/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Universal FIFO Single Clock                                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  D/L from: http://www.opencores.org/cores/generic_fifos/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: generic_fifo_sc_a.v,v 1.1.1.1 2002-09-25 05:42:06 rudi Exp $
//
//  $Date: 2002-09-25 05:42:06 $
//  $Revision: 1.1.1.1 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//
//
//
//
//
//
//
//

`include "timescale.v"

/*

Description
===========

I/Os
----
rst	low active, either sync. or async. master reset (see below how to select)
clr	synchronous clear (just like reset but always synchronous), high active
re	read enable, synchronous, high active
we	read enable, synchronous, high active
din	Data Input
dout	Data Output

full	Indicates the FIFO is full (combinatorial output)
full_r	same as above, but registered output (see note below)
empty	Indicates the FIFO is empty
empty_r	same as above, but registered output (see note below)

full_n		Indicates if the FIFO has space for N entries (combinatorial output)
full_n_r	same as above, but registered output (see note below)
empty_n		Indicates the FIFO has at least N entries (combinatorial output)
empty_n_r	same as above, but registered output (see note below)

level		indicates the FIFO level:
		2'b00	0-25%	 full
		2'b01	25-50%	 full
		2'b10	50-75%	 full
		2'b11	%75-100% full

combinatorial vs. registered status outputs
-------------------------------------------
Both the combinatorial and registered status outputs have exactly the same
synchronous timing. Meaning they are being asserted immediately at the clock
edge after the last read or write. The combinatorial outputs however, pass
through several levels of logic before they are output. The registered status
outputs are direct outputs of a flip-flop. The reason both are provided, is
that the registered outputs require quite a bit of additional logic inside
the FIFO. If you can meet timing of your device with the combinatorial
outputs, use them ! The FIFO will be smaller. If the status signals are
in the critical pass, use the registered outputs, they have a much smaller
output delay (actually only Tcq).

Parameters
----------
The FIFO takes 3 parameters:
dw	Data bus width
aw	Address bus width (Determines the FIFO size by evaluating 2^aw)
n	N is a second status threshold constant for full_n and empty_n
	If you have no need for the second status threshold, do not
	connect the outputs and the logic should be removed by your
	synthesis tool.

Synthesis Results
-----------------
In a Spartan 2e a 8 bit wide, 8 entries deep FIFO, takes 85 LUTs and runs
at about 116 MHz (IO insertion disabled). The registered status outputs
are valid after 2.1NS, the combinatorial once take out to 6.5 NS to be
available.


Misc
----
This design assumes you will do appropriate status checking externally.

IMPORTANT ! writing while the FIFO is full or reading while the FIFO is
empty will place the FIFO in an undefined state.

*/


// Selecting Sync. or Async Reset
// ------------------------------
// Uncomment one of the two lines below. The first line for
// synchronous reset, the second for asynchronous reset

`define SC_FIFO_ASYNC_RESET				// Uncomment for Syncr. reset
//`define SC_FIFO_ASYNC_RESET	or negedge rst		// Uncomment for Async. reset


module generic_fifo_sc_a(clk, rst, clr, din, we, dout, re,
			full, empty, full_r, empty_r,
			full_n, empty_n, full_n_r, empty_n_r,
			level);

parameter dw=8;
parameter aw=8;
parameter n=32;
parameter max_size = 1<<aw;

input			clk, rst, clr;
input	[dw-1:0]	din;
input			we;
output	[dw-1:0]	dout;
input			re;
output			full, full_r;
output			empty, empty_r;
output			full_n, full_n_r;
output			empty_n, empty_n_r;
output	[1:0]		level;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

reg	[aw-1:0]	wp;
wire	[aw-1:0]	wp_pl1;
wire	[aw-1:0]	wp_pl2;
reg	[aw-1:0]	rp;
wire	[aw-1:0]	rp_pl1;
reg			full_r;
reg			empty_r;
reg			gb;
reg			gb2;
reg	[aw:0]		cnt;
wire			full_n, empty_n;
reg			full_n_r, empty_n_r;

////////////////////////////////////////////////////////////////////
//
// Memory Block
//

generic_dpram  #(aw,dw) u0(
	.rclk(		clk		),
	.rrst(		!rst		),
	.rce(		1'b1		),
	.oe(		1'b1		),
	.raddr(		rp		),
	.do(		dout		),
	.wclk(		clk		),
	.wrst(		!rst		),
	.wce(		1'b1		),
	.we(		we		),
	.waddr(		wp		),
	.di(		din		)
	);

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)	wp <= #1 {aw{1'b0}};
	else
	if(clr)		wp <= #1 {aw{1'b0}};
	else
	if(we)		wp <= #1 wp_pl1;

assign wp_pl1 = wp + { {aw-1{1'b0}}, 1'b1};
assign wp_pl2 = wp + { {aw-2{1'b0}}, 2'b10};

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)	rp <= #1 {aw{1'b0}};
	else
	if(clr)		rp <= #1 {aw{1'b0}};
	else
	if(re)		rp <= #1 rp_pl1;

assign rp_pl1 = rp + { {aw-1{1'b0}}, 1'b1};

////////////////////////////////////////////////////////////////////
//
// Combinatorial Full & Empty Flags
//

assign empty = ((wp == rp) & !gb);
assign full  = ((wp == rp) &  gb);

// Guard Bit ...
always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)			gb <= #1 1'b0;
	else
	if(clr)				gb <= #1 1'b0;
	else
	if((wp_pl1 == rp) & we)		gb <= #1 1'b1;
	else
	if(re)				gb <= #1 1'b0;

////////////////////////////////////////////////////////////////////
//
// Registered Full & Empty Flags
//

// Guard Bit ...
always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)			gb2 <= #1 1'b0;
	else
	if(clr)				gb2 <= #1 1'b0;
	else
	if((wp_pl2 == rp) & we)		gb2 <= #1 1'b1;
	else
	if((wp != rp) & re)		gb2 <= #1 1'b0;

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)				full_r <= #1 1'b0;
	else
	if(clr)					full_r <= #1 1'b0;
	else
	if(we & ((wp_pl1 == rp) & gb2) & !re)	full_r <= #1 1'b1;
	else
	if(re & ((wp_pl1 != rp) | !gb2) & !we)	full_r <= #1 1'b0;

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)				empty_r <= #1 1'b1;
	else
	if(clr)					empty_r <= #1 1'b1;
	else
	if(we & ((wp != rp_pl1) | gb2) & !re)	empty_r <= #1 1'b0;
	else
	if(re & ((wp == rp_pl1) & !gb2) & !we)	empty_r <= #1 1'b1;

////////////////////////////////////////////////////////////////////
//
// Combinatorial Full_n & Empty_n Flags
//

assign empty_n = cnt < n;
assign full_n  = !(cnt < (max_size-n+1));
assign level = {2{cnt[aw]}} | cnt[aw-1:aw-2];

// N entries status
always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)	cnt <= #1 {aw+1{1'b0}};
	else
	if(clr)		cnt <= #1 {aw+1{1'b0}};
	else
	if( re & !we)	cnt <= #1 cnt + { {aw{1'b1}}, 1'b1};
	else
	if(!re &  we)	cnt <= #1 cnt + { {aw{1'b0}}, 1'b1};

////////////////////////////////////////////////////////////////////
//
// Registered Full_n & Empty_n Flags
//

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)				empty_n_r <= #1 1'b1;
	else
	if(clr)					empty_n_r <= #1 1'b1;
	else
	if(we & (cnt >= (n-1) ) & !re)		empty_n_r <= #1 1'b0;
	else
	if(re & (cnt <= n ) & !we)		empty_n_r <= #1 1'b1;

always @(posedge clk `SC_FIFO_ASYNC_RESET)
	if(!rst)				full_n_r <= #1 1'b0;
	else
	if(clr)					full_n_r <= #1 1'b0;
	else
	if(we & (cnt >= (max_size-n) ) & !re)	full_n_r <= #1 1'b1;
	else
	if(re & (cnt <= (max_size-n+1)) & !we)	full_n_r <= #1 1'b0;

////////////////////////////////////////////////////////////////////
//
// Sanity Check
//

// synopsys translate_off
always @(posedge clk)
	if(we & full)
		$display("%m WARNING: Writing while fifo is FULL (%t)",$time);

always @(posedge clk)
	if(re & empty)
		$display("%m WARNING: Reading while fifo is EMPTY (%t)",$time);
// synopsys translate_on

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Dual-Port Synchronous RAM                           ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common dual-port               ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  dual-port synchronous RAM.                                  ////
////  It also contains a fully synthesizeable model for FPGAs.    ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Dual-Port Sync RAM                                ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage 2-port Sync RAM                                    ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Generic FPGA (VENDOR_FPGA)                                ////
////    Tested RAMs: Altera, Xilinx                               ////
////    Synthesis tools: LeonardoSpectrum, Synplicity             ////
////  - Xilinx (VENDOR_XILINX)                                    ////
////  - Altera (VENDOR_ALTERA)                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - fix Avant!                                               ////
////   - add additional RAMs (VS etc)                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - Richard Herveille, richard@asics.ws                   ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.2  2001/11/08 19:11:31  samg
// added valid checks to behvioral model
//
// Revision 1.1.1.1  2001/09/14 09:57:10  rherveille
// Major cleanup.
// Files are now compliant to Altera & Xilinx memories.
// Memories are now compatible, i.e. drop-in replacements.
// Added synthesizeable generic FPGA description.
// Created "generic_memories" cvs entry.
//
// Revision 1.1.1.2  2001/08/21 13:09:27  damjan
// *** empty log message ***
//
// Revision 1.1  2001/08/20 18:23:20  damjan
// Initial revision
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//
 
//`include "timescale.v"
 
//`define VENDOR_FPGA
//`define VENDOR_XILINX
//`define VENDOR_ALTERA
 
module generic_dpram(
	// Generic synchronous dual-port RAM interface
	rclk, rrst, rce, oe, raddr, do,
	wclk, wrst, wce, we, waddr, di
);
 
	//
	// Default address and data buses width
	//
	parameter aw = 5;  // number of bits in address-bus
	parameter dw = 16; // number of bits in data-bus
 
	//
	// Generic synchronous double-port RAM interface
	//
	// read port
	input           rclk;  // read clock, rising edge trigger
	input           rrst;  // read port reset, active high
	input           rce;   // read port chip enable, active high
	input           oe;	   // output enable, active high
	input  [aw-1:0] raddr; // read address
	output [dw-1:0] do;    // data output
 
	// write port
	input          wclk;  // write clock, rising edge trigger
	input          wrst;  // write port reset, active high
	input          wce;   // write port chip enable, active high
	input          we;    // write enable, active high
	input [aw-1:0] waddr; // write address
	input [dw-1:0] di;    // data input
 
	//
	// Module body
	//
 
`ifdef VENDOR_FPGA
	//
	// Instantiation synthesizeable FPGA memory
	//
	// This code has been tested using LeonardoSpectrum and Synplicity.
	// The code correctly instantiates Altera EABs and Xilinx BlockRAMs.
	//
 
	reg [dw-1 :0] mem [(1<<aw) -1:0]; // instantiate memory
	reg [dw-1:0] do;                  // data output registers
 
	// read operation
 
	/*
	always@(posedge rclk)
		if (rce)                      // clock enable instructs Xilinx tools to use SelectRAM (LUTS) instead of BlockRAM
			do <= #1 mem[raddr];
	*/
 
	always@(posedge rclk)
		do <= #1 mem[raddr];
 
	// write operation
	always@(posedge wclk)
		if (we && wce)
			mem[waddr] <= #1 di;
 
`else
 
`ifdef VENDOR_XILINX
	//
	// Instantiation of FPGA memory:
	//
	// Virtex/Spartan2 BlockRAMs
	//
	xilinx_ram_dp xilinx_ram(
		// read port
		.CLKA(rclk),
		.RSTA(rrst),
		.ENA(rce),
		.ADDRA(raddr),
		.DIA( {dw{1'b0}} ),
		.WEA(1'b0),
		.DOA(do),
 
		// write port
		.CLKB(wclk),
		.RSTB(wrst),
		.ENB(wce),
		.ADDRB(waddr),
		.DIB(di),
		.WEB(we),
		.DOB()
	);
 
	defparam
		xilinx_ram.dwidth = dw,
		xilinx_ram.awidth = aw;
 
`else
 
`ifdef VENDOR_ALTERA
	//
	// Instantiation of FPGA memory:
	//
	// Altera FLEX/APEX EABs
	//
	altera_ram_dp altera_ram(
		// read port
		.rdclock(rclk),
		.rdclocken(rce),
		.rdaddress(raddr),
		.q(do),
 
		// write port
		.wrclock(wclk),
		.wrclocken(wce),
		.wren(we),
		.wraddress(waddr),
		.data(di)
	);
 
	defparam
		altera_ram.dwidth = dw,
		altera_ram.awidth = aw;
 
`else
 
`ifdef VENDOR_ARTISAN
 
	//
	// Instantiation of ASIC memory:
	//
	// Artisan Synchronous Double-Port RAM (ra2sh)
	//
	art_hsdp #(dw, 1<<aw, aw) artisan_sdp(
		// read port
		.qa(do),
		.clka(rclk),
		.cena(~rce),
		.wena(1'b1),
		.aa(raddr),
		.da( {dw{1'b0}} ),
		.oena(~oe),
 
		// write port
		.qb(),
		.clkb(wclk),
		.cenb(~wce),
		.wenb(~we),
		.ab(waddr),
		.db(di),
		.oenb(1'b1)
	);
 
`else
 
`ifdef VENDOR_AVANT
 
	//
	// Instantiation of ASIC memory:
	//
	// Avant! Asynchronous Two-Port RAM
	//
	avant_atp avant_atp(
		.web(~we),
		.reb(),
		.oeb(~oe),
		.rcsb(),
		.wcsb(),
		.ra(raddr),
		.wa(waddr),
		.di(di),
		.do(do)
	);
 
`else
 
`ifdef VENDOR_VIRAGE
 
	//
	// Instantiation of ASIC memory:
	//
	// Virage Synchronous 2-port R/W RAM
	//
	virage_stp virage_stp(
		// read port
		.CLKA(rclk),
		.MEA(rce_a),
		.ADRA(raddr),
		.DA( {dw{1'b0}} ),
		.WEA(1'b0),
		.OEA(oe),
		.QA(do),
 
		// write port
		.CLKB(wclk),
		.MEB(wce),
		.ADRB(waddr),
		.DB(di),
		.WEB(we),
		.OEB(1'b1),
		.QB()
	);
 
`else
 
	//
	// Generic dual-port synchronous RAM model
	//
 
	//
	// Generic RAM's registers and wires
	//
	reg	[dw-1:0]	mem [(1<<aw)-1:0];	// RAM content
	reg	[dw-1:0]	do_reg;            // RAM data output register
 
	//
	// Data output drivers
	//
	assign do = (oe & rce) ? do_reg : {dw{1'bz}};
 
	// read operation
	always @(posedge rclk)
		if (rce)
          		do_reg <= #1 (we && (waddr==raddr)) ? {dw{1'b x}} : mem[raddr];
 
	// write operation
	always @(posedge wclk)
		if (wce && we)
			mem[waddr] <= #1 di;
 
 
	// Task prints range of memory
	// *** Remember that tasks are non reentrant, don't call this task in parallel for multiple instantiations. 
	task print_ram;
	input [aw-1:0] start;
	input [aw-1:0] finish;
	integer rnum;
  	begin
    		for (rnum=start;rnum<=finish;rnum=rnum+1)
      			$display("Addr %h = %h",rnum,mem[rnum]);
  	end
	endtask
 
`endif // !VENDOR_VIRAGE
`endif // !VENDOR_AVANT
`endif // !VENDOR_ARTISAN
`endif // !VENDOR_ALTERA
`endif // !VENDOR_XILINX
`endif // !VENDOR_FPGA
 
endmodule
 
//
// Black-box modules
//
 
`ifdef VENDOR_ALTERA
	module altera_ram_dp(
		data,
		wraddress,
		rdaddress,
		wren,
		wrclock,
		wrclocken,
		rdclock,
		rdclocken,
		q) /* synthesis black_box */;
 
		parameter awidth = 7;
		parameter dwidth = 8;
 
		input [dwidth -1:0] data;
		input [awidth -1:0] wraddress;
		input [awidth -1:0] rdaddress;
		input               wren;
		input               wrclock;
		input               wrclocken;
		input               rdclock;
		input               rdclocken;
		output [dwidth -1:0] q;
 
		// synopsis translate_off
		// exemplar translate_off
 
		syn_dpram_rowr #(
			"UNUSED",
			dwidth,
			awidth,
			1 << awidth
		)
		altera_dpram_model (
			// read port
			.RdClock(rdclock),
			.RdClken(rdclocken),
			.RdAddress(rdaddress),
			.RdEn(1'b1),
			.Q(q),
 
			// write port
			.WrClock(wrclock),
			.WrClken(wrclocken),
			.WrAddress(wraddress),
			.WrEn(wren),
			.Data(data)
		);
 
		// exemplar translate_on
		// synopsis translate_on
 
	endmodule
`endif // VENDOR_ALTERA
 
`ifdef VENDOR_XILINX
	module xilinx_ram_dp (
		ADDRA,
		CLKA,
		ADDRB,
		CLKB,
		DIA,
		WEA,
		DIB,
		WEB,
		ENA,
		ENB,
		RSTA,
		RSTB,
		DOA,
		DOB) /* synthesis black_box */ ;
 
	parameter awidth = 7;
	parameter dwidth = 8;
 
	// port_a
	input               CLKA;
	input               RSTA;
	input               ENA;
	input [awidth-1:0]  ADDRA;
	input [dwidth-1:0]  DIA;
	input               WEA;
	output [dwidth-1:0] DOA;
 
	// port_b
	input               CLKB;
	input               RSTB;
	input               ENB;
	input [awidth-1:0]  ADDRB;
	input [dwidth-1:0]  DIB;
	input               WEB;
	output [dwidth-1:0] DOB;
 
	// insert simulation model
 
 
	// synopsys translate_off
	// exemplar translate_off
 
	C_MEM_DP_BLOCK_V1_0 #(
		awidth,
		awidth,
		1,
		1,
		"0",
		1 << awidth,
		1 << awidth,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		"",
		16,
		0,
		0,
		1,
		1,
		1,
		1,
		dwidth,
		dwidth)
	xilinx_dpram_model (
		.ADDRA(ADDRA),
		.CLKA(CLKA),
		.ADDRB(ADDRB),
		.CLKB(CLKB),
		.DIA(DIA),
		.WEA(WEA),
		.DIB(DIB),
		.WEB(WEB),
		.ENA(ENA),
		.ENB(ENB),
		.RSTA(RSTA),
		.RSTB(RSTB),
		.DOA(DOA),
		.DOB(DOB));
 
		// exemplar translate_on
		// synopsys translate_on
 
	endmodule
`endif // VENDOR_XILINX
