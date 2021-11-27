`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    input wire [`EX_TO_ID_WD-1:0] ex_to_id_w,
    input wire [`MEM_TO_ID_WD-1:0] mem_to_id_w,
    input wire [`WB_TO_ID_WD-1:0] wb_to_id_w,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    
    wire ex_id_wreg;
    wire [4:0] ex_id_waddr;
    wire [31:0] ex_id_wdata;

    wire mem_id_wreg;
    wire [4:0] mem_id_waddr;
    wire [31:0] mem_id_wdata;

    wire wb_id_wreg;
    wire [4:0] wb_id_waddr;
    wire [31:0] wb_id_wdata;
 
    assign {
        ex_id_wreg,
        ex_id_waddr,
        ex_id_wdata
    } = ex_to_id_w;

    assign {
        mem_id_wreg,
        mem_id_waddr,
        mem_id_wdata
    } = mem_to_id_w;

    assign {
        wb_id_wreg,
        wb_id_waddr,
        wb_id_wdata
    } = wb_to_id_w;
  
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end


    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :
                    ((ex_id_wreg == 1'b1) && (ex_id_waddr == raddr1)) ? ex_id_wdata :
                    ((mem_id_wreg ==1'b1) && (mem_id_waddr == raddr1)) ? mem_id_wdata :
                    ((wb_id_wreg ==1'b1) && (wb_id_waddr == raddr1)) ? wb_id_wdata : reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : 
                    ((ex_id_wreg == 1'b1) && (ex_id_waddr == raddr2)) ? ex_id_wdata :
                    ((mem_id_wreg ==1'b1) && (mem_id_waddr == raddr2)) ? mem_id_wdata :
                    ((wb_id_wreg ==1'b1) && (wb_id_waddr == raddr2)) ? wb_id_wdata : reg_array[raddr2];
endmodule