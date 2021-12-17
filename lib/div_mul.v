`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/25 13:51:28
// Design Name: 
// Module Name: div
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
module div_mul(
	input wire rst,							//��λ
	input wire clk,							//ʱ��
	input wire dm_signed ,						//�Ƿ�Ϊ�з��ų������㣬1λ�з���
	input wire[31:0] opdata1_i,				//������
	input wire[31:0] opdata2_i,				//����
	input wire start_i,						//�Ƿ�ʼ��������
	input wire annul_i,						//�Ƿ�ȡ���������㣬1λȡ��
	output reg[63:0] result_o,				//����������
	output reg ready_o,						//���������Ƿ����
	input wire[1:0]  choose_x
);
	
	wire [32:0] div_temp;
	reg [5:0] cnt;							//��¼���̷������˼���
	reg[64:0] dividend;						//��32λ����������м�������k�ε���������ʱ��dividend[k:0]����ľ��ǵ�ǰ�õ����м�����
											//dividend[31:k+1]������Ǳ�����û�в�������Ĳ��֣�dividend[63:32]��ÿ�ε���ʱ�ı�����
	reg [1:0] state;						//���������ڵ�״̬	
	reg[31:0] divisor;
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
	reg[63:0] mul_temp_op1;
	reg[31:0] mul_temp_op2;
	reg[63:0] mul_temp_result;

	assign div_temp = {1'b0, dividend[63: 32]} - {1'b0, divisor};
	
	
	always @ (posedge clk) begin
		if (rst && choose_x == 2'b00 ) begin
			state <= `DivFree;
			result_o <= {`ZeroWord,`ZeroWord};
			ready_o <= `DivResultNotReady;

		end else begin
			case(state)
				`DivFree: begin			//����������	

					if (start_i == `DivStart && annul_i == 1'b0) begin
						if(opdata2_i == `ZeroWord && choose_x == 2'b01) begin			//�������Ϊ0
							state <= `DivByZero;
						end else begin
							state <= `DivOn;					//������Ϊ0
							cnt <= 6'b000000;
							if(dm_signed == 1'b1 && opdata1_i[31] == 1'b1) begin			//������Ϊ����
								temp_op1 = ~opdata1_i + 1;
								mul_temp_op1 = {32'b0,~opdata1_i + 1};
							end else begin
								temp_op1 = opdata1_i;
								mul_temp_op1 = opdata1_i;
							end
							if (dm_signed == 1'b1 && opdata2_i[31] == 1'b1 ) begin			//����Ϊ����
								temp_op2 = ~opdata2_i + 1;
								mul_temp_op2 = temp_op2;
							end else begin
								temp_op2 = opdata2_i;
								mul_temp_op2 = temp_op2;
							end
							
							mul_temp_result <= 64'b0;
							
							dividend <= {`ZeroWord, `ZeroWord};
							dividend[32: 1] <= temp_op1;
							divisor <= temp_op2;
						end
					end else begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
				`DivByZero: begin			//����Ϊ0
					dividend <= {`ZeroWord, `ZeroWord};
					state <= `DivEnd;
				end
				
				`DivOn: begin				//������Ϊ0
					if(annul_i == 1'b0) begin			//���г�������
						if(cnt != 6'b100000) begin
						    if(choose_x == 2'b11)begin
						        mul_temp_result <= (mul_temp_op2[0] == 1'b1) ? (mul_temp_result + mul_temp_op1) :mul_temp_result;
						        mul_temp_op1 <= {mul_temp_op1[62:0],1'b0};
						        mul_temp_op2 <= {1'b0,mul_temp_op2[31:1]};
						    end else begin
                                if (div_temp[32] == 1'b1) begin
                                    dividend <= {dividend[63:0],1'b0};
                                end else begin
                                    dividend <= {div_temp[31:0],dividend[31:0], 1'b1};
                                end
						    end	
							cnt <= cnt +1;		//�����������
						
	//((   (opdata1_i[31] == 1'b1&&opdata2_i[31] == 1'b1)   ||    (opdata1_i[31] == 1'b0&&opdata2_i[31] == 1'b0)   &&   signed_div_i == 1'b1   )||signed_div_i == 1'b0)
						
						end	else begin
						    if(choose_x == 2'b11)begin
						        if ((dm_signed == 1'b1) && ((opdata1_i[31] == 1'b1 && opdata2_i[31] == 1'b0) || (opdata1_i[31] == 1'b0 &&opdata2_i[31] == 1'b1))) begin
                                    mul_temp_result <= (~mul_temp_result + 1);
                                end
						    end else begin
                                if ((dm_signed == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
                                    dividend[31:0] <= (~dividend[31:0] + 1);
                                end
                                if ((dm_signed == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
                                    dividend[64:33] <= (~dividend[64:33] + 1);
                                end
						    end	
							if ((dm_signed == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
								dividend[31:0] <= (~dividend[31:0] + 1);
							end
							if ((dm_signed == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin
								dividend[64:33] <= (~dividend[64:33] + 1);
							end
							state <= `DivEnd;
							cnt <= 6'b000000;
						end
					end else begin	
						state <= `DivFree;
					end
				end
				
				`DivEnd: begin			//��������
				    if(choose_x ==2'b11)begin
				        result_o <= mul_temp_result;
				    end else begin
				        result_o <= {dividend[64:33], dividend[31:0]};
				    end
					
					ready_o <= `DivResultReady;
					if (start_i == `DivStop) begin
						state <= `DivFree;
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
			endcase
		end
	end
	






      



endmodule