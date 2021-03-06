`include "defines.vh"
module mycpu_core(
    input wire clk,
    input wire rst,
    input wire [5:0] int,

    output wire inst_sram_en,
    output wire [3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input wire [31:0] inst_sram_rdata,

    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input wire [31:0] data_sram_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire [`IF_TO_ID_WD-1:0] if_to_id_bus;
    wire [`ID_TO_EX_WD-1:0] id_to_ex_bus;
    wire [`EX_TO_ID_WD-1:0] ex_to_id_bus;
    wire [`EX_TO_MEM_WD-1+2:0] ex_to_mem_bus;
    wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus;
    wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus;
    wire [`WB_TO_ID_WD-1:0] wb_to_id_bus;
    wire [`BR_WD-1:0] br_bus; 
    wire [`DATA_SRAM_WD-1:0] ex_dt_sram_bus;
    wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus;
    wire [`StallBus-1:0] stall;
    wire stallreq_id;
    wire inst_load;
    
    wire [31:0] hi_rdata;
    wire [31:0] lo_rdata;
    wire [31:0] hi_data;
    wire [31:0] lo_data;
    wire hilo_e;
    wire [64:0] ex_hilo;
    wire [64:0] mem_to_wb_hilo;
    wire [64:0] wb_to_ex_hilo;
    wire [64:0] mem_to_ex_hilo;
    wire stallreq_ex,start_i;//,ready_o;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [63:0] result_o;
    wire inst_lb;
    wire inst_lbu;
    
    IF u_IF(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .br_bus          (br_bus          ),
        .if_to_id_bus    (if_to_id_bus    ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_wen   (inst_sram_wen   ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
        //.ready_if        (ready_o)   
    );
    

    ID u_ID(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .stallreq        (stallreq_id     ),
        .ex_to_id_bus    (ex_to_id_bus    ),
        .mem_to_id_bus   (mem_to_id_bus   ),
        .wb_to_id_bus    (wb_to_id_bus    ),
        .if_to_id_bus    (if_to_id_bus    ),
        .inst_sram_rdata (inst_sram_rdata ),
        .wb_to_rf_bus    (wb_to_rf_bus    ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .br_bus          (br_bus          ),
        .inst_is_load    (inst_load       ),
        .hi_rdata        (hi_rdata        ),
        .lo_rdata        (lo_rdata        ),
        .hilo_e          (hilo_e          ),
        .hi_data         (hi_data         ),
        .lo_data         (lo_data         ),
        .mem_to_ex_hilo  (mem_to_ex_hilo  ),
        .wb_to_ex_hilo   (wb_to_ex_hilo   )  
    );

    EX u_EX(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .ex_to_mem_bus   (ex_to_mem_bus   ),
        .ex_to_id_bus    (ex_to_id_bus    ),
        .data_sram_en    (data_sram_en    ),
        .data_sram_wen   (data_sram_wen   ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata ),
        .inst_is_load    (inst_load       ),
       // .inst_is_lb      (inst_lb         ), 
      //  .inst_is_lbu     (inst_lbu        ),               
        .ex_hilo         (ex_hilo         ),
        .stallreq_ex     (stallreq_ex     ),
        .start_i         (start_i         ),
        .signed_div_i    (signed_div_i    ),
        .alu_src1        (alu_src1       ),
        .alu_src2        (alu_src2       ),
        .result_o        (result_o        ),
        .ready_o         (ready_o         ),
        .hi_data         (hi_data         ),
        .lo_data         (lo_data         )

    );

    MEM u_MEM(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .ex_to_mem_bus   (ex_to_mem_bus   ),
        .mem_to_id_bus   (mem_to_id_bus   ),
        .data_sram_rdata (data_sram_rdata ),
        .mem_to_wb_bus   (mem_to_wb_bus   ),
        .ex_to_mem_hilo  (ex_hilo         ),
        .mem_to_wb_hilo  (mem_to_wb_hilo  ),
        .mem_to_ex_hilo  (mem_to_ex_hilo  )
      // .inst_is_lb      (inst_lb         ), 
       //.inst_is_lbu     (inst_lbu        )
    );
    
    WB u_WB(
    	.clk               (clk               ),
        .rst               (rst               ),
        .stall             (stall             ),
        .mem_to_wb_bus     (mem_to_wb_bus     ),
        .wb_to_rf_bus      (wb_to_rf_bus      ),
        .wb_to_id_bus      (wb_to_id_bus      ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata ),
        .mem_to_wb_hilo    (mem_to_wb_hilo    ),
        .wb_to_ex_hilo     (wb_to_ex_hilo     ),
        .hi_rdata          (hi_rdata          ),
        .lo_rdata          (lo_rdata          ),
        .hilo_e            (hilo_e            )
    );

    CTRL u_CTRL(
    	.rst   (rst   ),
    	.stallreq_from_id (stallreq_id),
    	.stallreq_from_ex (stallreq_ex),
        .stall (stall )
    );


    
    
endmodule