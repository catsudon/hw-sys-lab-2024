`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 01:32:47 AM
// Design Name: 
// Module Name: ascii_control
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


module ascii_control(
    input clk,                 // Clock signal
    input reset,               // Reset signal
    input we,                  // Write enable signal from UART
    input moveL,               // Move cursor to the left
    input moveR,               // Move cursor to the right
    input [7:0] data,          // 8-bit data from UART
    input video_on,            // Video on/off signal
    input [9:0] x, y,          // Current pixel coordinates
    output reg [11:0] rgb      // RGB output
);

    // Parameters and declarations
    parameter MEMSIZE = 128;      // Memory size (128 locations)
    reg [6:0] mem[MEMSIZE - 1:0]; // 7-bit memory array
    reg [6:0] itr;                // Memory index for writing
    reg [6:0] temp;

    // Signals for ASCII ROM
    wire [10:0] rom_addr;         // 11-bit text ROM address
    wire [6:0] ascii_char;        // 7-bit ASCII character code
    wire [3:0] char_row;          // 4-bit row of ASCII character
    wire [2:0] bit_addr;          // Column number of ROM data
    wire [7:0] rom_data;          // 8-bit row data from text ROM
    wire ascii_bit, plot;         // ASCII ROM bit and plot signal
    wire on_cursor; // 1 if current coordinate is on the cursor, 0 otherwise
    
    integer i ;
    initial begin
        itr = 7'b0;
        for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
            mem[i] = 7'b0 ;
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
    
    assign on_cursor = (x[7:3] + (16  * ((y[6:4] + 5) & 3'b111))) == itr ? 1 : 0;
    
        // SCREEN UI PAINTER MODULE INSTANCE
//    wire [11:0] painter_rgb; // Output RGB from screen_painter
//    screen_painter ui_painter (
//        .x(x),
//        .y(y),
//        .video_on(video_on),
//        .rgb(painter_rgb)
//    );

    // Memory write logic
    always @(posedge we) begin
        if(reset) begin
            itr = 7'b0;
            for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
                mem[i] = 7'b0 ;
            end
        end
        else if (we) begin
            if (data[6:0] == 13) begin
                itr = (1 + (itr >> 4)) << 4 ;
    //            if (itr == 0)
    //                itr = itr + 1 ;
            end 
            else begin
                mem[itr] = data[6:0];
    //            itr = 1 + (itr%(MEMSIZE-1)) ;
                itr = 1 + itr;
            end
        end
        else if(moveL) begin
            if(itr > 0)
                itr = itr - 1;
        end
        else if(moveR) begin
            if(itr < MEMSIZE - 1)
                itr = itr + 1;
        end
    end
    
//    always @(posedge reset) begin
//        itr = 7'b0;
//        for (i = 0 ; i < MEMSIZE ; i = i + 1) begin
//            mem[i] = 7'b0 ;
//        end
//    end
    
//    always @(posedge moveL) begin
//        if(itr > 0)
//            itr = itr - 1;
//    end
    
//    always @(posedge moveR) begin
//        if(itr < MEMSIZE - 1)
//            itr = itr + 1;
//    end
    
    // RGB multiplexing logic with gradient
    always @* begin
        if (~video_on)
            rgb = 12'h000; // output black on the outside of the screen
        else if (on_cursor) begin
            rgb = 12'h433; // cursor
        end
        else if (plot) begin
            rgb = 12'h433; // characters
        end
//        else if (painter_rgb != 12'h000)
//            rgb = painter_rgb; // screen painter background
        else
            rgb = 12'hDCB; // default background color
    end

endmodule