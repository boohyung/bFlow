/*
 * This source file contains a Verilog description of an IP core
 * automatically generated by the SPIRAL HDL Generator.
 *
 * This product includes a hardware design developed by Carnegie Mellon University.
 *
 * Copyright (c) 2005-2011 by Peter A. Milder for the SPIRAL Project,
 * Carnegie Mellon University
 *
 * For more information, see the SPIRAL project website at:
 *   http://www.spiral.net
 *
 * This design is provided for internal, non-commercial research use only
 * and is not for redistribution, with or without modifications.
 * 
 * You may not use the name "Carnegie Mellon University" or derivations
 * thereof to endorse or promote products derived from this software.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY WARRANTY OF ANY KIND, EITHER
 * EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANY WARRANTY
 * THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS OR BE ERROR-FREE AND ANY
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 * TITLE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
 * BE LIABLE FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT,
 * SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN
 * ANY WAY CONNECTED WITH THIS SOFTWARE (WHETHER OR NOT BASED UPON WARRANTY,
 * CONTRACT, TORT OR OTHERWISE).
 *
 */

/* Portions of this design are protected by US Patent no. 8,321,823
 * (assignee: Carnegie Mellon University).
 */

//   Input/output stream: 2 complex words per cycle
//   Throughput: one transform every 37 cycles
//   Latency: 41 cycles

//   Resources required:
//     4 multipliers (4 x 4 bit)

// Generated on Thu Feb 26 00:17:51 EST 2015

// Latency: 41 clock cycles
// Throughput: 1 transform every 37 cycles


// We use an interleaved complex data format.  X0 represents the
// real portion of the first input, and X1 represents the imaginary
// portion.  The X variables are system inputs and the Y variables
// are system outputs.

// The design uses a system of flag signals to indicate the
// beginning of the input and output data streams.  The 'next'
// input (asserted high), is used to instruct the system that the
// input stream will begin on the following cycle.

// This system has a 'gap' of 37 cycles.  This means that
// 37 cycles must elapse between the beginning of the input
// vectors.

// The output signal 'next_out' (also asserted high) indicates
// that the output vector will begin streaming out of the system
 // on the following cycle.

// The system has a latency of 41 cycles.  This means that
// the 'next_out' will be asserted 41 cycles after the user
// asserts 'next'.

// The simple testbench below will demonstrate the timing for loading
// and unloading data vectors.
// The system reset signal is asserted high.

// Please note: when simulating floating point code, you must include
// Xilinx's DSP slice simulation module.


// Latency: 41
// Gap: 37
// module_name_is:dft_top
module spiraldft_4_4_iter_jacm(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [3:0] t0_0;
   wire [3:0] t0_1;
   wire [3:0] t0_2;
   wire [3:0] t0_3;
   wire next_0;
   wire [3:0] t1_0;
   wire [3:0] t1_1;
   wire [3:0] t1_2;
   wire [3:0] t1_3;
   wire next_1;
   wire [3:0] t2_0;
   wire [3:0] t2_1;
   wire [3:0] t2_2;
   wire [3:0] t2_3;
   wire next_2;
   assign t0_0 = X0;
   assign Y0 = t2_0;
   assign t0_1 = X1;
   assign Y1 = t2_1;
   assign t0_2 = X2;
   assign Y2 = t2_2;
   assign t0_3 = X3;
   assign Y3 = t2_3;
   assign next_0 = next;
   assign next_out = next_2;

// latency=4, gap=2
   rc71105 stage0(.clk(clk), .reset(reset), .next(next_0), .next_out(next_1),
    .X0(t0_0), .Y0(t1_0),
    .X1(t0_1), .Y1(t1_1),
    .X2(t0_2), .Y2(t1_2),
    .X3(t0_3), .Y3(t1_3));


// latency=37, gap=37
   ICompose_71342 IComposeInst71553(.next(next_1), .clk(clk), .reset(reset), .next_out(next_2),
       .X0(t1_0), .Y0(t2_0),
       .X1(t1_1), .Y1(t2_1),
       .X2(t1_2), .Y2(t2_2),
       .X3(t1_3), .Y3(t2_3));


endmodule

// Latency: 4
// Gap: 2
module rc71105(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [7:0] t0;
   wire [7:0] s0;
   assign t0 = {X0, X1};
   wire [7:0] t1;
   wire [7:0] s1;
   assign t1 = {X2, X3};
   assign Y0 = s0[7:4];
   assign Y1 = s0[3:0];
   assign Y2 = s1[7:4];
   assign Y3 = s1[3:0];

   perm71103 instPerm71554(.x0(t0), .y0(s0),
    .x1(t1), .y1(s1),
   .clk(clk), .next(next), .next_out(next_out), .reset(reset)
);



endmodule

// Latency: 4
// Gap: 2
module perm71103(clk, next, reset, next_out,
   x0, y0,
   x1, y1);
   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;

   input [width-1:0]  x0;
   output [width-1:0]  y0;
   wire [width-1:0]  ybuff0;
   input [width-1:0]  x1;
   output [width-1:0]  y1;
   wire [width-1:0]  ybuff1;
   input 	      clk, next, reset;
   output 	     next_out;

   wire    	     next0;

   reg              inFlip0, outFlip0;
   reg              inActive, outActive;

   wire [logBanks-1:0] inBank0, outBank0;
   wire [logDepth-1:0] inAddr0, outAddr0;
   wire [logBanks-1:0] outBank_a0;
   wire [logDepth-1:0] outAddr_a0;
   wire [logDepth+logBanks-1:0] addr0, addr0b, addr0c;
   wire [logBanks-1:0] inBank1, outBank1;
   wire [logDepth-1:0] inAddr1, outAddr1;
   wire [logBanks-1:0] outBank_a1;
   wire [logDepth-1:0] outAddr_a1;
   wire [logDepth+logBanks-1:0] addr1, addr1b, addr1c;


   reg [logDepth-1:0]  inCount, outCount, outCount_d, outCount_dd, outCount_for_rd_addr, outCount_for_rd_data;  

   assign    addr0 = {inCount, 1'd0};
   assign    addr0b = {outCount, 1'd0};
   assign    addr0c = {outCount_for_rd_addr, 1'd0};
   assign    addr1 = {inCount, 1'd1};
   assign    addr1b = {outCount, 1'd1};
   assign    addr1c = {outCount_for_rd_addr, 1'd1};
    wire [width+logDepth-1:0] w_0_0, w_0_1, w_1_0, w_1_1;

    reg [width-1:0] z_0_0;
    reg [width-1:0] z_0_1;
    wire [width-1:0] z_1_0, z_1_1;

    wire [logDepth-1:0] u_0_0, u_0_1, u_1_0, u_1_1;

    always @(posedge clk) begin
    end

   assign inBank0[0] = addr0[1] ^ addr0[0];
   assign inAddr0[0] = addr0[0];
   assign outBank0[0] = addr0b[1] ^ addr0b[0];
   assign outAddr0[0] = addr0b[1];
   assign outBank_a0[0] = addr0c[1] ^ addr0c[0];
   assign outAddr_a0[0] = addr0c[1];

   assign inBank1[0] = addr1[1] ^ addr1[0];
   assign inAddr1[0] = addr1[0];
   assign outBank1[0] = addr1b[1] ^ addr1b[0];
   assign outAddr1[0] = addr1b[1];
   assign outBank_a1[0] = addr1c[1] ^ addr1c[0];
   assign outAddr_a1[0] = addr1c[1];

   shiftRegFIFO #(2, 1) shiftFIFO_71557(.X(next), .Y(next0), .clk(clk));


   shiftRegFIFO #(2, 1) shiftFIFO_71560(.X(next0), .Y(next_out), .clk(clk));


   memArray4_71103 #(numBanks, logBanks, depth, logDepth, width)
     memSys(.inFlip(inFlip0), .outFlip(outFlip0), .next(next), .reset(reset),
        .x0(w_1_0[width+logDepth-1:logDepth]), .y0(ybuff0),
        .inAddr0(w_1_0[logDepth-1:0]),
        .outAddr0(u_1_0), 
        .x1(w_1_1[width+logDepth-1:logDepth]), .y1(ybuff1),
        .inAddr1(w_1_1[logDepth-1:0]),
        .outAddr1(u_1_1), 
        .clk(clk));

    reg resetOutCountRd2_2;
    reg resetOutCountRd2_3;

    always @(posedge clk) begin
        if (reset == 1) begin
            resetOutCountRd2_2 <= 0;
            resetOutCountRd2_3 <= 0;
        end
        else begin
            resetOutCountRd2_2 <= (inCount == 1) ? 1'b1 : 1'b0;
            resetOutCountRd2_3 <= resetOutCountRd2_2;
            if (resetOutCountRd2_3 == 1'b1)
                outCount_for_rd_data <= 0;
            else
                outCount_for_rd_data <= outCount_for_rd_data+1;
        end
    end
   always @(posedge clk) begin
      if (reset == 1) begin
      z_0_0 <= 0;
      z_0_1 <= 0;
         inFlip0 <= 0; outFlip0 <= 1; outCount <= 0; inCount <= 0;
        outCount_for_rd_addr <= 0;
      end
      else begin
          outCount_d <= outCount;
          outCount_dd <= outCount_d;
         if (inCount == 1)
            outCount_for_rd_addr <= 0;
         else
            outCount_for_rd_addr <= outCount_for_rd_addr+1;
      z_0_0 <= ybuff0;
      z_0_1 <= ybuff1;
         if (inCount == 1) begin
            outFlip0 <= ~outFlip0;
            outCount <= 0;
         end
         else
            outCount <= outCount+1;
         if (inCount == 1) begin
            inFlip0 <= ~inFlip0;
         end
         if (next == 1) begin
            if (inCount >= 1)
               inFlip0 <= ~inFlip0;
            inCount <= 0;
         end
         else
            inCount <= inCount + 1;
      end
   end
    assign w_0_0 = {x0, inAddr0};
    assign w_0_1 = {x1, inAddr1};
    assign y0 = z_1_0;
    assign y1 = z_1_1;
    assign u_0_0 = outAddr_a0;
    assign u_0_1 = outAddr_a1;
    wire wr_ctrl_st_0;
    assign wr_ctrl_st_0 = inCount[0];

    switch #(logDepth+width) in_sw_0_0(.x0(w_0_0), .x1(w_0_1), .y0(w_1_0), .y1(w_1_1), .ctrl(wr_ctrl_st_0));
    wire rdd_ctrl_st_0;
    assign rdd_ctrl_st_0 = outCount_for_rd_data[0];

    switch #(width) out_sw_0_0(.x0(z_0_0), .x1(z_0_1), .y0(z_1_0), .y1(z_1_1), .ctrl(rdd_ctrl_st_0));
    wire rda_ctrl_st_0;
    assign rda_ctrl_st_0 = outCount_for_rd_addr[0];

    switch #(logDepth) rdaddr_sw_0_0(.x0(u_0_0), .x1(u_0_1), .y0(u_1_0), .y1(u_1_1), .ctrl(rda_ctrl_st_0));
endmodule

module memArray4_71103(next, reset,
                x0, y0,
                inAddr0,
                outAddr0,
                x1, y1,
                inAddr1,
                outAddr1,
                clk, inFlip, outFlip);

   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;
         
   input     clk, next, reset;
   input    inFlip, outFlip;
   wire    next0;
   
   input [width-1:0]   x0;
   output [width-1:0]  y0;
   input [logDepth-1:0] inAddr0, outAddr0;
   input [width-1:0]   x1;
   output [width-1:0]  y1;
   input [logDepth-1:0] inAddr1, outAddr1;
   shiftRegFIFO #(2, 1) shiftFIFO_71563(.X(next), .Y(next0), .clk(clk));


   memMod #(depth*2, width, logDepth+1) 
     memMod0(.in(x0), .out(y0), .inAddr({inFlip, inAddr0}),
	   .outAddr({outFlip, outAddr0}), .writeSel(1'b1), .clk(clk));   
   memMod #(depth*2, width, logDepth+1) 
     memMod1(.in(x1), .out(y1), .inAddr({inFlip, inAddr1}),
	   .outAddr({outFlip, outAddr1}), .writeSel(1'b1), .clk(clk));   
endmodule

module shiftRegFIFO(X, Y, clk);
   parameter depth=1, width=1;

   output [width-1:0] Y;
   input  [width-1:0] X;
   input              clk;

   reg [width-1:0]    mem [depth-1:0];
   integer            index;

   assign Y = mem[depth-1];

   always @ (posedge clk) begin
      for(index=1;index<depth;index=index+1) begin
         mem[index] <= mem[index-1];
      end
      mem[0]<=X;
   end
endmodule


module memMod(in, out, inAddr, outAddr, writeSel, clk);
   
   parameter depth=1024, width=16, logDepth=10;
   
   input [width-1:0]    in;
   input [logDepth-1:0] inAddr, outAddr;
   input 	        writeSel, clk;
   output [width-1:0] 	out;
   reg [width-1:0] 	out;
   
   // synthesis attribute ram_style of mem is block

   reg [width-1:0] 	mem[depth-1:0]; 
   
   always @(posedge clk) begin
      out <= mem[outAddr];
      
      if (writeSel)
        mem[inAddr] <= in;
   end
endmodule 



module memMod_dist(in, out, inAddr, outAddr, writeSel, clk);
   
   parameter depth=1024, width=16, logDepth=10;
   
   input [width-1:0]    in;
   input [logDepth-1:0] inAddr, outAddr;
   input 	        writeSel, clk;
   output [width-1:0] 	out;
   reg [width-1:0] 	out;
   
   // synthesis attribute ram_style of mem is distributed

   reg [width-1:0] 	mem[depth-1:0]; 
   
   always @(posedge clk) begin
      out <= mem[outAddr];
      
      if (writeSel)
        mem[inAddr] <= in;
   end
endmodule 

module switch(ctrl, x0, x1, y0, y1);
    parameter width = 16;
    input [width-1:0] x0, x1;
    output [width-1:0] y0, y1;
    input ctrl;
    assign y0 = (ctrl == 0) ? x0 : x1;
    assign y1 = (ctrl == 0) ? x1 : x0;
endmodule

// Latency: 37
// Gap: 37
module ICompose_71342(clk, reset, next, next_out,
      X0, Y0,
      X1, Y1,
      X2, Y2,
      X3, Y3);

   output next_out;
   reg next_out;
   input clk, reset, next;

   reg [4:0] cycle_count;
   reg [1:0] count;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   reg [3:0] Y0,
      Y1,
      Y2,
      Y3;

   reg int_next;
   reg state;
   wire [3:0] t0; 
   reg [3:0] s0;
   wire [3:0] t1; 
   reg [3:0] s1;
   wire [3:0] t2; 
   reg [3:0] s2;
   wire [3:0] t3; 
   reg [3:0] s3;

   reg [1:0] iri_state;
   wire int_next_out;
   reg [1:0] i1;

   statementList71340 instList71564 (.clk(clk), .reset(reset), .next(int_next), .next_out(int_next_out),
      .i1_in(i1),
    .X0(s0), .Y0(t0),
    .X1(s1), .Y1(t1),
    .X2(s2), .Y2(t2),
    .X3(s3), .Y3(t3));

   always @(posedge clk) begin
      if (reset == 1) begin
         int_next <= 0;
         i1 <= 1;
         cycle_count <= 0;
         next_out <= 0;
         iri_state <= 0;
         Y0 <= 0;
         Y1 <= 0;
         Y2 <= 0;
         Y3 <= 0;
      end
      else begin
         Y0 <= t0;
         Y1 <= t1;
         Y2 <= t2;
         Y3 <= t3;
         next_out <= 0;
         case (iri_state)
            0: begin
               i1 <= 1;
               cycle_count <= 0;
               if (next == 1) begin
                  int_next <= 1;
                  iri_state <= 1;
                  
               end
               else begin
                  int_next <= 0;
                  iri_state <= 0;
               end
            end
            1: begin
               int_next <= 0;
               cycle_count <= cycle_count + 1;
               i1 <= i1;
               if (cycle_count < 16)
                  iri_state <= 1;
               else
                  iri_state <= 2;
            end
            2: begin
               cycle_count <= 0;
               i1 <= i1 - 1;
               if (i1 > 0) begin
                  iri_state <= 1;
                  int_next <= 1;
               end
               else begin
                  iri_state <= 0;
                  next_out <= 1;
                  int_next <= 0;
               end
            end
         endcase               
      end
   end

   always @(posedge clk) begin
      if (reset == 1) begin
         state <= 0;
         count <= 0;
         s0 <= 0;
         s1 <= 0;
         s2 <= 0;
         s3 <= 0;
      end      
      else begin
         case (state)
            0: begin
               count <= 0;
               if (next == 1) begin
                  state <= 1;
                  count <= 0;
                  s0 <= X0; 
                  s1 <= X1; 
                  s2 <= X2; 
                  s3 <= X3; 
               end
               else begin
                  state <= 0;
                  count <= 0;
                  s0 <= t0; 
                  s1 <= t1; 
                  s2 <= t2; 
                  s3 <= t3; 
               end               
            end
            1: begin
               count <= count + 1;
               if (count < 2) begin
                  s0 <= X0; 
                  s1 <= X1; 
                  s2 <= X2; 
                  s3 <= X3; 
                  state <= 1;                    
               end
               else begin
                  s0 <= t0; 
                  s1 <= t1; 
                  s2 <= t2; 
                  s3 <= t3; 
                  state <= 0;
               end
            end
         endcase               
      end
   end
endmodule

// Latency: 17
// Gap: 2
// module_name_is:statementList71340
module statementList71340(clk, reset, next, next_out,
   i1_in,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [1:0] i1_in;
   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [3:0] t0_0;
   wire [3:0] t0_1;
   wire [3:0] t0_2;
   wire [3:0] t0_3;
   wire next_0;
   wire [3:0] t1_0;
   wire [3:0] t1_1;
   wire [3:0] t1_2;
   wire [3:0] t1_3;
   wire next_1;
   wire [3:0] t2_0;
   wire [3:0] t2_1;
   wire [3:0] t2_2;
   wire [3:0] t2_3;
   wire next_2;
   wire [3:0] t3_0;
   wire [3:0] t3_1;
   wire [3:0] t3_2;
   wire [3:0] t3_3;
   wire next_3;
   wire [1:0] i1;
   wire [1:0] i1_0;
   assign t0_0 = X0;
   assign Y0 = t3_0;
   assign t0_1 = X1;
   assign Y1 = t3_1;
   assign t0_2 = X2;
   assign Y2 = t3_2;
   assign t0_3 = X3;
   assign Y3 = t3_3;
   assign next_0 = next;
   assign next_out = next_3;

   assign i1_0 = i1_in;

// latency=11, gap=2
   DirSum_71255 DirSumInst71567(.next(next_0), .clk(clk), .reset(reset), .next_out(next_1),
.i1(i1_0),
       .X0(t0_0), .Y0(t1_0),
       .X1(t0_1), .Y1(t1_1),
       .X2(t0_2), .Y2(t1_2),
       .X3(t0_3), .Y3(t1_3));


// latency=2, gap=2
   codeBlock71257 codeBlockIsnt71568(.clk(clk), .reset(reset), .next_in(next_1), .next_out(next_2),
       .X0_in(t1_0), .Y0(t2_0),
       .X1_in(t1_1), .Y1(t2_1),
       .X2_in(t1_2), .Y2(t2_2),
       .X3_in(t1_3), .Y3(t2_3));


// latency=4, gap=2
   rc71338 instrc71569(.clk(clk), .reset(reset), .next(next_2), .next_out(next_3),
    .X0(t2_0), .Y0(t3_0),
    .X1(t2_1), .Y1(t3_1),
    .X2(t2_2), .Y2(t3_2),
    .X3(t2_3), .Y3(t3_3));


endmodule

// Latency: 11
// Gap: 2
module DirSum_71255(clk, reset, next, next_out,
      i1,
      X0, Y0,
      X1, Y1,
      X2, Y2,
      X3, Y3);

   output next_out;
   input clk, reset, next;

   input [1:0] i1;
   reg [0:0] i2;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   always @(posedge clk) begin
      if (reset == 1) begin
         i2 <= 0;
      end
      else begin
         if (next == 1)
            i2 <= 0;
         else if (i2 == 1)
            i2 <= 0;
         else
            i2 <= i2 + 1;
      end
   end

   codeBlock71107 codeBlockIsnt71570(.clk(clk), .reset(reset), .next_in(next), .next_out(next_out),
.i2_in(i2),
.i1_in(i1),
       .X0_in(X0), .Y0(Y0),
       .X1_in(X1), .Y1(Y1),
       .X2_in(X2), .Y2(Y2),
       .X3_in(X3), .Y3(Y3));

endmodule

module D2_71247(addr, out, clk);
   input clk;
   output [3:0] out;
   reg [3:0] out, out2, out3;
   input [1:0] addr;

   always @(posedge clk) begin
      out2 <= out3;
      out <= out2;
   case(addr)
      0: out3 <= 4'h0;
      1: out3 <= 4'hc;
      2: out3 <= 4'h0;
      3: out3 <= 4'h0;
      default: out3 <= 0;
   endcase
   end
// synthesis attribute rom_style of out3 is "block"
endmodule



module D1_71253(addr, out, clk);
   input clk;
   output [3:0] out;
   reg [3:0] out, out2, out3;
   input [1:0] addr;

   always @(posedge clk) begin
      out2 <= out3;
      out <= out2;
   case(addr)
      0: out3 <= 4'h4;
      1: out3 <= 4'h0;
      2: out3 <= 4'h4;
      3: out3 <= 4'hc;
      default: out3 <= 0;
   endcase
   end
// synthesis attribute rom_style of out3 is "block"
endmodule



// Latency: 11
// Gap: 1
module codeBlock71107(clk, reset, next_in, next_out,
   i2_in,
   i1_in,
   X0_in, Y0,
   X1_in, Y1,
   X2_in, Y2,
   X3_in, Y3);

   output next_out;
   input clk, reset, next_in;

   reg next;
   input [0:0] i2_in;
   reg [0:0] i2;
   input [1:0] i1_in;
   reg [1:0] i1;

   input [3:0] X0_in,
      X1_in,
      X2_in,
      X3_in;

   reg   [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   shiftRegFIFO #(10, 1) shiftFIFO_71573(.X(next), .Y(next_out), .clk(clk));


   wire  [1:0] a57;
   wire  [0:0] a59;
   wire  [1:0] a60;
   wire signed [3:0] a70;
   wire signed [3:0] a71;
   wire  [2:0] a58;
   reg  [1:0] tm11;
   reg signed [3:0] tm12;
   reg signed [3:0] tm19;
   reg signed [3:0] tm40;
   reg signed [3:0] tm50;
   reg  [2:0] a61;
   wire  [1:0] a62;
   reg signed [3:0] tm13;
   reg signed [3:0] tm20;
   reg signed [3:0] tm41;
   reg signed [3:0] tm51;
   wire  [2:0] a63;
   reg signed [3:0] tm14;
   reg signed [3:0] tm21;
   reg signed [3:0] tm42;
   reg signed [3:0] tm52;
   reg signed [3:0] tm15;
   reg signed [3:0] tm22;
   reg signed [3:0] tm43;
   reg signed [3:0] tm53;
   reg signed [3:0] tm16;
   reg signed [3:0] tm23;
   reg signed [3:0] tm44;
   reg signed [3:0] tm54;
   wire signed [3:0] tm5;
   wire signed [3:0] a64;
   wire signed [3:0] tm6;
   wire signed [3:0] a66;
   reg signed [3:0] tm17;
   reg signed [3:0] tm24;
   reg signed [3:0] tm45;
   reg signed [3:0] tm55;
   reg signed [3:0] tm7;
   reg signed [3:0] tm8;
   reg signed [3:0] tm18;
   reg signed [3:0] tm25;
   reg signed [3:0] tm46;
   reg signed [3:0] tm56;
   reg signed [3:0] tm47;
   reg signed [3:0] tm57;
   wire signed [3:0] a65;
   wire signed [3:0] a67;
   wire signed [3:0] a68;
   wire signed [3:0] a69;
   reg signed [3:0] tm48;
   reg signed [3:0] tm58;
   wire signed [3:0] Y0;
   wire signed [3:0] Y1;
   wire signed [3:0] Y2;
   wire signed [3:0] Y3;
   reg signed [3:0] tm49;
   reg signed [3:0] tm59;

   wire [0:0] tm1;
   assign tm1 = 1'h1;
   wire [1:0] tm4;
   assign tm4 = 2'h2;

   assign a57 = i2 << 1;
   assign a59 = tm1 << i1;
   assign a60 = {a59, tm1[0:0]};
   assign a70 = X2;
   assign a71 = X3;
   assign a62 = {a61[0:0], a61[1:1]};
   assign a64 = tm5;
   assign a66 = tm6;
   assign Y0 = tm49;
   assign Y1 = tm59;

   D2_71247 instD2inst0_71247(.addr(a63[1:0]), .out(tm6), .clk(clk));

   D1_71253 instD1inst0_71253(.addr(a63[1:0]), .out(tm5), .clk(clk));

    addfxp #(3, 1) add71126(.a({1'b0, a57}), .b({2'b0, tm1}), .clk(clk), .q(a58));    // 0
    subfxp #(3, 1) sub71158(.a({1'b0, a62}), .b({1'b0, tm4}), .clk(clk), .q(a63));    // 2
    multfix #(4, 2) m71180(.a(tm7), .b(tm18), .clk(clk), .q_sc(a65), .q_unsc(), .rst(reset));
    multfix #(4, 2) m71202(.a(tm8), .b(tm25), .clk(clk), .q_sc(a67), .q_unsc(), .rst(reset));
    multfix #(4, 2) m71220(.a(tm8), .b(tm18), .clk(clk), .q_sc(a68), .q_unsc(), .rst(reset));
    multfix #(4, 2) m71231(.a(tm7), .b(tm25), .clk(clk), .q_sc(a69), .q_unsc(), .rst(reset));
    subfxp #(4, 1) sub71209(.a(a65), .b(a67), .clk(clk), .q(Y2));    // 9
    addfxp #(4, 1) add71238(.a(a68), .b(a69), .clk(clk), .q(Y3));    // 9


   always @(posedge clk) begin
      if (reset == 1) begin
         tm7 <= 0;
         tm18 <= 0;
         tm8 <= 0;
         tm25 <= 0;
         tm8 <= 0;
         tm18 <= 0;
         tm7 <= 0;
         tm25 <= 0;
      end
      else begin
         i2 <= i2_in;
         i1 <= i1_in;
         X0 <= X0_in;
         X1 <= X1_in;
         X2 <= X2_in;
         X3 <= X3_in;
         next <= next_in;
         tm11 <= a60;
         tm12 <= a70;
         tm19 <= a71;
         tm40 <= X0;
         tm50 <= X1;
         a61 <= (a58 & tm11);
         tm13 <= tm12;
         tm20 <= tm19;
         tm41 <= tm40;
         tm51 <= tm50;
         tm14 <= tm13;
         tm21 <= tm20;
         tm42 <= tm41;
         tm52 <= tm51;
         tm15 <= tm14;
         tm22 <= tm21;
         tm43 <= tm42;
         tm53 <= tm52;
         tm16 <= tm15;
         tm23 <= tm22;
         tm44 <= tm43;
         tm54 <= tm53;
         tm17 <= tm16;
         tm24 <= tm23;
         tm45 <= tm44;
         tm55 <= tm54;
         tm7 <= a64;
         tm8 <= a66;
         tm18 <= tm17;
         tm25 <= tm24;
         tm46 <= tm45;
         tm56 <= tm55;
         tm47 <= tm46;
         tm57 <= tm56;
         tm48 <= tm47;
         tm58 <= tm57;
         tm49 <= tm48;
         tm59 <= tm58;
      end
   end
endmodule

// Latency: 2
// Gap: 1
module codeBlock71257(clk, reset, next_in, next_out,
   X0_in, Y0,
   X1_in, Y1,
   X2_in, Y2,
   X3_in, Y3);

   output next_out;
   input clk, reset, next_in;

   reg next;

   input [3:0] X0_in,
      X1_in,
      X2_in,
      X3_in;

   reg   [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   shiftRegFIFO #(1, 1) shiftFIFO_71576(.X(next), .Y(next_out), .clk(clk));


   wire signed [3:0] a9;
   wire signed [3:0] a10;
   wire signed [3:0] a11;
   wire signed [3:0] a12;
   wire signed [3:0] t21;
   wire signed [3:0] t22;
   wire signed [3:0] t23;
   wire signed [3:0] t24;
   wire signed [3:0] Y0;
   wire signed [3:0] Y1;
   wire signed [3:0] Y2;
   wire signed [3:0] Y3;


   assign a9 = X0;
   assign a10 = X2;
   assign a11 = X1;
   assign a12 = X3;
   assign Y0 = t21;
   assign Y1 = t22;
   assign Y2 = t23;
   assign Y3 = t24;

    addfxp #(4, 1) add71269(.a(a9), .b(a10), .clk(clk), .q(t21));    // 0
    addfxp #(4, 1) add71284(.a(a11), .b(a12), .clk(clk), .q(t22));    // 0
    subfxp #(4, 1) sub71299(.a(a9), .b(a10), .clk(clk), .q(t23));    // 0
    subfxp #(4, 1) sub71314(.a(a11), .b(a12), .clk(clk), .q(t24));    // 0


   always @(posedge clk) begin
      if (reset == 1) begin
      end
      else begin
         X0 <= X0_in;
         X1 <= X1_in;
         X2 <= X2_in;
         X3 <= X3_in;
         next <= next_in;
      end
   end
endmodule

// Latency: 4
// Gap: 2
module rc71338(clk, reset, next, next_out,
   X0, Y0,
   X1, Y1,
   X2, Y2,
   X3, Y3);

   output next_out;
   input clk, reset, next;

   input [3:0] X0,
      X1,
      X2,
      X3;

   output [3:0] Y0,
      Y1,
      Y2,
      Y3;

   wire [7:0] t0;
   wire [7:0] s0;
   assign t0 = {X0, X1};
   wire [7:0] t1;
   wire [7:0] s1;
   assign t1 = {X2, X3};
   assign Y0 = s0[7:4];
   assign Y1 = s0[3:0];
   assign Y2 = s1[7:4];
   assign Y3 = s1[3:0];

   perm71336 instPerm71577(.x0(t0), .y0(s0),
    .x1(t1), .y1(s1),
   .clk(clk), .next(next), .next_out(next_out), .reset(reset)
);



endmodule

// Latency: 4
// Gap: 2
module perm71336(clk, next, reset, next_out,
   x0, y0,
   x1, y1);
   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;

   input [width-1:0]  x0;
   output [width-1:0]  y0;
   wire [width-1:0]  ybuff0;
   input [width-1:0]  x1;
   output [width-1:0]  y1;
   wire [width-1:0]  ybuff1;
   input 	      clk, next, reset;
   output 	     next_out;

   wire    	     next0;

   reg              inFlip0, outFlip0;
   reg              inActive, outActive;

   wire [logBanks-1:0] inBank0, outBank0;
   wire [logDepth-1:0] inAddr0, outAddr0;
   wire [logBanks-1:0] outBank_a0;
   wire [logDepth-1:0] outAddr_a0;
   wire [logDepth+logBanks-1:0] addr0, addr0b, addr0c;
   wire [logBanks-1:0] inBank1, outBank1;
   wire [logDepth-1:0] inAddr1, outAddr1;
   wire [logBanks-1:0] outBank_a1;
   wire [logDepth-1:0] outAddr_a1;
   wire [logDepth+logBanks-1:0] addr1, addr1b, addr1c;


   reg [logDepth-1:0]  inCount, outCount, outCount_d, outCount_dd, outCount_for_rd_addr, outCount_for_rd_data;  

   assign    addr0 = {inCount, 1'd0};
   assign    addr0b = {outCount, 1'd0};
   assign    addr0c = {outCount_for_rd_addr, 1'd0};
   assign    addr1 = {inCount, 1'd1};
   assign    addr1b = {outCount, 1'd1};
   assign    addr1c = {outCount_for_rd_addr, 1'd1};
    wire [width+logDepth-1:0] w_0_0, w_0_1, w_1_0, w_1_1;

    reg [width-1:0] z_0_0;
    reg [width-1:0] z_0_1;
    wire [width-1:0] z_1_0, z_1_1;

    wire [logDepth-1:0] u_0_0, u_0_1, u_1_0, u_1_1;

    always @(posedge clk) begin
    end

   assign inBank0[0] = addr0[1] ^ addr0[0];
   assign inAddr0[0] = addr0[0];
   assign outBank0[0] = addr0b[1] ^ addr0b[0];
   assign outAddr0[0] = addr0b[1];
   assign outBank_a0[0] = addr0c[1] ^ addr0c[0];
   assign outAddr_a0[0] = addr0c[1];

   assign inBank1[0] = addr1[1] ^ addr1[0];
   assign inAddr1[0] = addr1[0];
   assign outBank1[0] = addr1b[1] ^ addr1b[0];
   assign outAddr1[0] = addr1b[1];
   assign outBank_a1[0] = addr1c[1] ^ addr1c[0];
   assign outAddr_a1[0] = addr1c[1];

   shiftRegFIFO #(2, 1) shiftFIFO_71580(.X(next), .Y(next0), .clk(clk));


   shiftRegFIFO #(2, 1) shiftFIFO_71583(.X(next0), .Y(next_out), .clk(clk));


   memArray4_71336 #(numBanks, logBanks, depth, logDepth, width)
     memSys(.inFlip(inFlip0), .outFlip(outFlip0), .next(next), .reset(reset),
        .x0(w_1_0[width+logDepth-1:logDepth]), .y0(ybuff0),
        .inAddr0(w_1_0[logDepth-1:0]),
        .outAddr0(u_1_0), 
        .x1(w_1_1[width+logDepth-1:logDepth]), .y1(ybuff1),
        .inAddr1(w_1_1[logDepth-1:0]),
        .outAddr1(u_1_1), 
        .clk(clk));

    reg resetOutCountRd2_2;
    reg resetOutCountRd2_3;

    always @(posedge clk) begin
        if (reset == 1) begin
            resetOutCountRd2_2 <= 0;
            resetOutCountRd2_3 <= 0;
        end
        else begin
            resetOutCountRd2_2 <= (inCount == 1) ? 1'b1 : 1'b0;
            resetOutCountRd2_3 <= resetOutCountRd2_2;
            if (resetOutCountRd2_3 == 1'b1)
                outCount_for_rd_data <= 0;
            else
                outCount_for_rd_data <= outCount_for_rd_data+1;
        end
    end
   always @(posedge clk) begin
      if (reset == 1) begin
      z_0_0 <= 0;
      z_0_1 <= 0;
         inFlip0 <= 0; outFlip0 <= 1; outCount <= 0; inCount <= 0;
        outCount_for_rd_addr <= 0;
      end
      else begin
          outCount_d <= outCount;
          outCount_dd <= outCount_d;
         if (inCount == 1)
            outCount_for_rd_addr <= 0;
         else
            outCount_for_rd_addr <= outCount_for_rd_addr+1;
      z_0_0 <= ybuff0;
      z_0_1 <= ybuff1;
         if (inCount == 1) begin
            outFlip0 <= ~outFlip0;
            outCount <= 0;
         end
         else
            outCount <= outCount+1;
         if (inCount == 1) begin
            inFlip0 <= ~inFlip0;
         end
         if (next == 1) begin
            if (inCount >= 1)
               inFlip0 <= ~inFlip0;
            inCount <= 0;
         end
         else
            inCount <= inCount + 1;
      end
   end
    assign w_0_0 = {x0, inAddr0};
    assign w_0_1 = {x1, inAddr1};
    assign y0 = z_1_0;
    assign y1 = z_1_1;
    assign u_0_0 = outAddr_a0;
    assign u_0_1 = outAddr_a1;
    wire wr_ctrl_st_0;
    assign wr_ctrl_st_0 = inCount[0];

    switch #(logDepth+width) in_sw_0_0(.x0(w_0_0), .x1(w_0_1), .y0(w_1_0), .y1(w_1_1), .ctrl(wr_ctrl_st_0));
    wire rdd_ctrl_st_0;
    assign rdd_ctrl_st_0 = outCount_for_rd_data[0];

    switch #(width) out_sw_0_0(.x0(z_0_0), .x1(z_0_1), .y0(z_1_0), .y1(z_1_1), .ctrl(rdd_ctrl_st_0));
    wire rda_ctrl_st_0;
    assign rda_ctrl_st_0 = outCount_for_rd_addr[0];

    switch #(logDepth) rdaddr_sw_0_0(.x0(u_0_0), .x1(u_0_1), .y0(u_1_0), .y1(u_1_1), .ctrl(rda_ctrl_st_0));
endmodule

module memArray4_71336(next, reset,
                x0, y0,
                inAddr0,
                outAddr0,
                x1, y1,
                inAddr1,
                outAddr1,
                clk, inFlip, outFlip);

   parameter numBanks = 2;
   parameter logBanks = 1;
   parameter depth = 2;
   parameter logDepth = 1;
   parameter width = 8;
         
   input     clk, next, reset;
   input    inFlip, outFlip;
   wire    next0;
   
   input [width-1:0]   x0;
   output [width-1:0]  y0;
   input [logDepth-1:0] inAddr0, outAddr0;
   input [width-1:0]   x1;
   output [width-1:0]  y1;
   input [logDepth-1:0] inAddr1, outAddr1;
   shiftRegFIFO #(2, 1) shiftFIFO_71586(.X(next), .Y(next0), .clk(clk));


   memMod #(depth*2, width, logDepth+1) 
     memMod0(.in(x0), .out(y0), .inAddr({inFlip, inAddr0}),
	   .outAddr({outFlip, outAddr0}), .writeSel(1'b1), .clk(clk));   
   memMod #(depth*2, width, logDepth+1) 
     memMod1(.in(x1), .out(y1), .inAddr({inFlip, inAddr1}),
	   .outAddr({outFlip, outAddr1}), .writeSel(1'b1), .clk(clk));   
endmodule



						module multfix(clk, rst, a, b, q_sc, q_unsc);
						   parameter WIDTH=35, CYCLES=6;

						   input signed [WIDTH-1:0]    a,b;
						   output [WIDTH-1:0]          q_sc;
						   output [WIDTH-1:0]              q_unsc;

						   input                       clk, rst;
						   
						   reg signed [2*WIDTH-1:0]    q[CYCLES-1:0];
						   wire signed [2*WIDTH-1:0]   res;   
						   integer                     i;

						   assign                      res = q[CYCLES-1];   
						   
						   assign                      q_unsc = res[WIDTH-1:0];
						   assign                      q_sc = {res[2*WIDTH-1], res[2*WIDTH-4:WIDTH-2]};
						      
						   always @(posedge clk) begin
						      q[0] <= a * b;
						      for (i = 1; i < CYCLES; i=i+1) begin
						         q[i] <= q[i-1];
						      end
						   end
						                  
						endmodule 
module addfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a+b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
   
endmodule

module subfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a-b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
  
endmodule
