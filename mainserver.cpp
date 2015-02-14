/*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
  @
  @  MAINREF.cpp
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

//Server Includes
#include "similarity.hpp"
#include "server.hpp"
#include "error.hpp"

int main( int argc, char *argv[] ){
	if(argc != 3){
		printf("./server <port number>\n\n\n");
		return 0;
	}
	
	//**************************************************************************
	//* MKR- CONECTING WITH FRONT END
	//**************************************************************************
	try{
		Server* server = new Server(database->string2int(portNumber_str.c_str()));
		if(!server->waitForClient()) return 0;


		if(!server->sendData("REQUEST_DB")) throw ServerSendException

	}
	catch(ServerSendException)(
		printf("%s", e.what());
	}























	return 0;
}
	
