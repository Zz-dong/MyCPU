`include "defines.vh"
module EX(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
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
    
    
    wire rst1;
    wire[1:0] choose_x;
    assign rst1= (inst_is_mult | inst_is_multu) ? ~rst :rst;
    assign choose_x= (inst_is_mult | inst_is_multu) ? 2'b11 :
                      (inst_is_div|inst_is_divu) ? 2'b01 :
                       2'b00;
    
    
    assign start_i= (inst_is_div|inst_is_divu | inst_is_mult | inst_is_multu) ? 1'b1 :1'b0;
    assign stallreq_ex = (ready_o==1'b0 & start_i==1'b1) ? 1'b1 :1'b0;
    
    assign ex_result = (inst_is_mflo|inst_is_mfhi) ? move_result :alu_result;
    
    wire inst_is_mflo,inst_is_mthi,inst_is_mtlo,inst_is_mfhi,inst_is_div,inst_is_divu,inst_is_mult,inst_is_multu;
    assign signed_div_i=((inst[31:26]==6'b000000 & inst[5:0]==6'b011010 & (inst[15:6]==10'b0))|inst_is_mult) ? 1'b1 :1'b0;
    
    
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
    assign src1_mul = (inst_is_mult | inst_is_multu | inst_is_div |inst_is_divu) ? alu_src1 :32'b0;
    assign src2_mul = (inst_is_mult | inst_is_multu | inst_is_div |inst_is_divu) ? alu_src2 :32'b0;
    
//    mul u_mul(
//        .clk(clk),
//        . resetn(~rst),
//  //signed is 1, unsigned is 0
//        . ina(src1_mul),
//        . inb(src2_mul),

//    );
    
//    div_mul my_div_mul(
//        .rst(rst1),
//        .clk(clk),
//        .md_signed(signed_div_i),     
//        .opdata1(src1_mul ),
//        .opdata2(src2_mul),
//        .start_i(start_i),
//        .annul_i(1'b0),
//        .result(result_o),
//        .ready_i(ready_o),
//        .choose_x(choose_x)
//    );

        div_mul my_div_mul(
        .rst(rst1),
        .clk(clk),
        .dm_signed(signed_div_i),     
        .opdata1_i(src1_mul ),
        .opdata2_i(src2_mul),
        .start_i(start_i),
        .annul_i(1'b0),
        .result_o(result_o),
        .ready_o(ready_o),
        .choose_x(choose_x)
    );
    
    assign move_result=inst_is_mflo ? lo_data : 
                       inst_is_mfhi ? hi_data :32'b0;
    
    assign {whilo_e ,hi_rdata,lo_rdata}=inst_is_mthi ? {1'b1, rf_rdata1 ,lo_data } :
                                        inst_is_mtlo ? { 1'b1,hi_data ,rf_rdata1 } :
                                        (inst_is_div|inst_is_divu) ? { 1'b1,result_o[63:32] ,result_o[31:0] } :
                                        (inst_is_mult | inst_is_multu) ? {1'b1,result_o[63:32],result_o[31:0]} : {1'b1,hi_data,lo_data} ;
                                        
    assign ex_hilo= {whilo_e ,hi_rdata,lo_rdata};   
             
    assign rf_we2 = (inst_is_load|inst_is_lb==1'b1|inst_is_lbu==1'b1) ? 1'b0 : rf_we;
    
    assign ex_to_id_bus = {
        rf_we2,
        rf_waddr,
        ex_result
    };
    
    wire [1:0] choose_b;
    wire [1:0] choose_a;
    wire inst_is_lbu,inst_is_lb,inst_is_lh,inst_is_lhu;
    assign ex_to_mem_bus = {
        choose_b,
        choose_a,
        inst_is_lb,
        inst_is_lbu,
        inst_is_lh,
        inst_is_lhu,
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };
    
    wire inst_is_sb, inst_is_sh;
    
    assign inst_is_sb =  (inst[31:26] == 6'b101000);
    assign inst_is_sh = (inst[31:26] == 6'b101001);
    
    wire [3:0] choose_wen;
    wire [31:0] choose_data;
    
    assign choose_wen = (inst_is_sb & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b00) ? 4'b0001:
                         (inst_is_sb & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b01) ? 4'b0010:
                         (inst_is_sb & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b10) ? 4'b0100:
                         (inst_is_sb & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b11) ? 4'b1000:
                         (inst_is_sh & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b00) ? 4'b0011:
                         (inst_is_sh & data_ram_en & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b10) ? 4'b1100:
                         data_ram_wen;
    
    assign choose_data = (inst_is_sb & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b00) ?{4{rf_rdata2[7:0]}}:
                  (inst_is_sb & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b01) ?{4{rf_rdata2[7:0]}}:
                  (inst_is_sb & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b10) ?{4{rf_rdata2[7:0]}}:
                  (inst_is_sb & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b11) ?{4{rf_rdata2[7:0]}}:
                  (inst_is_sh & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b00) ?{2{rf_rdata2[15:0]}}:
                  (inst_is_sh & data_ram_en==1'b1 & data_ram_wen == 4'b1111 & ex_result[1:0] == 2'b10) ?{2{rf_rdata2[15:0]}}:
                   rf_rdata2;
    assign  data_sram_en = data_ram_en;
    assign  data_sram_wen = choose_wen;
    assign  data_sram_addr = ex_result;
    assign  data_sram_wdata = choose_data  ;
    
    
    
    assign inst_is_load =( (inst[31:26] == 6'b10_0011)|(inst[31:26] == 6'b10_0000)|(inst[31:26] == 6'b10_0100)|(inst[31:26] == 6'b10_0001)|(inst[31:26] == 6'b10_0101))? 1'b1 : 1'b0;
    assign choose_b = ex_result[1:0];
    assign choose_a = ex_result[1:0];
    assign inst_is_lb   = (inst[31:26] == 6'b10_0000) ? 1'b1 : 1'b0;
    assign inst_is_lbu   = (inst[31:26] == 6'b10_0100) ? 1'b1 : 1'b0;    
    assign inst_is_lh   = (inst[31:26] == 6'b10_0001) ? 1'b1 : 1'b0;
    assign inst_is_lhu   = (inst[31:26] == 6'b10_0101) ? 1'b1 : 1'b0;   
    
endmodule
