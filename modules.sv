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
			if (p_regs[n][0] == 0 && found_free == 1)
			begin
				found_free = 1;
				free_p = n;
			end
			//$display("n: %d , p_reg[n]: %d", n, p_regs[n]);
		end
		//update RAT
		rat[rd] = free_p;
		//update value in "free pool" (actually list of all p_regs)
		
		
		
		//p_regs[free_p][0] = 1;
		//p_regs[0] = 1;
		
		
		
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
 