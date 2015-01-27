#!/usr/bin/python2.7

import networkx as nx;
import sys, traceback;
import re;
import copy;


def findAddTree(node):
	global atIndex;
	global dfg;

	#print "FINDING ADD TREE UNDER NODE: " + node;
	label = labelAttr[node];

	if '$add' in label:
		predList = dfg.predecessors(node);

		for pred in predList:
			#Get the predecessor if it is a spliced 
			pred2 = pred;

			if 'x' in pred:
				pred2 = dfg.predecessors(pred);
				pred2 = pred2[0];

			if '$add' in labelAttr[pred2]:
				#print node + " " + pred2 + " combines to make an add tree";
				#Combine the two nodes to an addTree node
				name = "at" + repr(atIndex);
				atIndex = atIndex + 1;
				dfg.add_node(name, label="$addTree");
				labelAttr[name] = "$addTree";
				shapeAttr[name] = "record";

				#Get the neighbors
				succList = dfg.successors(node);
				ppredList = dfg.predecessors(pred2);
				predList.remove(pred2);
				predList.extend(ppredList);
				#print succList;
				#print predList;
			
				#Get the size of the "adder"
				osize = edgeAttr[(node, succList[0])];
				maxLength = 0;
				for predt in predList:
					if(predt, node) in edgeAttr:
						size = edgeAttr[(predt, node)];
						if size > maxLength: 
							maxLength = size;

				size = max(maxLength, osize);

				#Remove nodes;
				#print "DELETING NODE: " + repr(node) + " " + repr(pred);
				dfg.remove_node(node);
				dfg.remove_node(pred2);

				#Connect the tree block into the circuit
				for src in predList:
					dfg.add_edge(src, name, label=size);
					edgeAttr[(src, name)] = size
				
				for dest in succList:
					dfg.add_edge(name, dest, label=size);
					edgeAttr[(name, dest)] = size

				#Recurse
				findAddTree(name);
				break;

	
	
	###############################################################################
	# Extract the dataflow object names with bus sizes
	###############################################################################
def extractDF(dataflowList_node):
	dataflowList = [];
	for dataflow_node in dataflowList_node:
		dataflow = [];
		#print "CHECKING DATAFLOW";
		#print dataflow_node;
		#for index in xrange(len(dataflow_node)-2):
		#	print labelAttr[dataflow_node[index]];

		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
			#print "CHECKING NODE: " + node;
			
			#	Make sure it isn't a port/point node
			if 'n' in node:
				continue;
			elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
				continue;

			operation = labelAttr[node];

			if 'x' in node: 									 #Check to see if the node is a splice
				operation = "NETSPLICE";

			elif '$add' in operation:             #Check to see if the operation is a add
				#osize = edgeAttr[(node, dataflow_node[index+2])];
				osize = edgeAttr[(dataflow_node[index+2], node)];
				operation = operation + repr(osize);

				if 'Tree' in operation:
					predList = dfg.predecessors(node);
					operation = operation + "_" + repr(len(predList));

			elif '$mul' in operation: 
				insize = [];
				predList = dfg.predecessors(node);
				for pred in predList:
					osize = edgeAttr[(pred, node)];
					insize.append(osize);

				operation = operation + insize[0] + "x" + insize[1];
			elif '$eq' == operation:	
				predList = dfg.predecessors(node);
				osize = edgeAttr[(predList[0], node)];
				operation = operation + repr(osize);
			elif ('$mux' in operation) or ('sub' in operation):
				#osize = edgeAttr[(node, dataflow_node[index+2])];
				osize = edgeAttr[(dataflow_node[index+2], node)];
				operation = operation + repr(osize);
			elif '$' == operation:	
				predList = dfg.predecessors(node);
				operation = operation + repr(len(predList));
					
			dataflow.append(operation);
		dataflowList.append(dataflow);
	print dataflowList;
	return dataflowList;




def extractSWString(dataflowList_node):
	swList = set();
	for dataflow_node in dataflowList_node:
		#print "CHECKING DATAFLOW";
		sw="";
		for index in xrange(len(dataflow_node)-2):
			node = dataflow_node[index+1];
		
			#	Make sure it isn't a port/point node
			if 'n' in node:# or 'x' in node:
				continue;
			elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
				continue;

			#print "CHECKING NODE: " + node;
			operation = labelAttr[node];

			if 'x' in node: 									 #Check to see if the node is a splice
				sw = sw + 'N';
			elif ('$add' in operation) or ('sub' in operation):                        #Add or sub operation
				sw = sw + 'A';
			elif ('$fa' in operation) or ('lcu' in operation):                        #Add or sub operation
				sw = sw + 'A';
			elif ('$alu' in operation) or ('pow' in operation):                        #Add or sub operation
				sw = sw + 'P';
			elif '$mul' in operation or '$div' in operation or 'mod' in operation:     #Multiplication operation
				sw = sw + 'X';
			elif '$mux' in operation or '$pmux' in operation:                          #Conditional
				sw = sw + 'M';
			elif '$dff' in operation or '$adff' in operation:                          #memory
				sw = sw + 'F';
			elif '$eq' in operation or '$ne' in operation:	                           #Equality Operation
				sw = sw + 'E';
			elif '$sh' in operation or '$ssh' in operation:                            #Shift
				sw = sw + 'S';
			elif '$gt' in operation or '$lt' in operation:                             #Comparator
				sw = sw + 'C';
			elif '$dlatch' in operation or '$sr' in operation:                         #memory
				sw = sw + 'F';
			elif '$' in operation:
				sw = sw + 'L';                                                           #Logic
			else:
				sw = sw + 'B';                                     #...
				

			#print "OPERATION= " + operation + " SW: " + sw;
				
					
		#print;
		swList.add(sw);

	return swList;


def removeComponent(node):
	#Get neighbors
	succList = dfg.successors(node);
	predList = dfg.predecessors(node);

	#Make sure it is not a multiInput point
	if len(predList) > 1:
		#print "Traceback Error:  Multiinput point!!!!!";
		#print "NODE: " + node;
		#print "predList: ";
		#print predList;
		#sys.exit(1);
		return;
	if len(succList) < 1:
		return;

	#Get the size of the bus

	size = edgeAttr[(node, succList[0])];

	#Remove the node and passthrough the input
	dfg.remove_node(node);
	for dest in succList:
		dfg.add_edge(predList[0], dest, label=size);
		edgeAttr[(predList[0], dest)] = size





def findMaxPath(node, dst, marked, path, maxPath, maxPathList):
	#print "node " + node+ " dst: " + dst;
	if node == dst:
		path.append(node);
		if len(path) > len(maxPath):
			#maxPathList = [];
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			#print "NEW MAX PATH"
			#print maxPath;
		elif len(path) == len(maxPath):
			maxPath = copy.deepcopy(path);
			maxPathList.append(maxPath);
			
		path.pop(len(path)-1);
		return maxPath;

	path.append(node);
	marked.append(node);	

	predList = dfg.predecessors(node);
	for pred in predList:
		if pred not in marked:
			maxPath = findMaxPath(pred, dst,  marked, path, maxPath, maxPathList);
		else:
			length = len(maxPathList)
			for index in xrange(length):
				start = False;
				for i in maxPathList[index]:
					if i == pred:
						start = True;
						tempPath = copy.deepcopy(path);

					if start:
						tempPath.append(i);
	
				if start == True:
					if len(tempPath) > len(maxPath):
						#maxPathList = [];
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
						#print "NEW MAX PATH"
						#print maxPath;
					elif len(tempPath) == len(maxPath):
						maxPath = copy.deepcopy(tempPath);
						maxPathList.append(maxPath);
					break;
				


	path.pop(len(path)-1);
	#print "BT PATH"
	#print path;
	return maxPath;


















################################################################################
#
# START OF PYTHON PROGRAM
#
################################################################################
try:
	# Read in dot file of the dataflow
	fileName = sys.argv[1];
	print "[DFX] -- Reading in DOT File: " + fileName;
	dfg = nx.DiGraph(nx.read_dot(fileName));


	#Get the nodes and edges of the graph
	nodeList = dfg.nodes();
	edgeList = dfg.edges();
	
	outNodeList= [];
	inNodeList= [];
	constantList= [];

###############################################################################
# Get the shape and label attributes
###############################################################################
	shapeAttr = nx.get_node_attributes(dfg, 'shape');
	labelAttr = nx.get_node_attributes(dfg, 'label');



###############################################################################
# Preprocess edges 
###############################################################################
	edgeAttr = nx.get_edge_attributes(dfg, 'label');
	for edge in edgeList:
		if edge not in edgeAttr:
			edgeAttr[edge] = 1;
		else:
			label = edgeAttr[edge];
			label = re.search('<(.*)>', label);
			edgeAttr[edge] = label.group(1);
	
	
	
	###############################################################################
	# Preprocess nodes
	###############################################################################
	for node in nodeList:
		if 'v' in node:                          # Check to see if it is a  constant
			constantList.append(node);
		elif shapeAttr[node] == "octagon":       # Check to see if it is a port node
			inputs = dfg.predecessors(node);
			if len(inputs) == 0:
				inNodeList.append(node);
			else:
				outNodeList.append(node);
			#print "SHAPE: " + shapeAttr[node];
		elif shapeAttr[node] == "point":         # Check to see if it is a point node
			removeComponent(node);
		elif shapeAttr[node] == "diamond":         # Check to see if it is a point node
			removeComponent(node);
		else:                                    # Process the Combinational blocks
			label = labelAttr[node];
			label = re.search('\\\\n(.*)\|', label);
	
			if label != None:
				labelAttr[node] = label.group(1);
	
		#print "LABEL: " + labelAttr[node];
		#print "NAME:  " + node;
	
		#print
	
	
	
	
	
	#Set the nodes with the simplified label
	#nx.set_node_attributes(dfg, 'label', labelAttr);


	###############################################################################
	# Combine adders into add trees
	###############################################################################
	#atIndex = 1;
	#for node in nodeList:
#		#print "CHECKING NODE: " + repr(node);
#		if(dfg.has_node(node)):
#			if 'n' not in node:
#				findAddTree(node);

#	nx.write_dot(dfg, "newdot.dot");
		

	###############################################################################
	# Dataflow extraction Vectorized
	###############################################################################
	dataflowMaxList_node = [];
	dataflowMinList_node = [];
	for out in outNodeList:
		for inNode in inNodeList:
			#print "FROM " + inNode + " TO: " + out;
			#t = nx.dfs_postorder_nodes(dfg, inNode);
			if(not nx.has_path(dfg, inNode, out)):
				continue;
			
			print "SRC: " + inNode + " DST: " + out;
			marked = [];
			path= [];
			maxPath= [];
			maxPathList= [];
			findMaxPath(out, inNode, marked, path, maxPath, maxPathList);
			#print len(maxPathList)


			
			#s = nx.shortest_path(dfg, inNode, out);
			#print s;
			for s in nx.all_shortest_paths(dfg, inNode, out):
				dataflowMinList_node.append(list(reversed(s)));

			#Store the path of node names into list
			maxLength = 0;
			
			tempMaxList = []
			for p in maxPathList:
				if len(p) > maxLength:
					maxLength = len(p);
					tempMaxList= [];
					tempMaxList.append(p);

				elif len(p) == maxLength:
					tempMaxList.append(p);

			for p in tempMaxList:
				dataflowMaxList_node.append(p);
			#dataflowMinList_node.append(list(reversed(s)));
			#print "No path from " + inNode + " to " + out;



	#dfMax = extractDF(dataflowMaxList_node);
	#dfMin = extractDF(dataflowMinList_node);




	###############################################################################
	# Extract the sequence 
	###############################################################################
	swMax = extractSWString(dataflowMaxList_node);
	swMin = extractSWString(dataflowMinList_node);
	print "MAX: LENGTH: " + repr(len(swMax))
	print swMax;
	print "MIN: LENGTH: " + repr(len(swMin))
	print swMin;

	swMax = list(swMax);
	swMax.sort(lambda x, y: -1*(cmp(len(x), len(y))));

	maxList = [];

	fileStream = open(".seq", 'w');
	seqOutput = "";
	numMaxSeq = 3;
	numSeq = 0;
	sequence = "";
	maxLength = 0;
	


	for sw_str in swMax:
		#sw_str = re.sub('M+', 'M', sw_str)
		#sw_str.replace("FMMMM", "R");
		#sw_str.replace("FMMM", "R");
		#sw_str.replace("FMM", "R");
		#sw_str.replace("FM", "R");
		if(maxLength <= len(sw_str) ):
			maxLength = len(sw_str);

			sequence = sequence + sw_str + "\n";
			numSeq = numSeq + 1;
			if(numMaxSeq == numSeq):
				break;
		else:
			break;

	print "MAX MAXSTRING FEATURE: "
	sequence = repr(numSeq) + "\n" + sequence;
	seqOutput = sequence;
	print sequence;

	

	swMin = list(swMin);
	swMin.sort(lambda x, y: -1*(cmp(len(x), len(y))));

	numSeq = 0;
	sequence = "";
	maxLength = 0;
	for sw_str in swMin:
		#sw_str = re.sub('M+', 'M', sw_str)
		#sw_str.replace("FMMMM", "R");
		#sw_str.replace("FMMM", "R");
		#sw_str.replace("FMM", "R");
		#sw_str.replace("FM", "R");
		if(maxLength <= len(sw_str) ):
			maxLength = len(sw_str);

			sequence = sequence + sw_str + "\n";
			numSeq = numSeq + 1;
			if(numMaxSeq == numSeq):
				break;
		else:
			break;

	print "MAX MINSTRING FEATURE: "
	sequence = repr(numSeq) + "\n" + sequence;
	seqOutput = seqOutput +  sequence;
	print sequence;

	fileStream.write(seqOutput);
	fileStream.close();


	constSet = set();
	for constant in constantList:
		cnstVal = labelAttr[constant];
		cnstVal = re.search('\'(.*)', cnstVal);
		if(cnstVal == None):
			cnstVal = labelAttr[constant];
			constSet.add(cnstVal);
		else:
			cnstVal = cnstVal.group(1);
			if('x' in cnstVal):
				continue;
			constSet.add(repr(int(cnstVal,2)));

	fileStream = open(".const", 'w');
	for constant in constSet:		
		fileStream.write(constant+"\n");

	fileStream.close();


except:
	print "Error: ", sys.exc_info()[0];
	traceback.print_exc(file=sys.stdout);




