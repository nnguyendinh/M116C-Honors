`timescale 1 ns / 1 ns 

module complete(en_flag_i, result_1, result_dest_1, result_valid_1, result_ROB_1, result_FU_1, 
									result_2, result_dest_2, result_valid_2, result_ROB_2, result_FU_2,
									result_3, result_dest_3, result_valid_3, result_ROB_3, result_FU_3, en_flag_o, 
									u_rob, rob_p_1, rob_op_1, rob_p_2, rob_op_2, 
									f_flag_1, dest_r_1, f_data_1, f_flag_2, dest_r_2, f_data_2, f_flag_3, dest_r_3, f_data_3,
									o_rob_p_1, o_rob_p_2, rt_flag_1, fp_i_1, rt_flag_2, fp_i_2, pd_i, prev_flag,
									rt_index_1, rt_result_1, rt_index_2, rt_result_2, p_rg, tot_instr_count);

	import p::rob_row;
	import p::rat;
	import p::main_mem;


	rob_row rob [16]; //Re-Order Buffer (ROB) table
	output reg [31:0] p_rg[63:0]; //data to put physical registers in
	
	input reg [31:0] tot_instr_count;
	
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
	
	input u_rob;
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
	
	//retire flags and outputs
	output reg rt_flag_1;
	output reg [4:0] rt_index_1; //index of architectural reg to be overwritten
	output reg [31:0] rt_result_1; //new value that overwrites the architectural reg
	output reg [5:0] fp_i_1; //old phy register of first retired instruction (for update in rename)
	output reg rt_flag_2;
	output reg [4:0] rt_index_2; //index of architectural reg to be overwritten
	output reg [31:0] rt_result_2; //new value that overwrites the architectural reg
	output reg [5:0] fp_i_2; //old phy register of second retired instruction (for update in rename)
	output reg prev_flag;
	
	output reg en_flag_o;
	
	input [5:0] pd_i;

	//reg [5:0] dest_index;
	reg [5:0] prev_pd;
	integer un;
	integer rob_found;
	integer rob_top; //index that represents the first instruction that should be popped
	integer rat_found;
	integer curr_unused; //next unused row in the ROB stack
	reg [31:0] instr_retired; //total number of instructions retired
	//integer prev_flag;

	initial begin
		//set ROB tables as unused
		for(integer n = 0; n < 16; n = n + 1) begin
			rob[n].v = 0;
		end
		
		for(integer n = 0; n < 64; n = n + 1) begin
			p_rg[n] = 0; //all data is initially 0
		end 
		
		for(integer n = 0; n < 256; n = n + 1) begin
			main_mem[n] = 0; //all memory is initially 0
		end 
		
		prev_pd = 0;
		prev_flag = 0; //Same as intial flag state 0
		curr_unused = 0;
		instr_retired = 0;
	end
	
	always@(*) begin

	if(en_flag_i == 1) begin
		
		//Update from dispatch stage to add an instruction to ROB
		//$display("Prev flag: %b", prev_flag);
		//$display("Current flag: %b", u_rob);
		if(prev_flag != u_rob) begin
			prev_flag = u_rob;
			$display("Update enabled");
			
			
			//Actually, shouldn't try to find first unused ROB row but rather
			//just the next in the stack
	
			rob[curr_unused].v = 1'b1;
	
			//let ROB know if writing to register or memory
			if (rob_op_1 == 7'b0100011) begin //if SW 
				rob[curr_unused].instr_type = 1; //store to mem
			end
			else if (rob_op_1 == 7'b0000011) begin	// if LW
				rob[curr_unused].instr_type = 2;
			end
			else begin
				rob[curr_unused].instr_type = 0;
			end
			
			rob[curr_unused].phy_reg = rob_p_1;
			rob[curr_unused].old_phy = o_rob_p_1;

			
			//Update currently unused to next row
			if(curr_unused < 16) begin 
				curr_unused = curr_unused + 1; //move curr_unused up by one
			end
			else begin //go back to top of ROB array (circular)
				curr_unused = 0;
			end
			
			//Same code but for second instruction to ROB
			rob[curr_unused].v = 1'b1;
	
			//let ROB know if writing to register or memory
			if (rob_op_2 == 7'b0100011) begin //if SW 
				rob[curr_unused].instr_type = 1; //store to mem
			end
			else if (rob_op_2 == 7'b0000011) begin	// if LW
				rob[curr_unused].instr_type = 2;
			end
			else begin
				rob[curr_unused].instr_type = 0;
			end
			
			rob[curr_unused].phy_reg = rob_p_2;
			rob[curr_unused].old_phy = o_rob_p_2;
			
			if(curr_unused < 16) begin 
				curr_unused = curr_unused + 1; //move curr_unused up by one
			end
			else begin //go back to top of ROB array (circular)
				curr_unused = 0;
			end
					
		
			//$display("New prev flag: %b", prev_flag);
			
			for(integer n = 0; n < 16; n = n + 1) begin
				$display("Up ROB Line %d: %b, %b, %d, %d, %d, %d, %d", n, rob[n].v, 
						rob[n].instr_type, rob[n].phy_reg, rob[n].result, rob[n].old_phy, rob[n].old_result,
						rob[n].comp);
			end
		end
		
		
		if(prev_pd != pd_i) begin //if it's a new cycle
		
			prev_pd = pd_i;
			//Retire stage//////////////////////////////////////////////////////////////////////
			
			//retire up 1st instruction if possible
			if(rob[rob_top].comp == 1) begin
				$display("Retire enabled");
				//release "old" physical register of the destination register
				rt_flag_1 = 1;
				fp_i_1 = rob[rob_top].old_phy;
				
				//Write to p_rg or memory
				case (rob[rob_top].instr_type)
					0: begin	// Else
						p_rg[rob[rob_top].phy_reg] = rob[rob_top].result;
					end
					1: begin	// SW
						main_mem[rob[rob_top].result] = p_rg[rob[rob_top].phy_reg][31:24];
						main_mem[rob[rob_top].result+1] = p_rg[rob[rob_top].phy_reg][23:16];
						main_mem[rob[rob_top].result+2] = p_rg[rob[rob_top].phy_reg][15:8];
						main_mem[rob[rob_top].result+3] = p_rg[rob[rob_top].phy_reg][7:0];
					end
					2: begin // LW
						p_rg[rob[rob_top].phy_reg] = {main_mem[rob[rob_top].result],main_mem[rob[rob_top].result+1],main_mem[rob[rob_top].result+2],main_mem[rob[rob_top].result+3]};
					end
				endcase

				
				//Clear ROB row
				rob[rob_top] = 0;
				
				//Update rob pointer
				if(rob_top <= 16) begin
					rob_top = rob_top + 1;
				end
				else begin
					rob_top = 0; //go back to beginning of the array
				end
				
				instr_retired = instr_retired + 1;
				
				//Stop program is you've retired all instructions
				if(instr_retired == tot_instr_count) begin
					$stop;
				end
				
				$display("Rob top after 1st retire: %d", rob_top);
			end
			else begin
				rt_flag_1 = 0;
			end
			
			
			//retire a second time if possible (same code as above)
			if(rob[rob_top].comp == 1) begin

				rt_flag_2 = 1;
				fp_i_2 = rob[rob_top].old_phy;	
				
				//Write to p_rg or memory
				case (rob[rob_top].instr_type)
					0: begin	// Else
						p_rg[rob[rob_top].phy_reg] = rob[rob_top].result;
					end
					1: begin	// SW
						main_mem[rob[rob_top].result] = p_rg[rob[rob_top].phy_reg][31:24];
						main_mem[rob[rob_top].result+1] = p_rg[rob[rob_top].phy_reg][23:16];
						main_mem[rob[rob_top].result+2] = p_rg[rob[rob_top].phy_reg][15:8];
						main_mem[rob[rob_top].result+3] = p_rg[rob[rob_top].phy_reg][7:0];
					end
					2: begin // LW
						p_rg[rob[rob_top].phy_reg] = {main_mem[rob[rob_top].result],main_mem[rob[rob_top].result+1],main_mem[rob[rob_top].result+2],main_mem[rob[rob_top].result+3]};
					end
				endcase
				
				rob[rob_top] = 0;
				
				if(rob_top <= 16) begin
					rob_top = rob_top + 1;
				end
				else begin
					rob_top = 0; //go back to beginning of the array
				end
				
				instr_retired = instr_retired + 1;
				
				if(instr_retired == tot_instr_count) begin
					$stop;
				end
				
				$display("Rob top after 2nd retire: %d", rob_top);
			end
			else begin
				rt_flag_2 = 0;
			end
			
		
			
			//actual complete stage stuff///////////////////////////////////////////////////////
			if(result_valid_1 == 1) begin
				
				$display("Complete enabled - FU 1");
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
				
				$display("Complete enabled - FU 2");
				
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
				$display("Complete enabled - FU 3");
				
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
			$display("ROB at the end of complete");
			for(integer n = 0; n < 16; n = n + 1) begin
				$display("ROB Line %d: %b, %b, %d, %d, %d, %d, %d", n, rob[n].v, 
						rob[n].instr_type, rob[n].phy_reg, rob[n].result, rob[n].old_phy, rob[n].old_result,
						rob[n].comp);
			end
		
		end
		
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