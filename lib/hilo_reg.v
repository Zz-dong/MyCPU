`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 22:45:47
// Design Name: 
// Module Name: hilo_reg
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


module hilo_reg(
    input wire clk, 
    input wire rst,
    input wire we,
    input wire [`RegBus-1:0] hi_rdata,
    input wire [`RegBus-1:0] lo_rdata,
    output reg [`RegBus-1:0] hi_data1,
    output reg [`RegBus-1:0] lo_data1
    );
    always @(posedge clk) begin
        if (rst) begin
            hi_data1<=32'b0;
            lo_data1<=32'b0;
        end
        else if (we ==1'b1)begin
            hi_data1 <= hi_rdata;
            lo_data1 <= lo_rdata;
        end
     end     
endmodule
