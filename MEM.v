`include "defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
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
    
    
    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;
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
    
    wire inst_is_lb,inst_is_lbu,inst_is_lh,inst_is_lhu;
    wire [1:0] choose_b;
    wire [1:0] choose_a;
    
    assign {
        choose_b,
        choose_a,
        inst_is_lb,
        inst_is_lbu,
        inst_is_lh,
        inst_is_lhu,
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;
    
    wire [31:0] yituo;
    wire [31:0] ertuo;
    wire [31:0] santuo;
    wire [31:0] situo;
    wire [31:0] lingyituo;
    wire [31:0] lingertuo;
    wire [31:0] lingsantuo;
    wire [31:0] lingsituo;
    wire [31:0] tuo;
    wire [31:0] tuo1;
    wire [31:0] tuo2;
    wire [31:0] tuo3;
    
    assign yituo = {{24{data_sram_rdata [7]}},data_sram_rdata[7:0]};
    assign ertuo = {{24{data_sram_rdata [15]}},data_sram_rdata[15:8]};
    assign santuo = {{24{data_sram_rdata [23]}},data_sram_rdata[23:16]};
    assign situo = {{24{data_sram_rdata [31]}},data_sram_rdata[31:24]};
    assign lingyituo = {24'b0,data_sram_rdata[7:0]};
    assign lingertuo = {24'b0,data_sram_rdata[15:8]};
    assign lingsantuo = {24'b0,data_sram_rdata[23:16]};
    assign lingsituo = {24'b0,data_sram_rdata[31:24]};
    assign tuo = { {16{data_sram_rdata[15]}},data_sram_rdata[15:0]};
    assign tuo1 = { {16{data_sram_rdata[31]}},data_sram_rdata[31:16]};
    assign tuo2 = { 16'b0,data_sram_rdata[15:0]};
    assign tuo3 = { 16'b0,data_sram_rdata[31:16]};    

    assign rf_wdata = sel_rf_res ? mem_result  :
                       inst_is_lb ? (choose_b == 2'b00 ? yituo:
                                     choose_b == 2'b01 ? ertuo:
                                     choose_b == 2'b10 ? santuo:
                                     situo
                                    ):
                       inst_is_lbu ? (choose_b == 2'b00 ? lingyituo:
                                      choose_b == 2'b01 ? lingertuo:
                                      choose_b == 2'b10 ? lingsantuo:
                                      lingsituo
                       ) :
                       inst_is_lh ? (choose_a ==2'b00 ? tuo:
                                       tuo1):
                       inst_is_lhu ? (choose_a ==2'b00 ? tuo2:
                                       tuo3):           
                       (data_ram_en & (data_ram_wen == 4'b0000)) ? data_sram_rdata :
                       ex_result;
    
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
