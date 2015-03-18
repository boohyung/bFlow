/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @
  @  refTest.cpp
  @  
  @  @AUTHOR:Kevin Zeng
  @  Copyright 2012 – 2013 
  @  Virginia Polytechnic Institute and State University
  @
  @#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/


#ifndef MAIN_GUARD
#define MAIN_GUARD

//System Includes
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <sys/time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <math.h>
#include <fstream>

#include <sys/time.h>
#include <sys/stat.h>

//Server Includes
#include "similarity.hpp"
#include "database.hpp"
#include "error.hpp"

#include "libs/rapidxml/rapidxml.hpp"
#include "libs/rapidxml/rapidxml_print.hpp"
using namespace rapidxml;



int main( int argc, char *argv[] ){

	Database* db = NULL;
	enum Error{
		eARGS,
		eBIRTHMARK,
		eCLIENT_READY,
		eFILE
	};

	try{
		//Check arguments : Verilog File, XML Database File
		if(argc != 2) throw eARGS;
		std::string xmlDB= argv[1];


		//Read Database
		printf("[REF] -- Reading Database\n");
		db = new Database(xmlDB);
		db->print();


		
		timeval start_time, end_time;
		std::ofstream ofs;
		std::ofstream ofs2;
		ofs.open("data/compareTime.dat");
		ofs2.open("data/avgseqlength.dat");
		for(unsigned int i = 0; i < db->getSize(); i++){
			gettimeofday(&start_time, NULL); //----------------------------------
			std::vector<double> fsim;
			db->searchDatabase(db->getBirthmark(i), fsim);

			gettimeofday(&end_time, NULL); //----------------------------------
		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
		ofs<<elapsedTime/1000<<"\n";
		ofs2<<db->getBirthmark(i)->getAvgSequenceLength()<<"\n";
		}
		ofs.close();
		ofs2.close();

		/*
		for(unsigned int i = 0; i < fsim.size(); i++){
			printf("fSIM %7.4f\tCircuit: %s\n", fsim[i], db->getBirthmark(i)->getName().c_str());
			ofs<<fsim[i]<<"\n";
		}
		ofs.close();
		*/


		double elapsedTime = (end_time.tv_sec - start_time.tv_sec) * 1000.0;
		elapsedTime += (end_time.tv_usec - start_time.tv_usec) / 1000.0;
		printf("[REF] -- Elapsed search time: %f\n", elapsedTime/1000.0);
	}
	catch(Error e){
		switch(e){
			case eARGS:  
				printf("[ERROR] -- Invalid Arguments\n\t./refTest <verilog file> <XML Database File>\n\n");
				break;
			case eFILE:  
				printf("[ERROR] -- Cannot open file for importing\n\n");
				break;
			case eBIRTHMARK:  
				printf("[ERROR] -- Invalid Arguments\n\t./server <port number> <XML Database File>\n\n\n");
				break;
			default:
				printf("[ERROR] -- Exception occured\n"); 
				break;
		}
	}

	if(db != NULL) delete db;


	return 0;
}

#endif