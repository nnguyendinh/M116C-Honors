`timescale 1 ns / 1 ns 

module decode(c_i, en_flag_i, instr_1, opcode_1, func3_1, func7_1, rs1_1, rs2_1, rd_1, instr_1_,
					instr_2, opcode_2, func3_2, func7_2, rs1_2, rs2_2, rd_2, instr_2_, en_flag_o, c_o);
	input en_flag_i;
	input [31:0] instr_1;
	output reg [6:0] opcode_1;
	output reg [2:0] func3_1;
	output reg [6:0] func7_1;
	output reg [4:0] rs1_1;
	output reg [4:0] rs2_1;
	output reg [4:0] rd_1;
	output reg [31:0] instr_1_;
	
	input [31:0] instr_2;
	output reg [6:0] opcode_2;
	output reg [2:0] func3_2;
	output reg [6:0] func7_2;
	output reg [4:0] rs1_2;
	output reg [4:0] rs2_2;
	output reg [4:0] rd_2;
	output reg [31:0] instr_2_;
	output reg en_flag_o;
	
	input [31:0] c_i;
	output reg [31:0] c_o;
	
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
	
	always@(*) begin
		$display("Decode enabled: %b", en_flag_i);
	
		if(en_flag_i == 1) begin
			opcode_1 = instr_1[6:0];
			func3_1 = instr_1[14:12];
			func7_1 = instr_1[31:25];
			rs1_1 = instr_1[19:15];
			rs2_1 = instr_1[24:20];
			rd_1 = instr_1[11:7];
			instr_1_ = instr_1[31:0];
		
			opcode_2 = instr_2[6:0];
			func3_2 = instr_2[14:12];
			func7_2 = instr_2[31:25];
			rs1_2 = instr_2[19:15];
			rs2_2 = instr_2[24:20];
			rd_2 = instr_2[11:7];
			instr_2_ = instr_2[31:0];
		end
		else begin
			opcode_1 = 0;
			func3_1 = 0;
			func7_1 = 0;
			rs1_1 = 0;
			rs2_1 = 0;
			rd_1 = 0;
			instr_1_ = 0;
		
			opcode_2 = 0;
			func3_2 = 0;
			func7_2 = 0;
			rs1_2 = 0;
			rs2_2 = 0;
			rd_2 = 0;
			instr_2_ = 0;
		end
		
		en_flag_o = en_flag_i;
		c_o = c_i;
	end
	
	
endmodule
