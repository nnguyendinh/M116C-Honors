`timescale 1 ns / 1 ns 

module decode(instr_1, opcode_1, func3_1, func7_1, rs1_1, rs2_1, rd_1, instr_1_,
					instr_2, opcode_2, func3_2, func7_2, rs1_2, rs2_2, rd_2, instr_2_);
					
	input [31:0] instr_1;
	output [6:0] opcode_1;
	output [2:0] func3_1;
	output [6:0] func7_1;
	output [4:0] rs1_1;
	output [4:0] rs2_1;
	output [4:0] rd_1;
	output [31:0] instr_1_;
	
	input [31:0] instr_2;
	output [6:0] opcode_2;
	output [2:0] func3_2;
	output [6:0] func7_2;
	output [4:0] rs1_2;
	output [4:0] rs2_2;
	output [4:0] rd_2;
	output [31:0] instr_2_;
	
	//based on op code, assign each variable
	
	//ADD, SUB, ADDI, XOR, ANDI, SRA, LW, SW
	//ADD: 0000000 rs2 rs1 000 rd 0110011
	//SUB: 0100000 rs2 rs1 000 rd 0110011
	//ADDI: imm[11:0] rs1 000 rd 0010011
	//XOR: 0000000 rs2 rs1 100 rd 0110011
	//ANDI: imm[11:0] rs1 111 rd 0010011
	//SRA: 0100000 rs2 rs1 101 rd 0110011
	//LW: imm[11;0] rs1 010 rd 0000011
	//SW: imm[11:5] rs2 rs1 010 imm[4:0] 0100011
	
	assign opcode_1 = instr_1[6:0];
	assign func3_1 = instr_1[14:12];
	assign func7_1 = instr_1[31:25];
	assign rs1_1 = instr_1[19:15];
	assign rs2_1 = instr_1[24:20];
	assign rd_1 = instr_1[11:7];
	assign instr_1_ = instr_1[31:0];
	
	assign opcode_2 = instr_2[6:0];
	assign func3_2 = instr_2[14:12];
	assign func7_2 = instr_2[31:25];
	assign rs1_2 = instr_2[19:15];
	assign rs2_2 = instr_2[24:20];
	assign rd_2 = instr_2[11:7];
	assign instr_2_ = instr_2[31:0];
	
endmodule
