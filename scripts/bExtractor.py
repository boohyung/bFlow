#!/usr/bin/python2.7

'''
	dataflow module
		Contains functions to extract a dataflow from a dot file
		Given after yosys synthesis of a verilog file
'''

import networkx as nx;
import sys, traceback;
import re;
import copy;
import error;
import timeit
import time;
from collections import Counter
from frozendict import FrozenDict 
import collections
import yosys;
import math
from sortedcontainers import SortedSet

class BirthmarkExtractor(object):

	def __init__(self, dotFile):
		'''
		 Constructor	
		   Initializes and reads in the circuit
			 Initializes most of the private variables and settings 
		'''
		self.dfg = nx.DiGraph(nx.read_dot(dotFile));
		#Get the nodes and edges of the graph
		self.nodeList = self.dfg.nodes();
		self.edgeList = self.dfg.edges();

		# Get the shape and label attributes
		self.shapeAttr = nx.get_node_attributes(self.dfg, 'shape');
		self.labelAttr = nx.get_node_attributes(self.dfg, 'label');

		# Preprocess edges 
		self.edgeAttr = nx.get_edge_attributes(self.dfg, 'label');

		self.logicStr  = ["$not", "$and", "$or", "$xor", "$xnor", "$reduce", "$logic"]
		self.regStr    = ["$dff","$dffe","$adff","$sr","$dffsr","$dlatch"]
		self.wireStr   = ["$pos","$slice","$concat", "neg"]
		self.eqStr     = ["$eq","$eqx","$ne", "$nex"]
		self.muxStr    = ["$mux","$pmux"]
		self.shiftStr  = ["$shr","$shl","$sshr","$sshl","$shift","$shiftx"]
		self.arithStr  = ["$fa","$lcu", "$pow"]
		self.aluStr    = ["$alu"]
		self.macStr    = ["$macc", "alumacc"]
		self.addStr    = ["$add", "$sub"]
		self.multStr   = ["$mul"]
		self.cmpStr    = ["$lt", "$le", "$gt", "$ge"]
		self.divStr    = ["$div", "$mod"]
		self.lutStr    = ["$lut"]
		self.memStr    = ["$mem"]
		
		self.fpDict = {}
		self.statstr = "";
		self.statstrf = "";
		name = ["add", "mul", "div", "sh", "mux", "log", "eq", "cmp", "reg", "mem", "bb"]			
		for n in name:
			self.fpDict[n] = 0;

		self.constantList= [];
		self.outNodeList= [];
		self.inNodeList= [];
		self.cnodes = []
		self.linenumber= dict()

	
	
	def KGram2(self, k):
		start_time = timeit.default_timer();
		print " -- Extracting KGRAM k length from nodes"
		self.kgramset= Counter();
		self.kgramcounter= Counter();
		self.kgramlist= Counter();
		self.kgram= set();
		self.kgramline = dict(); #tuple...list of list of line numbers associated with the tuple 

		#self.kgramcountertuple= Counter();
		self.k = k;

		inputs = self.inNodeList + self.constantList

		for c in self.cnodes:
			print "\n\nChecking node: " + c
			path = [];
			self.markflag = 0;
			marked = set();
			self.findKGramPath(c ,  marked,  path );
			#print
			
		#print self.kgram
		for s in self.kgram:
			slist = [self.extractSequenceLetter(n) for n in s]
			#self.kgramline[tuple(slist)] = [][self.linenumber.get(n, -1) for n in s]]

			self.kgramline.setdefault(tuple(slist), set()).add(tuple(self.linenumber.get(n,"-1") for n in s));

			self.kgramlist[tuple(slist)] += 1;
			self.kgramset[frozenset(slist)] += 1;
			self.kgramcounter[FrozenDict(Counter(slist))] += 1;

		elapsed = timeit.default_timer() - start_time;
		return elapsed;
		

	def findKGramPath(self, node, marked,  path): 
		print "Checking node: " + node +  "\t" + repr(path)

		marked.add(node)

		#Record nodes that aren't wires, splices, constants, or ports
		if not any(s in node for s in ['n', 'x', 'v']):
			path.append(node);
			print " NEW PATH: " + repr(path);

			#Record the current gram if len is greater than k
			pathlen = len(path)
			if(pathlen <= self.k and pathlen > 1):
				#slist = [self.extractSequenceLetter(n) for n in path[len(path)-self.k:]]
				self.kgram.add(tuple(path));
			
				print "  GRAM ADDED" 

				if pathlen == self.k:
					print " POP"
					del path[-1];
					return

				
		succList = self.dfg.successors(node);
		for succ in succList:
			if succ not in marked:
				self.findKGramPath(succ, marked , path);
			else:
				print succ + " is marked..."



		#Pop only if node was inserted into path
		if not any(s in node for s in ['n', 'x', 'v']):
			del path[-1];
			print " POP"
	

	def findKATree(self, node, marked,  path): 
		#print "Checking node: " + node +  "\t" + repr(path)

		marked.add(node)

		#Record nodes that aren't wires, splices, constants, or ports
		if not any(s in node for s in ['n', 'x', 'v']):
			path.append(node);

			#Record the current gram if len is greater than k
			pathlen = len(path)
			if(pathlen <= self.k and pathlen > 1):
				#slist = [self.extractSequenceLetter(n) for n in path[len(path)-self.k:]]
				self.kgram.add(tuple(path));

				if pathlen == self.k:
					del path[-1];
					return

				
		succList = self.dfg.successors(node);
		for succ in succList:
			if succ not in marked:
				self.findKGramPath(succ, marked , path);


		#Pop only if node was inserted into path
		if not any(s in node for s in ['n', 'x', 'v']):
			del path[-1];




	def KGram(self, k):
		start_time = timeit.default_timer();
		print " -- Extracting KGRAM"
		self.kgramset= Counter();
		self.kgramcounter= Counter();
		self.kgramlist= Counter();
		self.kgram= set();
		#self.kgramcountertuple= Counter();
		self.k = k;

		inputs = self.inNodeList + self.constantList

		marked = set();
		for inNode in inputs:
			path = [];
			self.markflag = 0;
			m_marked = set();
			self.findKGram(inNode, self.outNodeList, marked, m_marked, path );
			#print
			
		#print self.kgram
		for s in self.kgram:
			slist = [self.extractSequenceLetter(n) for n in s]

			self.kgramlist[tuple(slist)] += 1;
			self.kgramset[frozenset(slist)] += 1;
			self.kgramcounter[FrozenDict(Counter(slist))] += 1;
		elapsed = timeit.default_timer() - start_time;
		return elapsed;


		
	def findKGram(self, node, dst, marked, m_marked, path): 
		succList = self.dfg.successors(node);
		#m_marked: A marked list when marked flag is set. Prevents infinite recursion
		#print "Checking node: " + node + ". DST: " + repr(dst) + "\t" + repr(path) + "   FLAG: " + repr(self.markflag);

		#Check if output has been reached
		if len(succList) == 0:
			#If a previous path has not been recorded, record the path from in to out
			pathlen = len(path)
			if pathlen <= self.k  and pathlen > 0:
				#slist = [self.labelAttr[n] for n in path[len(path)-self.k:]]
				#slist = [self.extractSequenceLetter(n) for n in path[len(path)-self.k:]]
				startindex = len(path)-self.k;
				if(startindex < 0):
					startindex = 0;

				self.kgram.add(tuple(path[startindex:]));
				#print repr(path[startindex:]) + "  :  "  + repr(slist) + "   FLAG:" + repr(self.markflag) ;
			
			#print "DST REACHED"
			#print "BACKTRACK CUR NODE: " + node

			return 

		
		#Prevent infinite loop if a marked node has been touched
		marked.add(node);	
		if(self.markflag > 0):
			m_marked.add(node);

		#Record nodes that aren't wires, splices, constants, or ports
		if not any(s in node for s in ['n', 'x', 'v']):
			path.append(node);
			if self.markflag > 0:
				self.markflag = self.markflag + 1;

			#Record the current gram if len is greater than k
			pathlen = len(path)
			if(pathlen > self.k and pathlen > 0):
				#slist = [self.extractSequenceLetter(n) for n in path[len(path)-self.k:]]
				startindex = len(path)-self.k;
				if(startindex < 0):
					startindex = 0;
				self.kgram.add(tuple(path[startindex:]));

				#print repr(path[startindex:]) + "  :  "  + repr(slist) + "   FLAG:" + repr(self.markflag) ;

				#Check and see if marked count is up to k. Past k, the paths should have been recorded already
				if self.markflag == self.k:
					#print " MARK LIMIT HIT...FLAG: " +repr(self.markflag) 
					#print "BACKTRACK CUR NODE: " + node	+ "   FLAG: " + repr(self.markflag);
					self.markflag = self.markflag - 1;
					del path[-1];
					return;

				
		for succ in succList:
			if self.markflag <= 0:
				if succ in marked:
					#print " NODE: " + succ + " is  MARKED!"
					self.markflag = 1;

			#Don't traverse node again during marked
			if succ not in m_marked:	
				self.findKGram(succ, dst, marked, m_marked, path);
				if(self.markflag < 1):
					m_marked.clear();


		#Pop only if node was inserted into path
		if not any(s in node for s in ['n', 'x', 'v']):
			self.markflag = self.markflag - 1;
			del path[-1];
		#print "BACKTRACK CUR NODE: " + node  + "   FLAG: " + repr(self.markflag);



	def Entropy(self, text):
		'''
			 Calculates the entropy of a given string
			 @PARAM: text- string to calculate entropy of
			 @RETURN Entropy value
		'''
		log2=lambda x:math.log(x)/math.log(2)
		exr={}
		infoc=0
		for each in text:
			try:
				exr[each]+=1
			except:
				exr[each]=1
		textlen=len(text)
		for k,v in exr.items():
			freq  =  1.0*v/textlen
			infoc+=freq*log2(freq)
		infoc*=-1
		return infoc



	def findMaxEntropy(self, sequenceList):
		'''
			 Finds the string in the list with the greatest entropy
			 @PARAM: sequenceList- List of sequences
			 @RETURN String with the largest entropy
		'''
		if(len(sequenceList) == 1):
			item,=sequenceList;
			return item

		maxEntropy = 0;
		maxString = '';
		for sequence in sequenceList:
			entropy = self.Entropy(sequence)
			#print "SEQUENCE:" + sequence + " ENTROPY: " + repr(entropy)
			if entropy >= maxEntropy:
				maxEntropy = entropy;
				maxString = sequence;
		
		return maxString;



	def getTopSequence(self, maxSeq, seqList):
		'''
			Gets the top (maxSeq) number of sequences
			 @PARAM: maxSeq - Number of sequences to return
			 @PARAM: seqList- Full list of sequences 
			 @RETURN List of the top maxSeq number of items in seqList
		'''
		slist = [];
		numSeq = 0;
		for seq in seqList:
			slist.append(seq);
			numSeq = numSeq + 1;
			if(maxSeq == numSeq):
				return slist;

		return slist;



	def extractSequenceLetter(self, node):
		'''
			Maps the operation of the function to a letter
			 @PARAM: node     - The node to assign a letter to
			 @RETURN Letter of the function
		'''
		if any(s in node for s in ['n', 'v', 'x']): # Check to see if node is splice, const, port
			return ""

		operation = self.labelAttr[node];

		if any(s in operation for s in self.wireStr):
			return 'N';
		elif any(s in operation for s in self.muxStr):
			return 'M';
		elif any(s in operation for s in self.regStr):
			return 'F';
		elif any(s in operation for s in self.addStr):
			return 'A';
		elif any(s in operation for s in self.logicStr):
			return 'L';
		elif any(s in operation for s in self.eqStr):
			return 'E';
		elif any(s in operation for s in self.cmpStr):
			return 'C';
		elif any(s in operation for s in self.shiftStr):
			return 'S';
		elif any(s in operation for s in self.multStr):
			return 'X';
		elif any(s in operation for s in self.divStr):
			return 'D';
		elif any(s in operation for s in self.memStr):
			return 'R';
		elif any(s in operation for s in self.macStr):
			return 'W';
		elif any(s in operation for s in self.aluStr):
			return 'U';
		elif any(s in operation for s in self.arithStr):
			return 'H';
		elif any(s in operation for s in self.lutStr):
			return 'T';
		else:
			print "Unknown operation: " + operation;
			return 'B';                                   





	def extractSWStringList(self, dataflowList_node, foundList):
		'''
			Converts a list of datapaths into their sequences
			 @PARAM: dataflowList_node- List of datapaths 
			 @PARAM: foundList -        List of nodes already found. Omit them
			 @RETURN Converted list of sequences
		'''
		swList = set();
		for dataflow_node in dataflowList_node:
			slist = [self.extractSequenceLetter(dataflow_node[index+1]) for index in xrange(len(dataflow_node)-2)];
			sw = "".join(slist)

			if(sw in foundList):
				continue;
			swList.add(sw);

		return swList;



		
	def findPath(self, node, dst, marked, path, simpPath, pathSequence, length, pathList, sequenceList):
		'''
			Finds the path from node to dst that has smallest number of nodes 
			 @PARAM: node           - Source node 
			 @PARAM: dst            - Destination node
			 @PARAM: marked         - Nodes that have been searched through already
			 @PARAM: path           - Current path of the search
			 @PARAM: minLen-          The length of min path currently found
			 @PARAM: maxPathList    - The nodes currently found with the minLen
			 @RETURN List of the datapaths from node to dst who's path is minimum
		'''
		#print "Checking node: " + node + ". DST: " + dst
		if node == dst:
			#print " * Node is dst!"
			newLen = len(path) + 1;

			#Max
			newPath = path + [node];
			if newLen  >= (length[0]):
				if newLen > length[0]:
					pathList[0][:] = [];
					length[0] = newLen 
				pathList[0].append(newPath);
			#Min
			if newLen  <= length[1]:
				if newLen <  length[1]:
					pathList[1][:] = [];
					length[1] = newLen 
				pathList[1].append(newPath);
			#Alpha
			numAlphabet = len(set(pathSequence))
			if numAlphabet >= length[2]:
				newLen = len(simpPath) + 1;
				if numAlphabet > length[2]:
					pathList[2][:] = [];
					sequenceList[:] = [];
					length[2] = numAlphabet
					length[3] = newLen 
				elif newLen > length[3]:
					pathList[2][:] = [];
					sequenceList[:] = [];
					length[3] = newLen 

				newPathSequence = copy.deepcopy(pathSequence)
				newPath = simpPath + [node];
				pathList[2].append(newPath);
				sequenceList.append(newPathSequence);
			
			return length;


		letter = self.extractSequenceLetter(node);
		if(letter != ""):
			pathSequence.append(letter)
			simpPath.append(node)

		path.append(node);
		marked.add(node);	
		succList = self.dfg.successors(node);

		for succ in succList:
			if succ not in marked:
				length = self.findPath(succ, dst,  marked, path, simpPath, pathSequence, length, pathList, sequenceList);
			else:
				#MAX
				for mp in pathList[0]:
					try:
						index = mp.index(succ);
						newLen = len(path) + len(mp) - index
						
						if newLen >= length[0]:
							if newLen > length[0]:
								length[0] = newLen
								pathList[0][:] = [];
							tempPath = path + mp[index:]
							pathList[0].append(tempPath);
							break;
					except ValueError:
						continue;
				
				#MIN
				for mp in pathList[1]:
					try:
						index = mp.index(succ);
						newLen = len(path) + len(mp) - index
						
						if newLen <= length[1]:
							if newLen < length[1]:
								length[1] = newLen
								pathList[1][:] = [];
							tempPath = path + mp[index:]
							pathList[1].append(tempPath);
							break;
					except ValueError:
						continue;

				#ALPHA
				i = 0;
				for mp in sequenceList:
					try:
						index = pathList[2][i].index(succ);

						tmpPathSequence = pathSequence + mp[index:];
						numAlphabet = len(set(tmpPathSequence))
						newLen = len(simpPath) + len(mp) - index
						tmpPath = simpPath + pathList[2][i][index:]

						if numAlphabet >= length[2]:
							if numAlphabet > length[2]:
								pathList[2][:] = [];
								length[2] = numAlphabet
								length[3] = newLen 
								sequenceList[:] = [];
							elif newLen > length[3]:
								pathList[2][:] = [];
								sequenceList[:] = [];
								length[3] = newLen 

							pathList[2].append(tmpPath);
							sequenceList.append(tmpPathSequence);
							break;
						
					except ValueError:
						continue;
					finally:
						i=i+1;




		del path[-1];
		if(letter != ""):
			del pathSequence[-1];
			del simpPath[-1];
		return length






	def faninCone(self, node, marked):
		marked.add(node);	
		predList = self.dfg.predecessors(node);
		for pred in predList:
			if pred not in marked:
				self.faninCone(pred,  marked);


	def extractkStructural(self):
		'''
		 Extracts the structural component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. Part of the structural fingerprint is 
				Handled in the functional extraction (OUT)
		'''

		print " -- Extracting structural features..."# from : " + fileName;

		#start_time = timeit.default_timer();
		for node in self.nodeList:
			if 'n' in node:  # Check to see if it is a port node
				predList = self.dfg.predecessors(node);
				if len(predList) == 0:
					self.inNodeList.append(node);
				else:
					self.outNodeList.append(node);
				continue;  #TODO: CHECK

			if 'c' in node:   
				label = self.labelAttr[node];
				label = re.search('\+(.*)\+', label);
		
				if label != None:
					operation = label.group(1);
					#print operation
					self.labelAttr[node] = operation;




	def extractStructural(self):
		'''
		 Extracts the structural component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. Part of the structural fingerprint is 
				Handled in the functional extraction (OUT)
		'''
		start_time = timeit.default_timer();

		print " -- Extracting structural features..."# from : " + fileName;
		# Preprocess nodes
		
		ffList = [];
		multList = [];
		totalFanin = 0;
		totalFanout = 0;
		maxFanin = 0;
		maxFanout = 0;
		nodeCount = 0;

		#start_time = timeit.default_timer();
		for node in self.nodeList:
			if 'v' in node:                     # Check to see if it is a  constant
				self.constantList.append(node);
				continue;

			predList = self.dfg.predecessors(node);
			sucList = self.dfg.successors(node);
			totalFanin = totalFanin + len(predList)
			totalFanout = totalFanout + len(sucList)
			nodeCount = nodeCount + 1;
			
			if self.shapeAttr[node] == "octagon":  # Check to see if it is a port node
				if len(predList) == 0:
					self.inNodeList.append(node);
				else:
					self.outNodeList.append(node);
				continue;  #TODO: CHECK

			if(len(predList) > maxFanin):
				maxFanin = len(predList)
			if(len(sucList) > maxFanout):
				maxFanout = len(sucList)

			#If it is a operational block
			if 'c' in node:   
				label = self.labelAttr[node];
				linenum =  re.search('!(.*)!', label);
				label = re.search('\+(.*)\+', label);
		
				if label != None:
					operation = label.group(1);
					#print operation
					self.labelAttr[node] = operation;
					self.cnodes.append(node);
					
					#Is there an associated line number?
					if linenum != None:
						self.linenumber[node] = linenum.group(1);

					size = 0;
					for pred in predList:
						if (pred,node) not in self.edgeAttr:
							psize = 1;
						else:
							label = self.edgeAttr[(pred,node)];
							label = re.search('<(.*)>', label);
							psize = int(label.group(1));

						if(psize > size):
							size = psize;

					for succ in sucList:
						if (node, succ) not in self.edgeAttr:
							ssize = 1;
						else:
							label = self.edgeAttr[(node, succ)];
							label = re.search('<(.*)>', label);
							ssize = int(label.group(1));

						if(ssize > size):
							size = ssize;

					if(size == 0):
						print "[WARNING] -- There is a size of zero. OPERATION: " + operation;
						print "IN:  " + repr(len(predList))
						print "OUT: " + repr(len(sucList))
						

					#Count the number of components
#TODO
					'''
					if any(s in operation for s in self.muxStr):
						self.fpDict["mux"][size] = self.fpDict["mux"].get(size, 0) + 1;
					elif any(s in operation for s in self.regStr):
						self.fpDict["reg"][size] = self.fpDict["reg"].get(size, 0) + 1;
						ffList.append(node);
					elif any(s in operation for s in self.addStr):
						self.fpDict["add"][size] = self.fpDict["add"].get(size, 0) + 1;
					elif any(s in operation for s in self.logicStr):
						self.fpDict["log"][size] = self.fpDict["log"].get(size, 0) + 1;
					elif any(s in operation for s in self.eqStr):
						self.fpDict["eq"][size] = self.fpDict["eq"].get(size, 0) + 1;
					elif any(s in operation for s in self.cmpStr):
						self.fpDict["cmp"][size] = self.fpDict["cmp"].get(size, 0) + 1;
					elif any(s in operation for s in self.shiftStr):
						self.fpDict["sh"][size] = self.fpDict["sh"].get(size, 0) + 1;
					elif any(s in operation for s in self.multStr):
						self.fpDict["mul"][size] = self.fpDict["mul"].get(size, 0) + 1;
					elif any(s in operation for s in self.divStr):
						self.fpDict["div"][size] = self.fpDict["div"].get(size, 0) + 1;
					elif any(s in operation for s in self.memStr):
						self.fpDict["mem"][size] = self.fpDict["mem"].get(size, 0) + 1;
					elif any(s in operation for s in self.macStr):
						print "[WARNING] -- There is a macc type node: " + operation
					elif any(s in operation for s in self.aluStr):
						print "[WARNING] -- There is an alu type node: " + operation
					elif any(s in operation for s in self.arithStr):
						print "[WARNING] -- There is an arithmetic type node: " + operation
					elif any(s in operation for s in self.lutStr):
						print "[WARNING] -- There is a lut node: " + operation
					else:
						self.fpDict["bb"][size] = self.fpDict["bb"].get(size, 0) + 1;
						'''
					if any(s in operation for s in self.muxStr):
						self.fpDict["mux"] = self.fpDict.get("mux", 0) + 1;
					elif any(s in operation for s in self.regStr):
						self.fpDict["reg"] = self.fpDict.get("reg", 0) + 1;
						ffList.append(node);
					elif any(s in operation for s in self.addStr):
						self.fpDict["add"] = self.fpDict.get("add", 0) + 1;
					elif any(s in operation for s in self.logicStr):
						self.fpDict["log"] = self.fpDict.get("log", 0) + 1;
					elif any(s in operation for s in self.eqStr):
						self.fpDict["eq"] = self.fpDict.get("eq", 0) + 1;
					elif any(s in operation for s in self.cmpStr):
						self.fpDict["cmp"] = self.fpDict.get("cmp", 0) + 1;
					elif any(s in operation for s in self.shiftStr):
						self.fpDict["sh"] = self.fpDict.get("sh", 0) + 1;
					elif any(s in operation for s in self.multStr):
						self.fpDict["mul"] = self.fpDict.get("mul", 0) + 1;
					elif any(s in operation for s in self.divStr):
						self.fpDict["div"] = self.fpDict.get("div", 0) + 1;
					elif any(s in operation for s in self.memStr):
						self.fpDict["mem"] = self.fpDict.get("mem", 0) + 1;
					elif any(s in operation for s in self.macStr):
						print "[WARNING] -- There is a macc type node: " + operation
					elif any(s in operation for s in self.aluStr):
						print "[WARNING] -- There is an alu type node: " + operation
					elif any(s in operation for s in self.arithStr):
						print "[WARNING] -- There is an arithmetic type node: " + operation
					elif any(s in operation for s in self.lutStr):
						print "[WARNING] -- There is a lut node: " + operation
					else:
						self.fpDict["bb"] = self.fpDict.get("bb", 0) + 1;

		avgFanin = totalFanin / nodeCount;	
		avgFanout = totalFanout / nodeCount;	
		#elapsed = timeit.default_timer() - start_time;
		#print "[PNODE] -- ELAPSED: " +  repr(elapsed) 

		#Need to wait till all the inputs have been found during node processing
		#start_time = timeit.default_timer();
		'''
		inputs = self.inNodeList + self.constantList
		ffDict = dict();
		for node in ffList:	
			marked = set();
			self.faninCone(node, marked)
			intoFF = [i for i in inputs if i in marked ]
			count = len(intoFF)

			ffDict[count] = ffDict.get(count, 0) + 1;
		
		self.fpDict["ffC"] = ffDict;

		#elapsed = timeit.default_timer() - start_time;
		#print "[FF]    -- ELAPSED: " +  repr(elapsed)
		'''


		#print "[DFX] -- Extracting additional structural features..."
		#print "AVG MAXPATH LEN: " + repr(float(maxPathCount)/float(totalMaxPaths));
		#print "AVG MINPATH LEN: " + repr(float(minPathCount)/float(totalMinPaths));
		#self.statstr = self.statstr + repr(len(self.nodeList)) + "," + repr(len(self.edgeList)) + ","
		#self.statstr = self.statstr + repr(len(self.inNodeList)) + "," + repr(len(self.outNodeList)) + ","
		#self.statstr = self.statstr + repr(maxFanin) + "," + repr(maxFanout) + ",";

		self.statstr = "%s,%s,%s,%s,%s,%s," % (repr(len(self.nodeList)), repr(len(self.edgeList)), repr(len(self.inNodeList)), repr(len(self.outNodeList)), repr(maxFanin), repr(maxFanout));
		#statstr = statstr + repr(len(list(nx.simple_cycles(dfg)))) + ",";
		#for freq in nx.degree_histogram(self.dfg):
		#	self.statstr = self.statstr + "," + repr(freq);

		slist = [repr(freq) for freq in nx.degree_histogram(self.dfg)];
		s = ",".join(slist)
		self.statstr = "%s,%s," % (self.statstr, s);
		#print "STAT: " + statstr

		return timeit.default_timer() - start_time;






	def extractFunctional(self):
		'''
		 Extracts the functional component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. 
		'''
		start_time = timeit.default_timer();
		print " -- Extracting functional features..."# from : " + fileName;
		self.pathList = set();
		self.maxList = set();
		self.minList = set();
		self.alphaList = set();

		totalMinPaths = 0;
		totalMaxPaths = 0;
		maxPathCount= 0;
		minPathCount= 0;

		maxNumAlpha = 0;
		pathHistory = [];

		#inAll = self.constantList + self.inNodeList;

		for out in self.outNodeList:
			'''
			count = 0;
			cmarked = set()
			self.faninCone(out, cmarked)
			intoFF = [i for i in self.constantList if i in cmarked]
			count = len(intoFF)
			'''

			for inNode in self.inNodeList:
				marked = set();
				path= [];
				simpPath= [inNode];
				pathSequence= [];
				pathList= [[],[],[]];
				swAlpha = [];

				length = self.findPath(inNode, out, marked, path, simpPath, pathSequence,  [0,sys.maxint,0, 0], pathList, swAlpha);
				if(0 in length[0:2]):
					continue;
				
				
				#Extract the sequence representation, make sure to ignore representations that is already in maxList
				#print " -- Extracting Sequence"
				swMax = self.extractSWStringList(pathList[0], self.maxList);
				swMin = self.extractSWStringList(pathList[1], self.minList);
				swAlpha = self.extractSWStringList(pathList[2], self.alphaList);

				#print " -- Finding Entropy"
				#Find the sequences with the highest entropy
				maxSequence = self.findMaxEntropy(swMax);
				minSequence = self.findMaxEntropy(swMin);
				alphaSequence = self.findMaxEntropy(swAlpha);
				nAlpha = len(set(alphaSequence))

				#Store the highest entropy sequence
				if(maxSequence != ""):
					self.maxList.add(maxSequence);
					totalMaxPaths= totalMaxPaths + 1;
					maxPathCount= maxPathCount+ len(maxSequence);
				if(minSequence != ""):
					self.minList.add(minSequence);
					totalMinPaths= totalMinPaths + 1;
					minPathCount= minPathCount+ len(minSequence);
				if(alphaSequence != ""):
					if(nAlpha > maxNumAlpha):
						self.alphaList = set();
						maxNumAlpha = nAlpha
						self.alphaList.add(alphaSequence);
					elif(nAlpha == maxNumAlpha):
						self.alphaList.add(alphaSequence);

				
			#Number of inputs the output depends on;
			#self.fpDict["outC"][count] = self.fpDict["outC"].get(count, 0) + 1;
			

	
		# Extract the sequence 
		#print "MAXLIST: " + repr(self.maxList);
		maxSeq = 3;
		swMax = list(self.maxList);
		swMax.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
		self.maxList = swMax[0:3];
		#print "MAXLIST: " + repr(self.maxList);

		#print "MINLIST: " + repr(self.minList);
		swMin = list(self.minList);
		swMin.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
		self.minList = swMin[0:3];
		#print "MINLIST: " + repr(self.minList);
		
		#print "ALPHALIST: " + repr(self.alphaList);
		self.alphaList= list(self.alphaList);
		self.alphaList.sort(lambda x, y: -1*(cmp(self.Entropy(x), self.Entropy(y))));
		self.alphaList = self.alphaList[0:3];

		#print "ALPHALIST: " + repr(self.alphaList);
		




		print " -- Extracting additional functional features..."
		if(totalMaxPaths == 0):
			self.statstrf = "%s,%s," % (self.statstrf, repr(0));
		else:
			self.statstrf = "%s,%s," % (self.statstrf, repr(float(maxPathCount)/float(totalMaxPaths)));

		if(totalMinPaths == 0):
			self.statstrf = "%s,%s," % (self.statstrf, repr(0));
		else:
			self.statstrf = "%s,%s" % (self.statstrf, repr(float(minPathCount)/float(totalMinPaths)));
		
		return timeit.default_timer() - start_time;






	def extractConstant(self):
		'''
		 Extracts the constant component of the circuit	
		 		Note that all three extractions (Structural, Functional, Constant)
				Needs to be called. 
		'''
		start_time = timeit.default_timer();
		print " -- Extracting constant features..."

		self.constSet = set();
		self.constMap = dict();
		constStr = "";
		for constant in self.constantList:
			cnstVal = self.labelAttr[constant];
			cnstVal = re.search('\'(.*)', cnstVal);
			if(cnstVal == None):
				cnstVal = self.labelAttr[constant];
				cnstVal = cnstVal.replace("L","")

				if(len(cnstVal) > 19):
					cnstVal = "9999999999999999";
				self.constSet.add(cnstVal);
				self.constMap[cnstVal] = self.constMap.get(cnstVal,0) + 1;

				if(cnstVal == "0"):
					cnstVal = "-1"
				constStr = constStr + cnstVal+ ",";

			else:
				cnstVal = cnstVal.group(1);

			#########################################################
				#Decompose the large constant for a pmux
				psize = sys.maxint;
				csize = 0;
				succList = self.dfg.successors(constant);
				for succ in succList:                         #Check if successor is PMUX
					operation = self.labelAttr[succ];
					if "pmux" in operation:
						predList = self.dfg.predecessors(succ);
						for pred in predList:                    #Find the size of the input
							if pred != constant:
								bitwidth = 0;
								if (pred,succ) not in self.edgeAttr:
									bitwidth= 1;
								else:
									label = self.edgeAttr[(pred,succ)];
									label = re.search('<(.*)>', label);
									bitwidth= int(label.group(1));
								if bitwidth <psize:
									psize = bitwidth;

						if (constant,succ) not in self.edgeAttr:
							csize = 1;
						else:
							label = self.edgeAttr[(constant,succ)];
							label = re.search('<(.*)>', label);
							csize = int(label.group(1));

						if(psize == 0 or csize == 0):
							print "NEED TO RETHINK METHODS!!!! PSIZE OR CSIZE IS ZERO!"
							raise error.GenError("PMUX ERROR")
						break;
							
				if(csize > psize):
					if((csize % psize) == 0 and 'x' not in cnstVal):
						start = 0;
						while start < csize:
							cnst = repr(int(cnstVal[start:start+psize], 2));
							self.constMap[cnst] = self.constMap.get(cnstVal,0) + 1;
							start = start + psize;

						continue;
			########################################################



				if('x' in cnstVal):   #DON'T CARE
					cnstVal = "-2";
				elif('z' in cnstVal): #HIGH IMPEDANCE
					cnstVal = "-3";
				else:
					cnstVal = repr(int(cnstVal, 2));
					cnstVal.replace("L", "")
					if(len(cnstVal) > 19):
						cnstVal = "9999999999999999";
				
				self.constMap[cnstVal] = self.constMap.get(cnstVal,0) + 1;

				self.constSet.add(cnstVal);

				if(cnstVal == "0"):
					cnstVal = "-1"

				constStr = constStr + cnstVal + ",";

		return timeit.default_timer() - start_time;


	def getBirthmark(self, kVal):
		'''
		 Returns the data for the birthmark
		'''
		#print "NUMBER OF CORES: " + repr(multiprocessing.cpu_count());
		print "[DFX] -- Extracting birthmarks"

		#f = multiprocessing.Process(target=self.extractFunctional);
		#s = multiprocessing.Process(target=self.extractStructural);

		#f.start();
		#time.sleep(1);
		#s.start();
		#print "========================================================================"
		#start_time = timeit.default_timer();
		selapsed = self.extractStructural();
		#elapsed = timeit.default_timer() - start_time;
		#print "[STRC] -- ELAPSED: " +  repr(elapsed) + "\n";


		#print "========================================================================"
		#start_time = timeit.default_timer();
		felapsed = self.extractFunctional();
		#elapsed = timeit.default_timer() - start_time;
		#print "[FUNC] -- ELAPSED: " +  repr(elapsed) + "\n";
		

		#print "========================================================================"
		#start_time = timeit.default_timer();
		celapsed = self.extractConstant();
		#elapsed = timeit.default_timer() - start_time;
		#print "[CONST] -- ELAPSED: " +  repr(elapsed) + "\n";

		#print "[DFX] -- Waiting for functional thread to finish..."
		#f.join();  #Wait till the first is finished
		#self.statstr = self.statstr + self.statstrf   #Append the stats from the functional
		self.statstr = "%s,%s" % (self.statstr, self.statstrf);


		kelapsed = self.KGram2(kVal);
		kgram = (self.kgramset, self.kgramcounter, self.kgramlist, self.kgramline);
		
		print "[KGRAM] -- ELAPSED: " +  repr(kelapsed) 
		print "[FUNCT] -- ELAPSED: " +  repr(felapsed) 
		print "[STRUC] -- ELAPSED: " +  repr(selapsed) 
		print "[CONST] -- ELAPSED: " +  repr(celapsed) 

		return (self.maxList, self.minList, self.constMap, self.fpDict, self.statstr, self.alphaList, kgram);



'''
					for pred in predList:
						if (pred,node) not in self.edgeAttr:
							psize = 1;
						else:
							label = self.edgeAttr[(pred,node)];
							label = re.search('<(.*)>', label);
							psize = int(label.group(1));

						if(psize > size):
							size = psize;

					for succ in sucList:
						if (node, succ) not in self.edgeAttr:
							ssize = 1;
						else:
							label = self.edgeAttr[(node, succ)];
							label = re.search('<(.*)>', label);
							ssize = int(label.group(1));

						if(ssize > size):
							size = ssize;




'''
