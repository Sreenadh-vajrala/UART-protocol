module uart_receiver
    (
        input clk_100MHz,               // clock of basys3 board
        input reset,                    // reset
        input rx,                       // incoming serial data
        input sample_tick,              // sample tick from baud rate generator
        output reg data_ready,          // signal indicating that a full data byte(8 bits) has been received.
        output [DBITS-1:0] data_out     // data to FIFO
    );
    parameter SB_TICK = 16;              // number of sample ticks per bit
    parameter half_SBT = SB_TICK/2;     
    parameter DBITS = 8;                // number of data bits in a data word
    
    // State Machine States
    parameter [1:0]  idle  = 2'b00;
    parameter [1:0]  start = 2'b01;
    parameter [1:0]  data  = 2'b10;
    parameter [1:0]  stop  = 2'b11;
    
    // Registers                 
    reg [1:0] state, next_state;        // state registers
    reg [7:0] data_reg, data_next;      // storing the data word that will be sent to receivers fifo unit
    reg [2:0] nbits_reg, nbits_next;    // counting of data bits received
    reg [3:0] tick_reg, tick_next;      // counting of sample ticks
    
    // Register Logic
    always @(posedge clk_100MHz or posedge reset)
        if(reset) 
        begin
            state <= idle;
            nbits_reg <= 0;
            tick_reg <= 0;
            data_reg <= 0;
        end
        else 
        begin
            state <= next_state;
            nbits_reg <= nbits_next;
            tick_reg <= tick_next;
            data_reg <= data_next;
        end        

    // State Machine Logic
    always @* begin
        next_state = state; 
        data_ready = 1'b0;
        nbits_next = nbits_reg;
        tick_next = tick_reg;
        data_next = data_reg;

        case(state)
            idle:
                if(~rx) 
                begin
                    next_state = start;
                    tick_next = 0;
                end
            start:
                if(sample_tick)
                    if(tick_reg == (half_SBT-1)) 
                    begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            data:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) 
                    begin
                        tick_next = 0;
                        data_next = {rx, data_reg[7:1]}; // concatenating so that rx becomes MSB and drops the oldest LSB
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            stop:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) 
                    begin
                        next_state = idle;
                        data_ready = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            default: next_state=idle;
        endcase                    
    end
    
    // Output Logic
    assign data_out = data_reg;

endmodule
