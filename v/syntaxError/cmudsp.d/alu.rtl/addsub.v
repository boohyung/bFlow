/*	File:	addsub.v	  						*/

/*	module name: addsub						*/

/*	Description: adder/subtractor module for ALU 		*/

/*				Calculates in1 +/- in2		*/


/*==============================================================================*/


/********************************************************************************/
/*																				*/
/*	module:																		*/
/*																				*/
/********************************************************************************/

module addsub (
	in1,
	in2_2, in2_1, in2_0,    /* in2, ext:msb:lsb */
	naddsub,
	sum
	);


/*============	I/O direction	================================================*/

input [`acc]	 in1;
input [`databus] in2_0, in2_1;
input [`ext]	 in2_2;
input 		naddsub;    /* 0 if add, 1 if subtract */
output [`acc]	sum;

/*==============================================================================*/



/*============		I/O type	================================================*/

wire [`acc] sum;		

/*==============================================================================*/


/*==============================================================================*/
/*	processes																	*/
/*==============================================================================*/



assign sum = naddsub ? (in1 - {in2_2, in2_1, in2_0}) : (in1 + {in2_2, in2_1, in2_0});


endmodule	/* end module */