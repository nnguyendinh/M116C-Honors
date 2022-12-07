`timescale 1 ns / 1 ns 

module complete(en_flag_i, result_1, result_dest_1, result_valid_1, result_ROB_1, result_FU_1, 
									result_2, result_dest_2, result_valid_2, result_ROB_2, result_FU_2,
									result_3, result_dest_3, result_valid_3, result_ROB_3, result_FU_3, en_flag_o);
	
	import p::p_reg_R;
	import p::rob;
	import p::rob_row;
	import p::rs;
	import p::FU_ready;

	input en_flag_i;
	input [31:0] result_1;
	input [31:0] result_2;
	input [31:0] result_3;
	
		
	input [5:0] result_dest_1;
	input [5:0] result_dest_2;
	input [5:0] result_dest_3;

	input result_valid_1;
	input result_valid_2;
	input result_valid_3;
	
	input [3:0] result_ROB_1;
	input [3:0] result_ROB_2;
	input [3:0] result_ROB_3;
	
	input [1:0] result_FU_1;
	input [1:0] result_FU_2;
	input [1:0] result_FU_3;
	
	output reg en_flag_o;

	reg [5:0] dest_index;
	integer n;
	rob_row dum;
	
	
	always@(*) begin

	if(en_flag_i == 1) begin
		
		
		if(result_valid_1 == 1) begin
			
			dest_index = rob[result_ROB_1].phy_reg; //just so you don't have to keep calling the rob
	
			
			
			/*
			//store old result
			dum.old_result = rob[result_ROB_1].result;

			
			
			//store new result from ALU
			dum.result = result_1;
			
			rob[result_ROB_1] = dum;
			*/
			
			
			//mark destination register used as ready
			p_reg_R[dest_index] = 1; // not okay
			
			//mark FU as ready
			//FU_ready[result_FU_1] = 1; //this seems okay
			
		/*	
			//go through reservation station and mark source registers as ready
			for(n = 0; n < 16; n = n + 1) begin
				if (rs[n].src_reg_1 == dest_index) begin
					rs[n].src_data_1 = result_1;
					rs[n].src1_ready = 1;
				end
				
				if (rs[n].src_reg_2 == dest_index) begin
					rs[n].src_data_2 = result_1;
					rs[n].src2_ready = 1;
				end
			end
		
			//mark ROB row as complete
			rob[result_ROB_1].comp = 1;
		*/
		end
		
		/*
		else if(result_valid_2 == 1) begin
			//same commands, except with result_2
			dest_index = rob[result_ROB_2].phy_reg;
			
			rob[result_ROB_2].old_result = rob[result_ROB_2].result;
			rob[result_ROB_2].result = result_2;
			p_reg_R[dest_index] = 1;
			FU_ready[result_FU_2] = 1;
			
			for(n = 0; n < 16; n = n + 1) begin
				if (rs[n].src_reg_1 == dest_index) begin
					rs[n].src_data_1 = result_2;
					rs[n].src1_ready = 1;
				end
				
				if (rs[n].src_reg_2 == dest_index) begin
					rs[n].src_data_2 = result_2;
					rs[n].src2_ready = 1;
				end
			end
		
			rob[result_ROB_2].comp = 1;
		end
		
		else if(result_valid_3 == 1) begin
			//same commands, except with result_3
			dest_index = rob[result_ROB_3].phy_reg;
			
			rob[result_ROB_3].old_result = rob[result_ROB_3].result;
			rob[result_ROB_3].result = result_3;
			p_reg_R[dest_index] = 1;
			FU_ready[result_FU_3] = 1;
			
			for(n = 0; n < 16; n = n + 1) begin
				if (rs[n].src_reg_1 == dest_index) begin
					rs[n].src_data_1 = result_3;
					rs[n].src1_ready = 1;
				end
				
				if (rs[n].src_reg_2 == dest_index) begin
					rs[n].src_data_2 = result_3;
					rs[n].src2_ready = 1;
				end
			end
		
			rob[result_ROB_3].comp = 1;
		
		end
		
		*/
	end

	else begin
		//do nothing

	end

		en_flag_o = en_flag_i;
	end

	
endmodule