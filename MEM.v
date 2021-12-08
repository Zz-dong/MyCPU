`include "defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    input wire [`EX_TO_MEM_WD-1+2:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    input wire inst_is_lb,
    input wire inst_is_lbu,
    output wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus,
    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    input wire [64:0] ex_to_mem_hilo,
    output wire [64:0] mem_to_wb_hilo,
    output wire [64:0] mem_to_ex_hilo
);
    
    wire [31:0] mem_lo_rdata;
    wire [31:0] mem_hi_rdata;
    wire mem_whilo_e;
    assign {mem_whilo_e , mem_hi_rdata , mem_lo_rdata }=  ex_to_mem_hilo;
    
    
    reg [`EX_TO_MEM_WD-1+2:0] ex_to_mem_bus_r;
    reg [64:0] mem_to_wb_hilo_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            mem_to_wb_hilo_r<= 65'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            mem_to_wb_hilo_r<= 65'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
            mem_to_wb_hilo_r <=ex_to_mem_hilo;
        end
    end
    
    assign mem_to_wb_hilo= mem_to_wb_hilo_r;
    assign mem_to_ex_hilo= mem_to_wb_hilo_r;
    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    
    wire inst_is_lb,inst_is_lbu;
    assign {
        inst_is_lb,
        inst_is_lbu,
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;


    assign rf_wdata = sel_rf_res ? mem_result  :
                      (data_ram_en & (data_ram_wen == 4'b0000)) ? data_sram_rdata :
                      inst_is_lb ?  { {24{ data_sram_rdata [8]}},data_sram_rdata[7:0]} :
                      inst_is_lbu ? {24'b0,data_sram_rdata [7:0]} : ex_result;
    
    assign mem_to_id_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };
    
    assign mem_to_wb_bus = {
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };




endmodule
