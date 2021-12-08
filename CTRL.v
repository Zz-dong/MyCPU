`include "defines.vh"
module CTRL(
    input wire rst,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    // output reg flush,
    // output reg [31:0] new_pc,
    output reg [`StallBus-1:0] stall
);  
    always @ (*) begin
        if (rst) begin
            stall = `StallBus'b0;
        end
        else begin
            stall =(stallreq_from_id==`Stop) ? 6'b000111:
                   (stallreq_from_ex==`Stop) ? 6'b001111:6'b000000;
        end
    end
endmodule