CXX = g++

CFLAGS = \
		-Wall \
		-g \
		$

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

OBJREF= \
	database.o \
	birthmark.o \
	feature.o \
	similarity.o \
	print.o \
	$

all: 

#build subdirectories
	
mat: $(OBJS) mat.o 
	$(CXX) $(OBJS) mat.o -o matlab 

autocor: $(OBJS) autocor.o 
	$(CXX) $(OBJS) autocor.o -o autocor 

refTest: $(OBJREF) refTest.o 
	$(CXX) $(OBJREF) refTest.o -o refTest 

mainopt: $(OBJS) swparam_opt.o
	$(CXX) $(OBJS) swparam_opt.o -o opt_sswparam 

mainserver:  $(OBJSERVER) mainserver.o
	$(CXX) -o serverMain $(OBJSERVER) mainserver.o 
	

%.o: %.cpp 
	$(CXX) $(CFLAGS) -c -o $@ $<


clean: 
	rm -v *.o hbflow serverMain  .yosys.dmp .yscript.seq *.pyc opt* *.csv .const* .seq .component .stat *.dmp
