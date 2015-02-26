//-----------------------------------------
// This block takes care of framing up an RS232 output word,
// and sending it out the "txd" line in a serial fashion.
// The user is responsible for providing appropriate clk
// and clock enable (tx_clk) to achieve the desired Baudot interval
// (a new bit is transmitted each (tx_clk/clock_factor) pulses)
// (NOTE: the state machine operates at "clock_factor" times the
//   desired BAUD rate.  Set it to anything between 2 and 16,
//   inclusive.  It may be useful to adjust the clock_factor in order to
//   generate good BAUD clocks from odd Fclk frequencies on your board.)
// A load operation is requested by bringing the "load" line high.  However,
// the load will only be accepted when load_request is also high (which  
// just happens to coincide with tx_clk_1x inside of the state machine...)
// Therefore, the "load_request" line may be used as a bus acknowledgement.
// (load_request = "ack_o" in Wishbone terminology -- but it only lasts for
//  one single clk cycle, so be careful how you use it!)
//
// If the "load_request" line is tied to "load," the unit will send
// data characters continuously, with no gaps in between transmissions.
//
// Note that support is not provided for 1.5 stop bits, only integral
// numbers of stop bits are allowed.  A selection of more than 2 for
// number of stop bits will still work fine, it will simply introduce
// a delay between characters being transmitted, although the length
// of the transmitter shift register will also grow to include one
// stage for each stop bit requested...

module rs232tx (
                clk,
                tx_clk,
                reset,
                load,
                data,
                load_request,
                txd
                );

  parameter START_BITS_PP  = 1;
  parameter DATA_BITS_PP  = 8;
  parameter STOP_BITS_PP  = 1;
  parameter CLOCK_FACTOR_PP  = 16;
  parameter TX_BIT_COUNT_BITS_PP = 4;  // = ceil(log(total_bits)/log(2)));

// State encodings, provided as parameters
// for flexibility to the one instantiating the module
  parameter m1_idle = 0;
  parameter m1_waiting = 1;
  parameter m1_sending = 3;
  parameter m1_sending_last_bit = 2;


// I/O declarations
  input clk;
  input tx_clk;
  input reset;
  input load;
  input[DATA_BITS_PP-1:0] data;
  output load_request;
  output txd;

  reg load_request;

// local signals
  `define TOTAL_BITS START_BITS_PP + DATA_BITS_PP + STOP_BITS_PP
  
  reg [`TOTAL_BITS-1:0] q;                 // Actual tx shifter
  reg [TX_BIT_COUNT_BITS_PP-1:0] tx_bit_count_l;
  reg [3:0] prescaler_count_l;
  reg [1:0] m1_state;
  reg [1:0] m1_next_state;

  wire [`TOTAL_BITS-1:0] tx_word = {{STOP_BITS_PP{1'b1}},
                                   data,
                                   {START_BITS_PP{1'b0}}};
  wire begin_last_bit;
  wire start_sending;
  wire tx_clk_1x;

  // This is a prescaler to produce the actual transmit clock.
  always @(posedge clk)
  begin
    if (reset) prescaler_count_l <= 0;
    else if (tx_clk)
    begin
      if (prescaler_count_l == (CLOCK_FACTOR_PP-1)) prescaler_count_l <= 0;
      else prescaler_count_l <= prescaler_count_l + 1;
    end
  end
  assign tx_clk_1x = ((prescaler_count_l == (CLOCK_FACTOR_PP-1) ) && tx_clk);

  // This is the transmitted bit counter
  always @(posedge clk)
  begin
    if (start_sending) tx_bit_count_l <= 0;
    else if (tx_clk_1x)
    begin
      if (tx_bit_count_l == (`TOTAL_BITS-2)) tx_bit_count_l <= 0;
      else tx_bit_count_l <= tx_bit_count_l + 1;
    end
  end
  assign begin_last_bit = ((tx_bit_count_l == (`TOTAL_BITS-2) ) && tx_clk_1x);

  assign start_sending = (tx_clk_1x && load);


  // This state machine handles sending out the transmit data
  
  // State register.
  always @(posedge clk)
  begin : state_register
    if (reset) m1_state <= m1_idle;
    else m1_state <= m1_next_state;
  end

  // State transition logic
  always @(m1_state or tx_clk_1x or load or begin_last_bit)
  begin : state_logic
    // Signal is low unless changed in a state condition.
    load_request <= 0;
    case (m1_state)
      m1_idle :
            begin
              load_request <= tx_clk_1x;
              if (tx_clk_1x && load) m1_next_state <= m1_sending;
              else m1_next_state <= m1_idle;
            end
      m1_sending :
            begin
              if (begin_last_bit) m1_next_state <= m1_sending_last_bit;
              else m1_next_state <= m1_sending;
            end
      m1_sending_last_bit :
            begin
              load_request <= tx_clk_1x;
              if (load & tx_clk_1x) m1_next_state <= m1_sending;
              else if (tx_clk_1x) m1_next_state <= m1_idle;
              else m1_next_state <= m1_sending_last_bit;
            end
      default :
            begin
              m1_next_state <= m1_idle;
            end
    endcase
  end


  // This is the transmit shifter
  always @(posedge clk)
  begin : txd_shifter
    if (reset) q <= 0;  // set output to all ones
    else if (start_sending) q <= ~tx_word;
    else if (tx_clk_1x) q <= {1'b0,q[`TOTAL_BITS-1:1]};
  end
  
  assign txd = ~q[0];

endmodule

