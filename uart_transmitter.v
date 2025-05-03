`timescale 1ns / 1ps
module uart_transmitter
    (
        input clk_100MHz,               // clock of basys3 board
        input reset,                    // Reset
        input tx_start,                 // begin data transmission (FIFO NOT empty)--> inverse of Tx FIFO`s empty line
        input sample_tick,              // from baud rate generator
        input [DBITS-1:0] data_in,      // data word from FIFO
        output reg tx_done,             // signal indicating the end of transmission sent to Tx FIFO
        output tx                       // transmitter data line
    );
    
     parameter   DBITS = 8;             // number of data bits
     parameter   SB_TICK = 16;          // number of sample ticks per bit

    // State Machine States
    parameter [1:0] idle  = 2'b00;
    parameter [1:0] start = 2'b01;
    parameter [1:0] data  = 2'b10;
    parameter [1:0] stop  = 2'b11;
    
    // Registers                    
    reg [1:0] state, next_state;            // state registers
    reg [DBITS-1:0] data_reg, data_next;    // assembled data word to transmit serially
    reg [3:0] tick_reg, tick_next;          // number of ticks received from baud rate generator(counting of sample ticks)
    reg [2:0] nbits_reg, nbits_next;        // number of bits transmitted in data state(counting of data bits transmitted)
    reg tx_reg, tx_next;                    // To avoid missing of trasmitting start and stop bits
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset) 
        begin
            state <= idle;
            nbits_reg <= 0;
            tick_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;                 // As Tx line is held high in idle state
        end
        else 
        begin
            state <= next_state;
            nbits_reg <= nbits_next;
            tick_reg <= tick_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    
    // State Machine Logic
    always @* 
    begin
        next_state = state;
        tx_done = 1'b0;
        nbits_next = nbits_reg;
        tick_next = tick_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(state)
            idle: 
            begin
                tx_next = 1'b1;              // As Tx line is held high in idle state   
                if(tx_start) 
                begin                        // when FIFO is NOT empty
                    next_state = start;
                    tick_next = 0;
                    data_next = data_in;
                end
            end
            
            start: 
            begin
                tx_next = 1'b0;              // start bit
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) 
                    begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            data: 
            begin
                tx_next = data_reg[0];       // transmission starts from LSB
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) 
                    begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            stop: 
            begin
                tx_next = 1'b1;              // back to idle
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        tx_done = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_reg;
 
endmodule
