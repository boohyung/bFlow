CXX = g++

CFLAGS = \
		-Wall \
		-g \
		-Wno-unused-function \
		-Wno-write-strings \
		-Wno-sign-compare \
		-Iyosys

OBJS = \
	sw/src/ssw.o \
	sw/src/ssw_cpp.o \
	similarity.o \
	print.o \
	$

OBJSERVER = \
	database.o \
	birthmark.o \
	feature.o \
	similarity.o \
	print.o \
	server.o \
	$

all: main mainserver

#build subdirectories
	
main: $(OBJS) main.o 
	$(CXX) $(OBJS) main.o -o hbflow 

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

mainserver:  $(OBJSERVER) mainserver.o
	$(CXX) -o serverMain $(OBJSERVER) mainserver.o 
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $<


clean: 
	rm *.o hbflow  .yosys.dmp .yscript.seq *.pyc
