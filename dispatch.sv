`timescale 1 ns / 1 ns 

module dispatch(en_flag_i, opcode_1, func3_1, func7_1, ps1_1, ps2_1, pd_1, instr_1, rs_line_1, 
						opcode_2, func3_2, func7_2, ps1_2, ps2_2, pd_2, instr_2, rs_line_2, en_flag_o,
						result_1, result_dest_1, result_valid_1, result_ROB_1, result_FU_1,
						result_2, result_dest_2, result_valid_2, result_ROB_2, result_FU_2,
						result_3, result_dest_3, result_valid_3, result_ROB_3, result_FU_3, 
						u_rob, rob_p_1, rob_op_1, rob_p_2, rob_op_2,
						f_flag_1, dest_r_1, f_data_1, f_flag_2, dest_r_2, f_data_2, f_flag_3, dest_r_3, f_data_3,
						o_pd_1, o_pd_2, o_rob_p_1, o_rob_p_2, pd_1_, p_rg, clock);
						
	//import p::p_reg_R;
	import p::rs_row;
	import p::rob_row;
	//import p::p_regs;
	
	rs_row rs [16]; //reservation station
	reg p_reg_R[63:0]; //Table for determining if physical register is ready or not
	
	input[31:0] p_rg[63:0]; //p_reg table directly wired from main
	input en_flag_i;
	input [6:0] opcode_1;
	input [2:0] func3_1;
	input [6:0] func7_1;
	input [5:0] ps1_1;
	input [5:0] ps2_1;
	input [5:0] pd_1;
	input [31:0] instr_1;
	output integer rs_line_1;

	input [6:0] opcode_2;
	input [2:0] func3_2;
	input [6:0] func7_2;
	input [5:0] ps1_2;
	input [5:0] ps2_2;
	input [5:0] pd_2;
	input [31:0] instr_2;
	output integer rs_line_2;
	output reg en_flag_o;
	
	reg [6:0] ALU_opcode_1;
	reg [6:0] ALU_opcode_2;
	reg [6:0] ALU_opcode_3;
	
	reg [2:0] ALU_func3_1;
	reg [2:0] ALU_func3_2;
	reg [2:0] ALU_func3_3;
	
	reg [6:0] ALU_func7_1;
	reg [6:0] ALU_func7_2;
	reg [6:0] ALU_func7_3;
	
	reg [31:0] ALU_source_1_1;
	reg [31:0] ALU_source_2_1;
	reg [31:0] ALU_source_1_2;
	reg [31:0] ALU_source_2_2;
	reg [31:0] ALU_source_1_3;
	reg [31:0] ALU_source_2_3;
	
	output reg [31:0] result_1;
	output reg [31:0] result_2;
	output reg [31:0] result_3;
	
	
	output reg [5:0] result_dest_1;
	output reg [5:0] result_dest_2;
	output reg [5:0] result_dest_3;
	
	output reg result_valid_1;
	output reg result_valid_2;
	output reg result_valid_3;
	
	output reg [3:0] result_ROB_1; //ROB index of the instruction being fired
	output reg [3:0] result_ROB_2;
	output reg [3:0] result_ROB_3;
	
	output reg [1:0] result_FU_1; //FU index of instruction being fired
	output reg [1:0] result_FU_2;
	output reg [1:0] result_FU_3;
	
	input [5:0] o_pd_1; //old phy info added to the ROB 
	input [5:0] o_pd_2;
	output reg [5:0] pd_1_;
	
	//Outside of the pipeline
	
	//Outputs to ROB
	output reg u_rob;
	output reg [5:0] rob_p_1;
	output reg [6:0] rob_op_1;
	output reg [5:0] rob_p_2;
	output reg [6:0] rob_op_2;
	output reg [5:0] o_rob_p_1;
	output reg [5:0] o_rob_p_2;
	
	//Updates to source register from complete stage
	input f_flag_1;
	input [5:0] dest_r_1;
	input [31:0] f_data_1;
	input f_flag_2;
	input [5:0] dest_r_2;
	input [31:0] f_data_2;
	input f_flag_3;
	input [5:0] dest_r_3;
	input [31:0] f_data_3;
	
		
	reg [4:0] un; //index of first unused
	reg [4:0] un_2; //index of second unused
	integer rob_un;
	integer rob_un_2;
	reg switch = 0;
	reg rob_switch = 0;
	integer num;
	reg rob_found = 0;
	reg [1:0] rs_found = 0;
	reg rob_found_2 = 0;
	reg rs_found_2 = 0;
	reg instr_found_1 = 0;
	reg instr_found_2 = 0;
	reg instr_found_3 = 0;
	rob_row dum;
	rob_row dum2;
	reg [5:0] prev_pd_1;
	
	reg RS_filled = 0;
	input clock;

	ALU fu_1(ALU_opcode_1, ALU_func3_1, ALU_func7_1, ALU_source_1_1, ALU_source_2_1, result_dest_1, result_1);
	ALU fu_2(ALU_opcode_2, ALU_func3_2, ALU_func7_2, ALU_source_1_2, ALU_source_2_2, result_dest_2, result_2);
	ALU fu_3(ALU_opcode_3, ALU_func3_3, ALU_func7_3, ALU_source_1_3, ALU_source_2_3, result_dest_3, result_3);
	
	initial begin
	
		//before enable flag is sent thru, initialize reservation station
		for(integer n = 0; n < 16; n = n + 1) begin
			rs[n].in_use = 0;
		end 
		
		for(integer n = 0; n < 64; n = n + 1) begin
			p_reg_R[n] = 1; //all physical registers are intially ready
		end 
		
		prev_pd_1 = 0; //set to any value not equal to initial pd_1
		u_rob = 0;
	end
	
	always@(*) begin
		//place instruction in reservation station (RS) --> mark as used, grab which operation, mark which FU
		//find first unused reservation station --> loop to find first unused every time?
		
		//$display("Dispatch enabled: %b", en_flag_i);
		//$display("Prev pd 1:, %d", prev_pd_1);
		
		if(en_flag_i == 1/* || RS_filled == 1*/) begin
			//$display("initial pd_1: %d", pd_1);
			//$display("initial pd_2: %d", pd_2);
			
			//Update p_reg_R from complete stage
			if(f_flag_1 == 1) begin
				p_reg_R[dest_r_1] = 1;
				
				$display("Updating any src reg 1: %d", dest_r_1);
				
				//Update source registers from data forwarded from complete stage
				for(integer n = 0; n < 16; n = n + 1) begin
					if (rs[n].src_reg_1 == dest_r_1 && rs[n].src1_ready != 1) begin
						rs[n].src_data_1 = f_data_1;
						rs[n].src1_ready = 1;
					end
					
					if (rs[n].src_reg_2 == dest_r_1 && rs[n].src2_ready != 1) begin
						rs[n].src_data_2 = f_data_1;
						rs[n].src2_ready = 1;
					end
					
					if (rs[n].sw_reg == dest_r_1) begin
						rs[n].sw_ready = 1;
					end
				end
				
			end
		
			if(f_flag_2 == 1) begin
				p_reg_R[dest_r_2] = 1;
				
				$display("Updating any src reg 2: %d", dest_r_2);
				
				for(integer n = 0; n < 16; n = n + 1) begin
					if (rs[n].src_reg_1 == dest_r_2 && rs[n].src1_ready != 1) begin
						rs[n].src_data_1 = f_data_2;
						rs[n].src1_ready = 1;
					end
					
					if (rs[n].src_reg_2 == dest_r_2 && rs[n].src2_ready != 1) begin
						rs[n].src_data_2 = f_data_2;
						rs[n].src2_ready = 1;
					end
					
					if (rs[n].sw_reg == dest_r_2) begin
						rs[n].sw_ready = 1;
					end
				end
			end 
			
			if(f_flag_3 == 1) begin
				p_reg_R[dest_r_3] = 1;
				
				$display("Updating any src reg 3: %d", dest_r_3);
				
				for(integer n = 0; n < 16; n = n + 1) begin
					if (rs[n].src_reg_1 == dest_r_3 && rs[n].src1_ready != 1) begin
						rs[n].src_data_1 = f_data_3;
						rs[n].src1_ready = 1;
					end
					
					if (rs[n].src_reg_2 == dest_r_3 && rs[n].src2_ready != 1) begin
						rs[n].src_data_2 = f_data_3;
						rs[n].src2_ready = 1;
					end
					
					if (rs[n].sw_reg == dest_r_3) begin
						rs[n].sw_ready = 1;
					end
				end
			end 
			
			
			//$display("Dispatch pd_1: %d", pd_1);
			//$display("Dispatch prev_pd: %d", prev_pd_1);

			if(prev_pd_1 != pd_1) begin //make sure it's a different cycle
			
				//Actual Dispatch/fire stuff////////////////////////////////////////
				$display("Dispatch stage enabled");
				prev_pd_1 = pd_1;
				rs_found = 0;
				
				// Find first two unused rows in the RS
				for(num = 0; num < 16; num = num + 1) begin
					
					if (rs[num].in_use == 0 && rs_found == 0) begin
						un = num;
						//$display("found un: %d, rs_f: %b", num, rs_found);
						rs_found = 1;
					end
					else if (rs[num].in_use == 0 && rs_found == 1) begin
						un_2 = num;
						//$display("found un_2: %d, rs_f: %b", num, rs_found);
						rs_found = 2;
					end
					
				end
					
				//$display("1st RS line found: %d",un);
				//$display("2nd RS line found: %d",un_2);
				
				// Issue/Fire Stage////////////////////////////////////////////////
				
				result_valid_1 = 0;
				result_valid_2 = 0;
				result_valid_3 = 0;
				
				// Fire first instruction
				instr_found_1 = 0;
				for(num = 0; num < 16; num = num + 1) begin
				
					if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
							&& rs[num].sw_ready == 1 && instr_found_1 == 0) begin
						
						ALU_opcode_1 = rs[num].op;
						ALU_func3_1 = rs[num].func3;
						ALU_func7_1 = rs[num].func7;
						ALU_source_1_1 = rs[num].src_data_1;
						ALU_source_2_1 = rs[num].src_data_2;

						if (rs[num].op == 7'b0100011) begin	// If SW, we don't use rd
							$display("SW INSTRUCTION FIREDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD");
							result_dest_1 = rs[num].sw_reg;
						end
						else begin
							result_dest_1 = rs[num].dest_reg;
						end
						
						result_valid_1 = 1;
						result_ROB_1 = rs[num].rob_index;
						result_FU_1 = rs[num].fu_index;
						
						instr_found_1 = 1;
						$display("ISSUE ENABLED - INSTRUCTION 1 FIRED");
						$display("%d + %d -> P_reg %d", ALU_source_1_1, ALU_source_2_1, result_dest_1);
						
						//clear the whole row
						rs[num] = 0;
					end
				end
				
				
				// Fire second instruction
				instr_found_2 = 0;
				for(num = 0; num < 16; num = num + 1) begin
				
					if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
							&& rs[num].sw_ready == 1 && instr_found_2 == 0) begin
						
						ALU_opcode_2 = rs[num].op;
						ALU_func3_2 = rs[num].func3;
						ALU_func7_2 = rs[num].func7;
						ALU_source_1_2 = rs[num].src_data_1;
						ALU_source_2_2 = rs[num].src_data_2;

						if (rs[num].op == 7'b0100011) begin	// If SW, we don't use rd
							$display("SW INSTRUCTION FIREDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD");
							result_dest_2 = rs[num].sw_reg;
						end
						else begin
							result_dest_2 = rs[num].dest_reg;
						end
						
						result_valid_2 = 1;
						result_ROB_2 = rs[num].rob_index;
						result_FU_2 = rs[num].fu_index;
						instr_found_2 = 1;
						$display("ISSUE ENABLED - INSTRUCTION 2 FIRED");
						$display("%d + %d -> P_reg %d", ALU_source_1_2, ALU_source_2_2, result_dest_2);
						
						rs[num] = 0;
					end
				end
				
				// Fire third instruction
				instr_found_3 = 0;
				for(num = 0; num < 16; num = num + 1) begin
				
					if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
							&& rs[num].sw_ready == 1 && instr_found_3 == 0) begin
							
						
						ALU_opcode_3 = rs[num].op;
						ALU_func3_3 = rs[num].func3;
						ALU_func7_3 = rs[num].func7;
						ALU_source_1_3 = rs[num].src_data_1;
						ALU_source_2_3 = rs[num].src_data_2;

						if (rs[num].op == 7'b0100011) begin	// If SW, we don't use rd
							$display("SW INSTRUCTION FIREDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD");
							result_dest_3 = rs[num].sw_reg;
						end
						else begin
							result_dest_3 = rs[num].dest_reg;
						end
						
						result_valid_3 = 1;
						result_ROB_3 = rs[num].rob_index;
						result_FU_3 = rs[num].fu_index;
						instr_found_3 = 1;
						$display("ISSUE ENABLED - INSTRUCTION 3 FIRED");
						$display("%d + %d -> P_reg %d", ALU_source_1_3, ALU_source_2_3, result_dest_3);
						
						rs[num] = 0;
					end
				end

				//Rest of Dispatch stage ///////////////////////////////////////////////
				rs_line_1 = un; 
				
				rs[un].in_use = 1'b1;
				rs[un].op = opcode_1;
				rs[un].func3 = func3_1;
				rs[un].func7 = func7_1;
				//$display("pd_1: %d", pd_1);
				rs[un].dest_reg = pd_1;
				rs[un].src_reg_1 = ps1_1;
				rs[un].src_reg_2 = ps2_1;
				rs[un].sw_reg = 0;
				rs[un].sw_ready = 1'b1;
				
				//Set source 1 data if possible
				case (opcode_1)
					7'b0010011: begin	// ADDI & ANDI
						rs[un].src_data_1 = p_rg[ps1_1];
						rs[un].src1_ready = p_reg_R[ps1_1];
					end
					7'b0110011: begin	// ADD, SUB, XOR, SRA
						rs[un].src_data_1 = p_rg[ps1_1];
						rs[un].src1_ready = p_reg_R[ps1_1];
					end
					7'b0000011: begin		// LW
						rs[un].src_data_1 = p_rg[ps1_1];
						rs[un].src1_ready = p_reg_R[ps1_1];
					end
					7'b0100011: begin		// SW
						rs[un].src_data_1 = p_rg[ps1_1];
						rs[un].src1_ready = p_reg_R[ps1_1];
					end
					
					default: begin
						rs[un].src_data_1 = 31'b0;
						rs[un].src1_ready = 1'b0;
						rs[un].in_use = 1'b0;
					end
				endcase
				
				if (ps1_1 == 0) begin
					rs[un_2].src1_ready = 1'b1;
				end
				
				//Set source 2 data/immediate if possible
				case (opcode_1)
					7'b0010011: begin	// ADDI & ANDI
						rs[un].src_data_2 = {20'b0, instr_1[31:20]};
						rs[un].src2_ready = 1'b1;
					end
					7'b0110011: begin	// ADD, SUB, XOR, SRA
						rs[un].src_data_2 = p_rg[ps2_1];
						rs[un].src2_ready = p_reg_R[ps2_1];
					end
					7'b0000011: begin		// LW
						rs[un].src_data_2 = {20'b0, instr_1[31:20]};
						rs[un].src2_ready = 1'b1;
					end
					7'b0100011: begin		// SW
						rs[un].src_data_2 = {20'b0, instr_1[31:25], instr_1[11:7]};
						rs[un].src2_ready = 1'b1;
						rs[un].sw_reg = ps2_1;
						rs[un].sw_ready = p_reg_R[ps2_1];
					end
					default: begin
						rs[un].src_data_2 = 31'b0;
						rs[un].src2_ready = 1'b0;
						rs[un].in_use = 1'b0;
					end
				endcase
				
				if (ps2_1 == 0) begin
					rs[un].src2_ready = 1'b1;
				end
				
				
			//determine fu_index from opcode
				if (opcode_1 == 7'b0100011 || opcode_1 == 7'b0000011) begin//if instr is SW or LW
					rs[un].fu_index = 2; //index 2 corresponds to FU 3 (mem only)
				end
				else begin
					if(switch == 0) begin //alternate between FU 1 and 2
						rs[un].fu_index = 0;
						switch = 1;
					end
					else begin
						rs[un].fu_index = 1; 
						switch = 0;
					end
				end
			
				//Set up the ROB row corresponding to the instruction 
				$display("Switching ROB signal");
				if(rob_switch == 0) begin //alternate ROB signal
						u_rob = 1;
						rob_switch = 1;
					end
					else begin
						u_rob = 0; 
						rob_switch = 0;
					end
				
				rob_p_1 = pd_1;
				rob_op_1 = opcode_1;
				o_rob_p_1 = o_pd_1;
				
				//Mark destination register as not ready
				if (opcode_1 != 7'b0100011 && pd_1 != 0) begin	// Don't do anything if SW or x0
					p_reg_R[pd_1] = 1'b0;
				end
				
				
				/////////////// OK NOW DO IT AGAIN :) /////////////////////////
				
				
				rs_line_2 = un_2; 
				
				rs[un_2].in_use = 1'b1;
				rs[un_2].op = opcode_2;
				rs[un_2].func3 = func3_2;
				rs[un_2].func7 = func7_2;
				//$display("pd_2: %d", pd_2);
				rs[un_2].dest_reg = pd_2;
				rs[un_2].src_reg_1 = ps1_2;
				rs[un_2].src_reg_2 = ps2_2;
				rs[un_2].sw_reg = 0;
				rs[un_2].sw_ready = 1'b1;

				//Set source 1 data if possible
				case (opcode_2)
					7'b0010011: begin	// ADDI & ANDI
						rs[un_2].src_data_1 = p_rg[ps1_2];
						rs[un_2].src1_ready = p_reg_R[ps1_2];
					end
					7'b0110011: begin	// ADD, SUB, XOR, SRA
						rs[un_2].src_data_1 = p_rg[ps1_2];
						rs[un_2].src1_ready = p_reg_R[ps1_2];
					end
					7'b0000011: begin		// LW
						rs[un_2].src_data_1 = p_rg[ps1_2];
						rs[un_2].src1_ready = p_reg_R[ps1_2];
					end
					7'b0100011: begin		// SW
						rs[un_2].src_data_1 = p_rg[ps1_2];
						rs[un_2].src1_ready = p_reg_R[ps1_2];
					end
					default: begin
						rs[un_2].src_data_1 = 31'b0;
						rs[un_2].src1_ready = 1'b0;
						rs[un_2].in_use = 1'b0;
					end
					
				endcase
				
				if (ps1_2 == 0) begin
					rs[un_2].src1_ready = 1'b1;
				end
					
				//Set source 2 data/immediate if possible
				case (opcode_2)
					7'b0010011: begin	// ADDI & ANDI
						rs[un_2].src_data_2 = {20'b0, instr_2[31:20]};
						rs[un_2].src2_ready = 1'b1;
					end
					7'b0110011: begin	// ADD, SUB, XOR, SRA
						rs[un_2].src_data_2 = p_rg[ps2_2];
						rs[un_2].src2_ready = p_reg_R[ps2_2];
					end
					7'b0000011: begin		// LW
						rs[un_2].src_data_2 = {20'b0, instr_2[31:20]};
						rs[un_2].src2_ready = 1'b1;
					end
					7'b0100011: begin		// SW
						rs[un_2].src_data_2 = {20'b0, instr_2[31:25], instr_2[11:7]};
						rs[un_2].src2_ready = 1'b1;
						rs[un_2].sw_reg = ps2_2;
						rs[un_2].sw_ready = p_reg_R[ps2_2];
					end
					default: begin
						rs[un_2].src_data_2 = 31'b0;
						rs[un_2].src2_ready = 1'b0;
						rs[un_2].in_use = 1'b0;
					end
				endcase
				
				if (ps2_2 == 0) begin
					rs[un_2].src2_ready = 1'b1;
				end
						
				
				//determine fu_index from opcode
				if (opcode_2 == 7'b0100011 || opcode_2 == 7'b0000011) begin//if instr is LW or SW
					rs[un_2].fu_index = 2; //index 2 corresponds to FU 3 (mem only)
				end
				else begin
					if(switch == 0) begin //alternate between FU 1 and 2
						rs[un_2].fu_index = 0;
						switch = 1;
					end
					else begin
						rs[un_2].fu_index = 1; 
						switch = 0;
					end
				end
				
				
				
				//ROB stuff
				rob_p_2 = pd_2;
				rob_op_2 = opcode_2;
				o_rob_p_2 = o_pd_2;
				
				//Mark destination register as not ready
				
				if (opcode_1 != 7'b0100011 && pd_2 != 0) begin			// Don't do anything if SW
					p_reg_R[pd_2] = 1'b0;
				end

				pd_1_ = pd_1; //to let complete stage know when a new cycle has passed
				
				//Display entire reservation station
				for(integer n = 0; n < 16; n = n + 1) begin
					$display("RS Line %d: %b, %b, %b, %b, dest: %d, src1: %d, %d, %d, src2: %d, %d, %d, sw: %d, %d, fu: %b, %b", n, rs[n].in_use, 
							rs[n].op, rs[n].func3, rs[n].func7, rs[n].dest_reg, rs[n].src_reg_1,
							rs[n].src_data_1, rs[n].src1_ready, rs[n].src_reg_2, rs[n].src_data_2,
							rs[n].src2_ready, rs[n].sw_reg, rs[n].sw_ready, rs[n].fu_index, rs[n].rob_index);
				end
				
				// Find if the RS is empty or not
				RS_filled = 0;
				for(num = 0; num < 16; num = num + 1) begin
					if (rs[num].in_use == 1) begin
						RS_filled = 1;
					end
				end
				$display("RS_filled = %d", RS_filled);
					
			end
			//else begin
			//	u_rob = 0;
			//end	
		end
		
		else begin
			rs_line_1 = 0;
			rs_line_2 = 0;
		end
		
		en_flag_o = (en_flag_i/* || RS_filled*/);
	end

endmodule
