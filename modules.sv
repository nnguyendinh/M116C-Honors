`timescale 1 ns / 1 ns 

module decode(instr, opcode, rs1, rs2, rd, instr_);
	input [31:0] instr;
	output [6:0] opcode;
	output [4:0] rs1;
	output [4:0] rs2;
	output [4:0] rd;
	output [31:0] instr_;
	
	//based on op code, construct immediate
	

	assign opcode = instr[6:0];
	assign rs1 = instr[19:15];
	assign rs2 = instr[24:20];
	assign rd = instr[11:7];
	assign instr_ = instr[31:0];
	
endmodule

module rename(opcode, rs1, rs2, rd, instr, opcode_, ps1, ps2, pd, instr_, p_regs, rat);
	input [6:0] opcode;
	input [4:0] rs1;
	input [4:0] rs2;
	input [4:0] rd;
	input [31:0] instr;
	output [6:0] opcode_;
	output [5:0] ps1;			// Physical registers are 6 bit because we have 128 of them
	output [5:0] ps2;
	output [5:0] pd;
	output [31:0] instr_;
	int n = 0;
	int found_free = 0;
	
	initial begin 
	
		// Lmao insert rename logic here
		
		//keep track of the free pool
		
		//Algorithm: for each destination register, assign a P-reg from the free pool
		//Find first free P-reg
		
		//$display("control: %p", p_regs[0+:6][0]);
		//p_col = p_regs[0+:6][0];
		//free_p = p_col.find_first_index(x) with (x == 0);
		
		while (n< 64 && found_free == 0)
		begin
			if (p_regs[n][0] == 0)
			begin
				found_free = 1;
				free_p = n;
			end
			n = n + 1;
		end
		//update RAT
		rat[rd] = free_p;
		//update value in "free pool" (actually list of all p_regs)
		p_regs[free_p] [0] = 1;
		
		//Algorithm: for each source register, access RAT and pick the corresponding P-reg 
		
		assign ps1 = rat[rs1];
		assign ps2 = rat[rs2];
		assign pd = free_p;
		assign opcode_ = opcode;	// The signals we are passing and not changing
		assign instr_ = instr;
		
	end
endmodule
	
// module reservationStation(?)
 