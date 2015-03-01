#!/usr/bin/python2.7

'''
	preprocess database module: 
		Functions for interacting with the yosys tools
'''

import os;
import sys;
import re;
import time;
import datetime;
from bs4 import BeautifulSoup
import error;
import yosys;
import dataflow as dfx
import traceback
import timeit


if len(sys.argv) != 3: 
	print "[ERROR] -- Not enough argument. Provide direction of DOT files to process";
	print "        -- ARG1: list of .v, ARG2: Name of sql database";
	exit();
	
#xmlFile= sys.argv[1];
#handler = open(xmlFile);
#xmlContent = handler.read();
#soup = BeautifulSoup(xmlContent,  'xml');
#cList = soup.DATABASE.find_all('CIRCUIT');
#for circuit in cList:
#	content = circuit.MAXSEQUENCE.string	
#	content = re.sub(r"\s+", "", content);
#	print content;

cfiles= sys.argv[1];
dbFile= sys.argv[2];

try:
	print
	print "########################################################################";
	print "[PPDB] -- Begin Circuit Database Preprocessing..."
	print "########################################################################";
	print

	soup = BeautifulSoup();
	dbtag = soup.new_tag("DATABASE");
	soup.append(dbtag)


	ID = 0;
	scriptName = "yoscript_db"
	fstream = open(cfiles);
	flines = fstream.readlines();

	for line in flines:
		start_time = timeit.default_timer();
		line= re.sub(r"\s+", "", line);
		print "--------------------------------------------------------------------------------"
		print "[PPDB] -- Extracting feature from verilog file: " + line;
		print "--------------------------------------------------------------------------------"

		val  = yosys.create_yosys_script(line, scriptName)
		top = val[1];

		rVal = yosys.execute(scriptName);
		if(rVal != ""):
			raise error.YosysError(rVal);


		#(maxList, minList, constSet, fp) 
		result = dfx.extractDataflow(val[0]);
		
		#Create tag for new circuit
		ckttag = soup.new_tag("CIRCUIT");
		ckttag['name'] = top
		ckttag['id'] = ID
		ID = ID + 1;
		dbtag.append(ckttag)
	
		#Store the max seq
		maxList = result[0];
		for seq in maxList:
			seqtag = soup.new_tag("MAXSEQ");
			seqtag.string =seq 
			ckttag.append(seqtag);
		
		minList = result[1];
		for seq in maxList:
			seqtag = soup.new_tag("MINSEQ");
			seqtag.string =seq 
			ckttag.append(seqtag);
		
		constSet= result[2];
		for const in constSet:
			consttag = soup.new_tag("CONSTANT");
			consttag.string = const
			ckttag.append(consttag);
		
		fpDict= result[3];

		i = 0;
		for n, fp in fpDict.iteritems():		
			fptag = soup.new_tag("FP");
			fptag['type'] = n;
			for k, v in fp.iteritems():
				attrTag = soup.new_tag("DATA");
				attrTag['size'] = k;
				attrTag['count'] = v;
				fptag.append(attrTag);
			i = i + 1;

			ckttag.append(fptag);
		elapsed = timeit.default_timer() - start_time;
		print "ELASPED TIME: " + repr(elapsed);
		print
		
	#print soup.prettify()
	fileStream = open(dbFile, 'w');
	fileStream.write(repr(soup));
	fileStream.close();
	
	print " -- XML File saved  : " + dbFile;
	print " -- Files processed : " + repr(ID);
	

except error.YosysError as e:
	print "[ERROR] -- Yosys has encountered an error...";
	print e.msg;
except error.YosysError as e:
	print "[ERROR] -- Yosys Error...";
	print "        -- " +  e.msg;
except Exception as e:
	print e;
	traceback.print_exc(file=sys.stdout);
finally:
	print "-----------------------------------------------------------------------"
	print "[PPDB] -- COMPLETE!";
	print 