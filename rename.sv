`timescale 1 ns / 1 ns 

module rename(en_flag_i, opcode_1, func3_1, func7_1, rs1_1, rs2_1, rd_1, instr_1, opcode_1_, func3_1_, func7_1_, ps1_1, ps2_1, pd_1, instr_1_,
					opcode_2, func3_2, func7_2, rs1_2, rs2_2, rd_2, instr_2, opcode_2_, func3_2_, func7_2_, ps1_2, ps2_2, pd_2, instr_2_, en_flag_o, 
					old_pd_1, old_pd_2, rt_flag_1, fp_i_1, rt_flag_2, fp_i_2);
	
	import p::rat;
	
	reg free_pool[63:0]; //free pool, each index represents the physical register with the corresponding number
	//0 = not attached to an arch reg, 1 = attached to an arch reg
	
	input en_flag_i;
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
	
	output reg [5:0] old_pd_1;
	output reg [5:0] old_pd_2;
	
	input rt_flag_1;
	input [5:0] fp_i_1;
	input rt_flag_2;
	input [5:0] fp_i_2;
	
	output reg en_flag_o;
	
	integer n;
	integer found_free;
	integer free_p;
	
	initial begin
	
			for(n = 0; n < 32; n = n + 1) begin
				free_pool[n] = 1;
			end 

			for(n = 32; n < 64; n = n + 1) begin
				free_pool[n] = 0;
			end
	
	end
	
	
	always@(*) begin
	
		$display("Rename enabled: %b", en_flag_i);
		
		if(en_flag_i == 1) begin
			
			//Updates from Retire stage
			if(rt_flag_1 == 1 || rt_flag_2 == 1) begin
			
				if(rt_flag_1 == 1) begin
					free_pool[fp_i_1] = 1;
				end
				
				if(rt_flag_2 == 1) begin
					free_pool[fp_i_2] = 1;
				end
			
			end 
			
			else begin
				//Rename stuff////////////////////////////////////////////////////
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
				if (rd_1 != 0 && opcode_1 != 7'b0100011) begin // Ignore x0 and SW instructions
					old_pd_1 = rat[rd_1];
					rat[rd_1] = free_p;
					//update value in "free pool" (actually list of all free_pool)
					free_pool[free_p] = 1'b1;
					pd_1 = free_p;
				end
				
				else begin
					pd_1 = 0;
				end
				
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
				if (rd_2 != 0 && opcode_2 != 7'b0100011) begin	// Ignore x0 and SW instructions
					old_pd_2 = rat[rd_2];
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

				
				/*
				for(n = 0; n < 64; n = n + 1) begin
					$display("free_pool[%d]: %b", n, free_pool[n]); 
				end
				*/	
			end
		end
		
		else begin
			opcode_1_ = 0;
			func3_1_ = 0;
			func7_1_ = 0;
			ps1_1 = 0;		
			ps2_1 = 0;
			pd_1 = 0;
			instr_1_ = 0;
			
			opcode_2_ = 0;
			func3_2_ = 0;
			func7_2_ = 0;
			ps1_2 = 0;		
			ps2_2 = 0;
			pd_2 = 0;
			instr_2_ = 0;
		end
		
		//$display("rename pd_1 = %d", pd_1);
		//$display("rename pd_2 = %d", pd_2);
		en_flag_o = en_flag_i;
		
	end
	
endmodule