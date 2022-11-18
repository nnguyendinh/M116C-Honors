`timescale 1 ns / 1 ns 

module decode(instr, opcode, rs1, rs2, rd, instr_);
	input [31:0] instr;
	output [6:0] opcode;
	output [4:0] rs1;
	output [4:0] rs2;
	output [4:0] rd;
	output [31:0] instr_;
	
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
	
	
	assign opcode = instr[6:0];
	assign rs1 = instr[19:15];
	assign instr_ = instr[31:0];
	//if opcode == SW, replace rd with imm[4:0]
	//else, rd is [11:7]
	assign rd = (opcode == 7'b0100011) ? instr[24:20]: instr[11:7];
	//if opcode == SW, replace rs2 with imm[11:5]
	//if opcode == ADDI, ANDI, or LW, replace rs2 with imm[11:0]
	assign rs2 = (opcode == 7'b0100011) ? instr[31:25]: ((opcode == 7'b0010011 || opcode == 7'b0000011) ? instr[31:20]: instr[24:20]);
	
	//need a flag to indicate whether to use rs2 or imm?
	
	//always @(*) begin
	//	opcode = instr[6:0];
	//	rs1 = instr[19:15];
	//	instr_ = instr[31:0];
		
	//	if(opcode == 0100011) begin//SW
	//		rs2 = instr[31:25]; //rs2 replaced by imm [11:5]
	//		rd = instr[24:20]; //rd replaced by imm[4:0]
	//	end else begin//ADDI, ANDI, or LW begin
	//		rs2 = instr[24:20]; //normal rs2
	//		rd = instr[11:7];
			
	//		if (opcode == 0010011 || opcode == 0000011) begin //ADDI, ANDI, or LW
	//			rs2 = instr[31:20]; //replace rs2 with imm[11:0]
	//		end
	//	end 
	//end
	
endmodule

module rename(opcode, rs1, rs2, rd, instr, opcode_, ps1, ps2, pd, instr_);
	input [6:0] opcode;
	input [4:0] rs1;
	input [4:0] rs2;
	input [4:0] rd;
	input [31:0] instr;
	output reg [6:0] opcode_;
	output reg [5:0] ps1;			// Physical registers are 6 bit because we have 128 of them
	output reg [5:0] ps2;
	output reg [5:0] pd;
	output reg [31:0] instr_;
	integer n;
	integer found_free;
	integer free_p;
	
	import p::rat;
	import p::p_regs;
	
	always@(*) begin
	
		found_free = 0;
		free_p = 0;
		
		//free_p = p_col.find_first_index(x) with (x == 0);
		
		for (n = 0; n < 64; n = n + 1)
		begin
			#1 $display("p_reg[n][0]: %b", p_regs[n][0]);
			if (p_regs[n][0] == 0 && found_free == 0)
			begin
				found_free = 1;
				free_p = n;
			end
			//$display("n: %d , p_reg[n]: %d", n, p_regs[n]);
		end
		//update RAT
		rat[rd] = free_p;
		//update value in "free pool" (actually list of all p_regs)
		
		
		
		#1 $display("free_p: %d , p_reg[free_p]: %b", free_p, p_regs[free_p][0]);
		//p_regs[free_p][0] = 1;
		
		
		
		$display("FREE_P: %b", free_p);
		
		//Algorithm: for each source register, access RAT and pick the corresponding P-reg 
	
		ps1 = rat[rs1];
		ps2 = rat[rs2];
		pd = free_p;
		opcode_ = opcode;	// The signals we are passing and not changing
		instr_ = instr;
	
	end
	
endmodule
	
// module reservationStation(?)
 