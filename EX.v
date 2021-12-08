`include "defines.vh"
module EX(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    output wire [`EX_TO_MEM_WD-1+2:0] ex_to_mem_bus,
    output wire [`EX_TO_ID_WD-1:0] ex_to_id_bus,
    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire inst_is_load,
   // output wire inst_is_lb,
  //  output wire inst_is_lbu,
    output wire [64:0] ex_hilo,
    output wire stallreq_ex,
    output wire start_i,
    //output wire start_i_if,
    output wire signed_div_i,
    output wire [31:0] alu_src1,
    output wire [31:0] alu_src2,
    input wire [63:0] result_o,
    input wire ready_o,
    input wire [31:0] hi_data,
    input wire [31:0] lo_data

);

    //assign start_i_if = start_i;
    wire signed [63:0] result_mul;
    
   
    wire [31:0] lo_rdata;
    wire [31:0] hi_rdata;
    wire whilo_e;
    wire [31:0] move_result;    
                   
    
    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        // else if (flush) begin
        //     id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        // end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        else if (stall[2]==`NoStop) begin
            id_to_ex_bus_r <= id_to_ex_bus;
        end
    end
    
    wire rf_we2;
    wire [31:0] ex_pc, inst;
    wire [11:0] alu_op;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;
    reg is_in_delayslot;
    

    
    assign {
        ex_pc,          // 148:117
        inst,           // 116:85
        alu_op,         // 84:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,         // 63:32
        rf_rdata2          // 31:0
    } = id_to_ex_bus_r;

    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    assign imm_sign_extend = {{16{inst[15]}},inst[15:0]};
    assign imm_zero_extend = {16'b0, inst[15:0]};
    assign sa_zero_extend = {27'b0,inst[10:6]};

    //wire [31:0] alu_src1, alu_src2;
    wire [31:0] alu_result, ex_result;
    
    assign alu_src1 = sel_alu_src1[1] ? ex_pc :
                      sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend :
                      sel_alu_src2[2] ? 32'd8 :
                      sel_alu_src2[3] ? imm_zero_extend : rf_rdata2;
    
    alu u_alu(
    	.alu_control (alu_op ),
        .alu_src1    (alu_src1    ),
        .alu_src2    (alu_src2    ),
        .alu_result  (alu_result  )
    );

    
    assign signed_div_i=(inst[31:26]==6'b000000 & inst[5:0]==6'b011010 & (inst[15:6]==10'b0)) ? 1'b1 :1'b0;
    assign start_i= (inst_is_div|inst_is_divu) ? 1'b1 :1'b0;
    assign stallreq_ex = (ready_o==1'b0 & start_i==1'b1) ? 1'b1 :1'b0;
    
    assign ex_result = (inst_is_mflo|inst_is_mfhi) ? move_result :alu_result;
    
    wire inst_is_mflo,inst_is_mthi,inst_is_mtlo,inst_is_mfhi,inst_is_div,inst_is_divu,inst_is_mult,inst_is_multu;
    
    assign inst_is_mflo=(inst[31:26]==6'b000000 &inst[5:0]==6'b010010 & inst[10:6]==5'b00000& inst[25:16]==10'b0) ? 1'b1:1'b0;
    assign inst_is_mfhi=(inst[31:26]==6'b000000 &inst[5:0]==6'b010000 & inst[10:6]==5'b00000& inst[25:16]==10'b0) ? 1'b1:1'b0;
    assign inst_is_mthi=(inst[31:26]==6'b000000 &inst[5:0]==6'b010001 & inst[20:6]==15'b0) ? 1'b1:1'b0;
    assign inst_is_mtlo=(inst[31:26]==6'b000000 &inst[5:0]==6'b010011 &  inst[20:6]==15'b0) ? 1'b1:1'b0;
    assign inst_is_div =(inst[31:26]==6'b000000 &inst[5:0]==6'b011010 & inst[15:6]==10'b0);
    assign inst_is_divu =(inst[31:26]==6'b000000 &inst[5:0]==6'b011011 & inst[15:6]==10'b0);
    assign inst_is_mult =(inst[31:26]==6'b000000 &inst[5:0]==6'b011000 & inst[15:6]==10'b0);
    assign inst_is_multu =(inst[31:26]==6'b000000 &inst[5:0]==6'b011001 & inst[15:6]==10'b0);
    
    assign signed_mul=inst_is_mult ? 1'b1 :1'b0;    
    
    wire [31:0] src1_mul;
    wire [31:0] src2_mul;
    assign src1_mul = (inst_is_mult | inst_is_multu) ? alu_src1 :32'b0;
    assign src2_mul = (inst_is_mult | inst_is_multu) ? alu_src2 :32'b0;
    
    mul u_mul(
        .clk(clk),
        . resetn(~rst),
        . mul_signed(signed_mul), //signed is 1, unsigned is 0
        . ina(src1_mul),
        . inb(src2_mul),
        . result(result_mul)
    );

    assign move_result=inst_is_mflo ? lo_data : 
                       inst_is_mfhi ? hi_data :32'b0;
    
    assign {whilo_e ,hi_rdata,lo_rdata}=inst_is_mthi ? {1'b1, rf_rdata1 ,lo_data } :
                                        inst_is_mtlo ? { 1'b1,hi_data ,rf_rdata1 } :
                                        (inst_is_div|inst_is_divu) ? { 1'b1,result_o[63:32] ,result_o[31:0] } :
                                        (inst_is_mult | inst_is_multu) ? {1'b1,result_mul[63:32],result_mul[31:0]} : {1'b1,hi_data,lo_data} ;
                                        
    assign ex_hilo= {whilo_e ,hi_rdata,lo_rdata};   
             
    assign rf_we2 = (inst_is_load|inst_is_lb==1'b1|inst_is_lbu==1'b1) ? 1'b0 : rf_we;
    
    assign ex_to_id_bus = {
        rf_we2,
        rf_waddr,
        ex_result
    };
    
    
    assign ex_to_mem_bus = {
        inst_is_lb,
        inst_is_lbu,
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };
    
    
    assign  data_sram_en = data_ram_en;
    assign  data_sram_wen = data_ram_wen;
    assign  data_sram_addr =  ex_result;
    assign  data_sram_wdata = rf_rdata2  ;
    
    
    assign inst_is_load =( (inst[31:26] == 6'b10_0011)|(inst[31:26] == 6'b10_0000)|(inst[31:26] == 6'b10_0100) )? 1'b1 : 1'b0;
    assign inst_is_lb   = (inst[31:26] == 6'b10_0000) ? 1'b1 : 1'b0;
    assign inst_is_lbu   = (inst[31:26] == 6'b10_0100) ? 1'b1 : 1'b0;    
endmodule
