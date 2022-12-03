`timescale 1 ns / 1 ns 

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