/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module uart_mm #(
	parameter csr_addr = 4'h0,
	parameter clk_freq = 100000000,
	parameter baud = 115200
) (
	input sys_clk,
	input sys_rst,
	
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

	output rx_irq,
	output tx_irq,

	input uart_rx,
	output uart_tx
);

reg [15:0] divisor;
wire [7:0] rx_data;
wire [7:0] tx_data;
wire tx_wr;

reg thru;
wire uart_tx_transceiver;

uart_transceiver transceiver(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.uart_rx(uart_rx),
	.uart_tx(uart_tx_transceiver),

	.divisor(divisor),

	.rx_data(rx_data),
	.rx_done(rx_irq),

	.tx_data(tx_data),
	.tx_wr(tx_wr),
	.tx_done(tx_irq)
);

assign uart_tx = thru ? uart_rx : uart_tx_transceiver;

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

assign tx_data = csr_di[7:0];
assign tx_wr = csr_selected & csr_we & (csr_a[1:0] == 2'b00);

parameter default_divisor = clk_freq/baud/16;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		divisor <= default_divisor;
		csr_do <= 32'd0;
	end else begin
		csr_do <= 32'd0;
		if(csr_selected) begin
			case(csr_a[1:0])
				2'b00: csr_do <= rx_data;
				2'b01: csr_do <= divisor;
				2'b10: csr_do <= thru;
			endcase
			if(csr_we) begin
				case(csr_a[1:0])
					2'b00:; /* handled by transceiver */
					2'b01: divisor <= csr_di[15:0];
					2'b10: thru <= csr_di[0];
				endcase
			end
		end
	end
end

endmodule

module uart_transceiver(
	input sys_rst,
	input sys_clk,

	input uart_rx,
	output reg uart_tx,

	input [15:0] divisor,

	output reg [7:0] rx_data,
	output reg rx_done,

	input [7:0] tx_data,
	input tx_wr,
	output reg tx_done
);

//-----------------------------------------------------------------
// enable16 generator
//-----------------------------------------------------------------
reg [15:0] enable16_counter;

wire enable16;
assign enable16 = (enable16_counter == 16'd0);

always @(posedge sys_clk) begin
	if(sys_rst)
		enable16_counter <= divisor - 16'b1;
	else begin
		enable16_counter <= enable16_counter - 16'd1;
		if(enable16)
			enable16_counter <= divisor - 16'b1;
	end
end

//-----------------------------------------------------------------
// Synchronize uart_rx
//-----------------------------------------------------------------
reg uart_rx1;
reg uart_rx2;

always @(posedge sys_clk) begin
	uart_rx1 <= uart_rx;
	uart_rx2 <= uart_rx1;
end

//-----------------------------------------------------------------
// UART RX Logic
//-----------------------------------------------------------------
reg rx_busy;
reg [3:0] rx_count16;
reg [3:0] rx_bitcount;
reg [7:0] rx_reg;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		rx_done <= 1'b0;
		rx_busy <= 1'b0;
		rx_count16  <= 4'd0;
		rx_bitcount <= 4'd0;
	end else begin
		rx_done <= 1'b0;

		if(enable16) begin
			if(~rx_busy) begin // look for start bit
				if(~uart_rx2) begin // start bit found
					rx_busy <= 1'b1;
					rx_count16 <= 4'd7;
					rx_bitcount <= 4'd0;
				end
			end else begin
				rx_count16 <= rx_count16 + 4'd1;

				if(rx_count16 == 4'd0) begin // sample
					rx_bitcount <= rx_bitcount + 4'd1;

					if(rx_bitcount == 4'd0) begin // verify startbit
						if(uart_rx2)
							rx_busy <= 1'b0;
					end else if(rx_bitcount == 4'd9) begin
						rx_busy <= 1'b0;
						if(uart_rx2) begin // stop bit ok
							rx_data <= rx_reg;
							rx_done <= 1'b1;
						end // ignore RX error
					end else
						rx_reg <= {uart_rx2, rx_reg[7:1]};
				end
			end
		end
	end
end

//-----------------------------------------------------------------
// UART TX Logic
//-----------------------------------------------------------------
reg tx_busy;
reg [3:0] tx_bitcount;
reg [3:0] tx_count16;
reg [7:0] tx_reg;

always @(posedge sys_clk) begin
	if(sys_rst) begin
		tx_done <= 1'b0;
		tx_busy <= 1'b0;
		uart_tx <= 1'b1;
	end else begin
		tx_done <= 1'b0;
		if(tx_wr) begin
			tx_reg <= tx_data;
			tx_bitcount <= 4'd0;
			tx_count16 <= 4'd1;
			tx_busy <= 1'b1;
			uart_tx <= 1'b0;
`ifdef SIMULATION
			$display("UART: %c", tx_data);
`endif
		end else if(enable16 && tx_busy) begin
			tx_count16  <= tx_count16 + 4'd1;

			if(tx_count16 == 4'd0) begin
				tx_bitcount <= tx_bitcount + 4'd1;
				
				if(tx_bitcount == 4'd8) begin
					uart_tx <= 1'b1;
				end else if(tx_bitcount == 4'd9) begin
					uart_tx <= 1'b1;
					tx_busy <= 1'b0;
					tx_done <= 1'b1;
				end else begin
					uart_tx <= tx_reg[0];
					tx_reg <= {1'b0, tx_reg[7:1]};
				end
			end
		end
	end
end

endmodule
