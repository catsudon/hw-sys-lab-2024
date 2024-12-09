`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 01:39:38 AM
// Design Name: 
// Module Name: system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module system(
    input clk,          // 100MHz on Basys 3
    input btnU,         // btnU on Basys 3 reset screen
    input btnC,         // btnC on Basys 3 and send data from switch to another
    output wire RsTx,   // micro USB UART transmit
    input wire RsRx,    // micro USB UART receive
    input [7:0] sw,     // switch
    input ja1,          // Receive from another board
    output ja2,         // Transmit to another board
    output hsync,       // to VGA connector
    output vsync,       // to VGA connector
    output [11:0] rgb,  // to DAC, to VGA connector
    output [6:0] seg,   // 7-Segment Display
    output dp,
    output [3:0] an     // 7-Segment an control
    );
    
    // signals
    wire [7:0] data_in;     // Data received through uart
    wire received1;         // Indicate uart receive completion
    wire [9:0] w_x, w_y;
    wire w_video_on, w_p_tick;
//    wire sent1, sent2 ;
//    wire received2; // FROM Keyboard and FROM another board
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    wire [3:0] char_row;    // 4-bit row of ASCII character
    wire [2:0] bit_addr;    // column number of ROM data
//    wire gnd; // Ground
//    wire [7:0] gnd_b; // GROUND_BUS
    
    
    // VGA ASSIGN VARIABLE
    assign char_row = w_y[3:0];// row number of ascii character rom
    assign bit_addr = w_x[2:0];// column number of ascii character rom
    
    // VGA Controller
    vga_controller vga(.clk_100MHz(clk), .reset(btnU), .hsync(hsync), .vsync(vsync), .video_on(w_video_on), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    // Text Generation Circuit
    text_control tc(.clk(clk), .video_on(w_video_on), .x(w_x), .y(w_y), .rgb(rgb_next), .data(data_in), .we(received1), .reset(btnU));
    
    // Uart transmit to/receive from another board
    uart uart1(.tx(ja2), .data_transmit(sw[7:0]),
               .rx(ja1), .data_received(data_in), .received(received1),
               .dte(btnC), .clk(clk));
                
    // UART1 Receive from another and transmit to monitor
//    uart uart1(.tx(RsTx), .data_transmit(gnd_b),
//               .rx(ja1), .data_received(data_in), .received(received1),
//               .dte(1'b0), .clk(clk));
                
    // UART2 Receive from keyboard or switch and transmit to another
//    uart uart2(.rx(RsRx), .data_transmit(sw[7:0]), 
//               .tx(ja2), .data_received(gnd_b), .received(received2),
//               .dte(btnC), .clk(clk));
   
    // rgb buffer
    always @(posedge clk)begin
        if(w_p_tick)
            rgb_reg <= rgb_next;
    end
    // output
    assign rgb = rgb_reg;
      
endmodule
