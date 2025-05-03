`timescale 1ns / 1ps
module debounce_explicit(
    input clk_100MHz,
    input reset,
    input btn,              // button input
    output reg db_level,    // for switches (debounce output)
    output reg db_tick      // for buttons (edge detection)
    );
    
    // state declarations
    parameter [1:0] zero  = 2'b00,
                    wait1 = 2'b01,
                    one   = 2'b10;
    
    // Basys3 has a 100MHz clk with a period of 10ns
    parameter N = 22;      // number of counter bits (as 2^N * 10ns = ~40ms) we took 40ms as delay
    
    // signal declaration
    reg [1:0] state_reg, next_state;
    reg [N-1:0] q_reg;    // counter register
    wire [N-1:0] q_next;  // next value for counter
    wire q_zero;
    reg q_load, q_dec;
    
    // register logic
    always @(posedge clk_100MHz or posedge reset) 
        if(reset) 
        begin
            state_reg <= zero;
            q_reg <= 0;
        end
        else 
        begin
            state_reg <= next_state;
            q_reg <= q_next;
        end
        
    // counter`s next state logic
    assign q_next = (q_load) ? {N{1'b1}} :      // load all 1s
                    (q_dec) ? q_reg - 1  :      // decrement
                     q_reg;                     // no change in q
    
    assign q_zero = (q_next == 0);
    
    // the debounce is designed for delayed detection
    // next state logic
    always @* 
    begin
        next_state = state_reg;
        q_load = 1'b0;
        q_dec = 1'b0;
        db_tick = 1'b0;
        
        case(state_reg)
            zero    : 
            begin
                        db_level = 1'b0;
                        if(btn) 
                        begin
                            next_state = wait1;
                            q_load = 1'b1;
                        end
            end
            
            wait1   : 
            begin
                        db_level = 1'b0;
                        if(btn) 
                        begin
                            q_dec = 1'b1;
                            if(q_zero) 
                            begin
                                next_state = one;
                                db_tick = 1'b1;
                                q_load = 1'b1;
                            end
                        end
                        else
                            next_state = zero;
            end
            
            one     : 
            begin
                        db_level = 1'b1;
                        if(~btn) 
                        begin
                            q_dec = 1'b1;
                            if(q_zero)
                                next_state = zero;
                        end
                        else
                            next_state = one;
            end
            
            default : next_state = zero;
        endcase
    end
        
endmodule
