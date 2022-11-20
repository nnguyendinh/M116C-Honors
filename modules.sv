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
	
	//if opcode == SW, replace rd with imm[4:0]
	//else, rd is [11:7]
	//assign rd = (opcode == 7'b0100011) ? instr[24:20]: instr[11:7];
	//if opcode == SW, replace rs2 with imm[11:5]
	//if opcode == ADDI, ANDI, or LW, replace rs2 with imm[11:0]
	//assign rs2 = (opcode == 7'b0100011) ? instr[31:25]: ((opcode == 7'b0010011 || opcode == 7'b0000011) ? instr[31:20]: instr[24:20]);
	
	//need a flag to indicate whether to use rs2 or imm?
	*/
	
	/*
	always @(*) begin
		opcode = instr[6:0];
		rs1 = instr[19:15];
		instr_ = instr[31:0];
		
		if(opcode == 0100011) begin//SW
			rs2 = instr[31:25]; //rs2 replaced by imm [11:5]
			rd = instr[24:20]; //rd replaced by imm[4:0]
		end else begin//ADDI, ANDI, or LW begin
			rs2 = instr[24:20]; //normal rs2
			rd = instr[11:7];
			
			if (opcode == 0010011 || opcode == 0000011) begin //ADDI, ANDI, or LW
				rs2 = instr[31:20]; //replace rs2 with imm[11:0]
			end
		end 
	end
	*/
	
endmodule

module rename(opcode_1, func3_1, func7_1, rs1_1, rs2_1, rd_1, instr_1, opcode_1_, func3_1_, func7_1_, ps1_1, ps2_1, pd_1, instr_1_,
					opcode_2, func3_2, func7_2, rs1_2, rs2_2, rd_2, instr_2, opcode_2_, func3_2_, func7_2_, ps1_2, ps2_2, pd_2, instr_2_);
	
	input [6:0] opcode_1;
	input [2:0] func3_1;
	input [6:0] func7_1;
	input [4:0] rs1_1;
	input [4:0] rs2_1;
	input [4:0] rd_1;
	input [31:0] instr_1;
	output reg [6:0] opcode_1_;
	output reg [2:0] func3_1_;
	output reg [6:0] func7_1_;
	output reg [5:0] ps1_1;			// Physical registers are 6 bit because we have 128 of them
	output reg [5:0] ps2_1;
	output reg [5:0] pd_1;
	output reg [31:0] instr_1_;
	
	input [6:0] opcode_2;
	input [2:0] func3_2;
	input [6:0] func7_2;
	input [4:0] rs1_2;
	input [4:0] rs2_2;
	input [4:0] rd_2;
	input [31:0] instr_2;
	output reg [6:0] opcode_2_;
	output reg [2:0] func3_2_;
	output reg [6:0] func7_2_;
	output reg [5:0] ps1_2;			// Physical registers are 6 bit because we have 128 of them
	output reg [5:0] ps2_2;
	output reg [5:0] pd_2;
	output reg [31:0] instr_2_;
	
	integer n;
	integer found_free;
	integer free_p;
	
	import p::rat;
	import p::free_pool;
	
	always@(*) begin
	
		found_free = 0;
		free_p = 0;
		
		for (n = 0; n < 64; n = n + 1) begin
			if (free_pool[n] == 0 && found_free == 0) begin
				found_free = 1;
				free_p = n;
			end
		end
		
		//Algorithm: for each source register, access RAT and pick the corresponding P-reg 
		ps1_1 = rat[rs1_1];
		ps2_1 = rat[rs2_1];
		
		//update RAT
		if (rd_1 != 0) begin
			rat[rd_1] = free_p;
			//update value in "free pool" (actually list of all free_pool)
			free_pool[free_p] = 1'b1;
			pd_1 = free_p;
		end
		
		else begin
			pd_1 = 0;
		end
		
		$display("free_p = %d", free_p);

		opcode_1_ = opcode_1;	// The signals we are passing and not changing
		func3_1_ = func3_1;
		func7_1_ = func7_1;
		instr_1_ = instr_1;
	
	/////////////// OK NOW DO IT AGAIN :) /////////////////////////
	
		found_free = 0;
		free_p = 0;
		
		for (n = 0; n < 64; n = n + 1) begin
			if (free_pool[n] == 0 && found_free == 0) begin
				found_free = 1;
				free_p = n;
			end
		end
		
		//Algorithm: for each source register, access RAT and pick the corresponding P-reg 
		ps1_2 = rat[rs1_2];
		ps2_2 = rat[rs2_2];
		
		//update RAT
		if (rd_2 != 0) begin
			rat[rd_2] = free_p;
			//update value in "free pool" (actually list of all free_pool)
			free_pool[free_p] = 1'b1;
			pd_2 = free_p;
		end
		
		else begin
			pd_2 = 0;
		end

		opcode_2_ = opcode_2;	// The signals we are passing and not changing
		func3_2_ = func3_2;
		func7_2_ = func7_2;
		instr_2_ = instr_2;
	
	end
	
endmodule
 
//Dispatch stage
//place instruction in reservation station (RS) --> mark as used, grab which operation, mark which FU
//Re-order buffer (ROB) --> increase ROB index by 1
//grab register values --> grab register values from the pointers into temp registers
//Mark sr regs as ready/not ready --> have "sr1 ready" and "sr2 ready" flags for each instruction
//How to tell if sr regs are ready or not?

//Issue stage
//Excecute only if source registers and FU are all ready --> check the flags
//Execute based on what OP the instruction is --> might have to put extra consideration for lw and sw
//Mark FU being used as not ready


//Complete stage
//copy result to ROB and mark as complete --> Have an array for ROB with the instruction and complete flag
//Mark FU that was being used as ready again
//Mark registers being used as ready


//Retire stage 
//Overwrite reg file with result from execution
//erase instruction from RS?
//retire instruction at top of ROB --> ?
//release "old" regs to architectural reg mapping --> back into RAT and free pool?
