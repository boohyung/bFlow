#!/usr/bin/python2.7

'''
	yosys module: 
		Functions for interacting with the yosys tools
'''

import os;
import sys;
import re;
import time;
import datetime;
from subprocess import call
import error;

def create_yosys_script(fileName, scriptName):
	data = getFileData(fileName);
	path = data[0];
	top= data[1];
	ext= data[2];

	script = "";	
	script = script + "echo on\n";

	if (ext == 'v'):
		script = script + "read_verilog " + fileName;
	if(ext == 'd' or ext == 'd/'):
		files = fileName +   "/files"
		with open(files) as f:
			for line in f:
				script = script + "read_verilog " + line;

	script = script + "\n\n";
	script = script + "hierarchy -check\n";
	script = script + "proc; opt; fsm; opt;\n\n";
	script = script + "memory_collect; opt;\n\n";
	script = script + "flatten "+ top +"; opt\n";
	script = script + "wreduce; opt\n\n";
	script = script + "stat " + top + "\n\n";
	script = script + "show -width -format dot -prefix ./dot/" + top + "_df " + top + "\n";


	fileStream = open(scriptName, 'w');
	fileStream.write(script);
	fileStream.close();

	dotFile = "./dot/"+top+"_df.dot";
	return (dotFile, top);




def execute(scriptFile):
	print "[YOSYS] -- Running yosys tools..."
	cmd = "yosys -Qq -s " + scriptFile + " -l data/.pyosys.log";
	rc = call(cmd, shell=True);

	msg = ""
	hasError = False;
	with open("data/.pyosys.log") as f:
		fsc = open("data/statcell.dat", "a");
		fsw = open("data/statwire.dat", "a");
		for line in f:
			if("ERROR:" in line or hasError):
				hasError = True;
				msg = msg + line;
			elif("Number of cells:" in line):
				fsc.write(line);
			elif("Number of wire bits:" in line):
				fsw.write(line);
		fsc.close()
		fsw.close()


	if hasError:
		print msg;
		return msg;
	
	return "";




def getFileData(fileName):
	data = re.search("(.+\/)*(.+)\.(.+)$", fileName);
	return (data.group(1), data.group(2), data.group(3));










