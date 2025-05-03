`timescale 1ns / 1ps
module uart_test(
    input clk_100MHz,       // basys 3 FPGA clock signal
    input reset,            // btnR    
    input rx,               // Rx line
    input btn1,             // read FIFO operation
    input btn2,             // write FIFO operation
    input [7:0] a,          // data given to Tx FIFO
    output tx,              // Tx line
    output [3:0] an,        // 7 segment display digits
    output [6:0] seg,       // 7 segment display segments
    output [7:0] LED        // 8-bit output showing the received byte on LEDs.
    );
    
    // Connection Signals
    wire rx_full, rx_empty, btn_tick1, btn_tick2;  //Status signals from the receive FIFO.
    wire [7:0] rec_data, rec_data1;
    
    // Complete UART Core
    uart_top UART_UNIT
        (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .read_uart(btn_tick1),
            .write_uart(btn_tick2),
            .rx(rx),
            .write_data(rec_data1),
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .read_data(rec_data),
            .tx(tx)
        );
    
    // Button Debouncer for Rx fifo to move the read pointer
    debounce_explicit BUTTON_DEBOUNCER1
        (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .btn(btn1),         
            .db_level(),  
            .db_tick(btn_tick1)
        );
    // Button Debouncer for Tx fifo to move the write pointer 
    debounce_explicit BUTTON_DEBOUNCER2
        (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .btn(btn2),         
            .db_level(),  
            .db_tick(btn_tick2)
        );
    // Signal Logic    
    assign rec_data1 = a;
    
    // Output Logic
    assign LED = rec_data;              // data byte received displayed on LEDs(ascii)
    assign an = 4'b1110;                // using only one 7 segment digit (rightmost digit is only on)
    // 7-Segment Display Logic
assign seg = (rx_full)  ? 7'b0001110 :   // 'F'
             (rx_empty) ? 7'b0000110 :   // 'E'
                          7'b1111111 ;   // OFF if neither
endmodule
