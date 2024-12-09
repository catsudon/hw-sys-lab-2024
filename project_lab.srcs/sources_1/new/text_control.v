`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 02:02:55 AM
// Design Name: 
// Module Name: text_control
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


module text_control(
    input clk,                 // Clock signal
    input reset,               // Reset signal
    input we,                  // Write enable signal from UART
//    input moveL,               // Move cursor to the left
//    input moveR,               // Move cursor to the right
    input [7:0] data,          // 8-bit data from UART
    input video_on,            // Video on/off signal
    input [9:0] x, y,          // Current pixel coordinates
    output reg [11:0] rgb      // RGB output
);

    // Parameters and declarations
    parameter MEMSIZE = 128;      // Memory size (128 locations)
    reg [7:0] mem[MEMSIZE - 1:0]; // 8-bit memory array
    reg [6:0] itr;                // Memory index for writing
//    reg [6:0] temp;

    // Signals for ASCII ROM
    wire [10:0] rom_addr;         // 11-bit text ROM address
    wire [7:0] ascii_char;        // 8-bit ASCII character code
    wire [3:0] char_row;          // 4-bit row of ASCII character
    wire [2:0] bit_addr;          // Column number of ROM data
    wire [7:0] rom_data;          // 8-bit row data from text ROM
    wire ascii_bit, plot;         // ASCII ROM bit and plot signal
    wire on_cursor;               // 'x,y is on cursor' signal
    
    integer i ;
    initial begin
        itr = 7'b0;
        for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
            mem[i] = 8'b0 ;
        end
    end

    // ASCII ROM instance
    ascii_rom rom(.clk(clk), .addr(rom_addr), .data(rom_data));
    
    // ASCII ROM address and data interface
    assign rom_addr = {ascii_char, char_row};   // ROM address
    assign ascii_bit = rom_data[~bit_addr];     // Reverse bit order for ASCII character
    assign char_row = y[3:0];                   // Row number of ASCII character
    assign bit_addr = x[2:0];                   // Column number of ASCII character
//    assign ascii_char = mem[((x[7:3] + 8) & 5'b11111) + 32 * ((y[5:4] + 3) & 2'b11)];
    assign ascii_char = mem[x[7:3] + (16  * ((y[6:4] + 5) & 3'b111))];

//    assign plot = ((x >= 192 && x < 448) && (y >= 208 && y < 272)) ? ascii_bit : 1'b0;
    assign plot = ((x >= 256 && x < 384) && (y >= 176 && y < 304)) ? ascii_bit : 1'b0;
    assign on_cursor = (x[7:3] + (16  * ((y[6:4] + 5) & 3'b111)))==itr ? 1 : 0;

    // Memory write logic
    always @(posedge we or posedge reset) begin
        if(reset) begin
            itr = 7'b0;
            for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
                mem[i] = 8'b0 ;
            end
        end
        else if (we) begin
            if (data[7:0] == 13) begin
                itr = (1 + (itr >> 4)) << 4 ;
    //            if (itr == 0)
    //                itr = itr + 1 ;
            end 
            else begin
                mem[itr] = data[7:0];
    //            itr = 1 + (itr%(MEMSIZE-1)) ;
                itr = 1 + itr;
            end
        end
    end
    
//    always @(posedge reset) begin
//        itr = 7'b0;
//        for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
//            mem[i] = 7'b0 ;
//        end
//    end
    
//    always @(posedge moveL or posedge moveR) begin
//        if(moveL & (itr > 0)) begin
//            itr = itr - 1;
//        end
//        else if(moveR & (itr < MEMSIZE-1)) begin
//            itr = itr + 1;
//        end
//    end
    
    // RGB multiplexing logic with gradient
    always @* begin
        if (~video_on)
            rgb = 12'h000; // output black on the outside of the screen
        else if (on_cursor) begin
            rgb = 12'h000; // cursor
        end
        else if (plot) begin
            rgb = 12'h000; // characters
        end
        else if (y[4] == 0) begin
            rgb = 12'habc; // background stripe color
        end
        else
            rgb = 12'hbcd; // background color
    end
endmodule
