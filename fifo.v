`timescale 1ns /1ps
module fifo
	(
	input clk,
	input reset,
	input write_to_fifo,
	input read_from_fifo,
	input [DATA_SIZE-1:0] write_data_in,
	output [DATA_SIZE-1:0] read_data_out,
	output empty,
	output full	
    );

    parameter DATA_SIZE= 8;       	// number of bits in a data word
	parameter ADDR_SPACE_EXP= 2;	// number of bits used for addressing the memory. so total 2^2=4 addresses are stored

	// signal declaration
	reg [DATA_SIZE-1:0] memory [2**ADDR_SPACE_EXP-1:0]; // register file block storing 4 addresses, each address holds 8 data bits
	reg [ADDR_SPACE_EXP-1:0] current_write_addr, current_write_addr_buff, next_write_addr;
	reg [ADDR_SPACE_EXP-1:0] current_read_addr, current_read_addr_buff, next_read_addr;
	reg fifo_full, fifo_empty, full_buff, empty_buff;
	wire write_enabled;
	
	// body
	// write operation
	always @(posedge clk)
		if(write_enabled)
			memory[current_write_addr] <= write_data_in;
			
	// read operation
	assign read_data_out = memory[current_read_addr];
	
	// only allow write operation when FIFO is NOT full
	assign write_enabled = write_to_fifo & ~fifo_full;
	
	// register logic
	always @(posedge clk or posedge reset)
		if(reset) begin
			current_write_addr 	<= 0;
			current_read_addr 	<= 0;
			fifo_full 			<= 1'b0;
			fifo_empty 			<= 1'b1;       // FIFO is empty after reset
		end
		else begin
			current_write_addr  <= current_write_addr_buff;
			current_read_addr   <= current_read_addr_buff;
			fifo_full  			<= full_buff;
			fifo_empty 			<= empty_buff;
		end

	// next state logic
	always @* begin
		// successive pointer values
		next_write_addr = current_write_addr + 1;
		next_read_addr  = current_read_addr + 1;
		
		// default: keep old values
		current_write_addr_buff = current_write_addr;
		current_read_addr_buff  = current_read_addr;
		full_buff  = fifo_full;
		empty_buff = fifo_empty;
		
		// Button press logic
		case({write_to_fifo, read_from_fifo})     // checking both buttons
			// 2'b00: neither buttons pressed, do nothing
			
			2'b01:	// read button pressed
				if(~fifo_empty) begin   // FIFO not empty
					current_read_addr_buff = next_read_addr;
					full_buff = 1'b0;   // after read, FIFO not full anymore
					if(next_read_addr == current_write_addr)
						empty_buff = 1'b1;
				end
			
			2'b10:	// write button pressed
				if(~fifo_full) begin	// FIFO not full
					current_write_addr_buff = next_write_addr;
					empty_buff = 1'b0;  // after write, FIFO not empty anymore
					if(next_write_addr == current_read_addr)
						full_buff = 1'b1;
				end
				
			2'b11:	begin	// write and read
				current_write_addr_buff = next_write_addr;
				current_read_addr_buff  = next_read_addr;
				end
		endcase			
	end

	// output
	assign full = fifo_full;
	assign empty = fifo_empty;

endmodule
