`timescale 1 ns / 1 ns 

module complete(en_flag_i, result_1, result_dest_1, result_valid_1, result_ROB_1, result_FU_1, 
									result_2, result_dest_2, result_valid_2, result_ROB_2, result_FU_2,
									result_3, result_dest_3, result_valid_3, result_ROB_3, result_FU_3, 
									en_flag_o, rob_p_1, rob_op_1, rob_p_2, rob_op_2, 
									f_flag_1, dest_r_1, f_data_1, f_flag_2, dest_r_2, f_data_2, f_flag_3, dest_r_3, f_data_3,
									o_rob_p_1, o_rob_p_2, rt_flag_1, fp_i_1, rt_flag_2, fp_i_2);
	
	//import p::p_reg_R;
	import p::rob_row;
	import p::p_regs;
	import p::rat;


	rob_row rob [16]; //Re-Order Buffer (ROB) table
	
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
	
	input [5:0] rob_p_1;
	input [5:0] o_rob_p_1;
	input [6:0] rob_op_1;
	input [5:0] rob_p_2;
	input [5:0] o_rob_p_2;
	input [6:0] rob_op_2;
	
	output reg f_flag_1;
	output reg [5:0] dest_r_1;
	output reg [31:0] f_data_1;
	output reg f_flag_2;
	output reg [5:0] dest_r_2;
	output reg [31:0] f_data_2;
	output reg f_flag_3;
	output reg [5:0] dest_r_3;
	output reg [31:0] f_data_3;
	
	
	output reg rt_flag_1;
	output reg [5:0] fp_i_1;
	output reg rt_flag_2;
	output reg [5:0] fp_i_2;
	
	output reg en_flag_o;

	reg [5:0] dest_index;
	//integer n;
	integer un;
	integer rob_found;
	integer rob_top; //index that represents the first instruction that should be popped
	integer rat_found;

	initial begin
		//set ROB tables as unused
		for(integer n = 0; n < 16; n = n + 1) begin
			rob[n].v = 0;
		end
	end
	
	always@(*) begin

	if(en_flag_i == 1) begin
		
		//Update from dispatch stage to add an instruction to ROB
		rob_found = 0;
		for(integer n = 0; n < 16; n = n + 1) begin
			if (rob[n].v != 1 && rob_found == 0) begin
			
				rob[n].v = 1'b1;
		
				//let ROB know if writing to register or memory
				if (rob_op_1 == 7'b0100011) begin //if SW 
					rob[n].instr_type = 1; //store to mem
				end
				else begin
					rob[n].instr_type = 0;
				end
				
				rob[n].phy_reg = rob_p_1;
				rob[n].old_phy = o_rob_p_1;
			
				rob_found = 1;
			end
		end
		
		//Same code but for second instruction to ROB
		rob_found = 0;
		for(integer n = 0; n < 16; n = n + 1) begin
			if (rob[n].v != 1 && rob_found == 0) begin
			
				rob[n].v = 1'b1;
		
				//let ROB know if writing to register or memory
				if (rob_op_2 == 7'b0100011) begin //if SW 
					rob[n].instr_type = 1; //store to mem
				end
				else begin
					rob[n].instr_type = 0;
				end
				
				rob[n].phy_reg = rob_p_2;
				rob[n].old_phy = o_rob_p_2;
			
				rob_found = 1;
			end
		end
		
		
		//Retire stage//////////////////////////////////////////////////////////////////////
		
		
		//retire up 1st instruction if possible
		if(rob[rob_top].comp == 1) begin
			
			//release "old" physical register of the destination register
			rt_flag_1 = 1;
			fp_i_1 = rob[rob_top].old_phy;
			
			//Search RAT for the architectural register?
			rat_found = 0;
			for(integer n = 0; n < 32; n = n + 1) begin
				if(rat[n] == rob[rob_top].phy_reg && rat_found == 0) begin
					//Write to the register
					//p_regs[n] = rob[rob_top].result;
					
					rat_found = 1;
				end
			end		
			
			//Clear ROB row
			rob[rob_top].v = 0;
			
			//Update rob pointer
			if(rob_top <= 16) begin
				rob_top = rob_top + 1;
			end
			else begin
				rob_top = 0; //go back to beginning of the array
			end
		end
		else begin
			rt_flag_1 = 0;
		end
		
		//retire a second time if possible (same code as above)
		if(rob[rob_top].comp == 1) begin

			rt_flag_2 = 1;
			fp_i_2 = rob[rob_top].old_phy;
			
			rat_found = 0;
			for(integer n = 0; n < 32; n = n + 1) begin
				if(rat[n] == rob[rob_top].phy_reg && rat_found == 0) begin
					//Write to the register
					//p_regs[n] = rob[rob_top].result;
					
					rat_found = 1;
				end
			end		
			
			rob[rob_top].v = 0;
			
			if(rob_top <= 16) begin
				rob_top = rob_top + 1;
			end
			else begin
				rob_top = 0; //go back to beginning of the array
			end
		end
		else begin
			rt_flag_2 = 0;
		end
		
	
		
		//actual complete stage stuff///////////////////////////////////////////////////////
		if(result_valid_1 == 1) begin
			
			//search for the rob row corresponding to the destination register
			rob_found = 0;
			
			for(integer n = 0; n < 16; n = n + 1) begin
				if (rob[n].phy_reg == result_dest_1 && rob_found == 0) begin
					
					//store old result
					rob[n].old_result = rob[n].result;

					//store new result from ALU
					rob[n].result = result_1;
					
					
					//Let dispatch mark destination register as ready
					dest_r_1 = rob[n].phy_reg;
					
					rob[n].comp = 1;
					
					rob_found = 1;
				end
			end
			
			//Forward data
			f_flag_1 = 1;
			f_data_1 = result_1;
			
		end
		
		else begin
			f_flag_1 = 0; //don't forward anything 
		
		end
		
		if(result_valid_2 == 1) begin
			//Same process but for outputs from FU 2
			rob_found = 0;
			
			for(integer n = 0; n < 16; n = n + 1) begin
				if (rob[n].phy_reg == result_dest_2 && rob_found == 0) begin
					
					rob[n].old_result = rob[n].result;
					rob[n].result = result_2;
					dest_r_2 = rob[n].phy_reg;
					rob[n].comp = 1;	
					rob_found = 1;
					
				end
			end
			
			f_flag_2 = 1;
			f_data_2 = result_2;
			
		end
		
		else begin
			f_flag_2 = 0; //don't forward anything 
		
		end
		
		if(result_valid_3 == 1) begin
			//Same process but for outputs from FU 3
			rob_found = 0;
			
			for(integer n = 0; n < 16; n = n + 1) begin
				if (rob[n].phy_reg == result_dest_3 && rob_found == 0) begin
					
					rob[n].old_result = rob[n].result;
					rob[n].result = result_3;
					dest_r_3 = rob[n].phy_reg;
					rob[n].comp = 1;	
					rob_found = 1;
					
				end
			end
			
			f_flag_3 = 1;
			f_data_3 = result_3;
		
		end
		
		else begin
			f_flag_3 = 0; //don't forward anything 
		
		end
		
		//display entire ROB
		/*
		for(integer n = 0; n < 16; n = n + 1) begin
			$display("ROB Line %d: %b, %b, %d, %d, %d, %d, %d", n, rob[n].v, 
					rob[n].instr_type, rob[n].phy_reg, rob[n].result, rob[n].old_phy, rob[n].old_result,
					rob[n].comp);
		end
		*/
	end
	
	else if (en_flag_i == 0) begin
	
		$stop;
		
	end
	

	else begin
		
		//top of ROB starts out at index 0
		rob_top = 0;
		
		f_flag_1 = 0;
		f_flag_2 = 0;
		f_flag_3 = 0;
		rt_flag_1 = 0;
		rt_flag_2 = 0;
		
	end

		en_flag_o = en_flag_i;
	end

	
endmodule