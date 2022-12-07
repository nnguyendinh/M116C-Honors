`timescale 1 ns / 1 ns 

module dispatch(en_flag_i, opcode_1, func3_1, func7_1, ps1_1, ps2_1, pd_1, instr_1, rs_line_1, 
						opcode_2, func3_2, func7_2, ps1_2, ps2_2, pd_2, instr_2, rs_line_2, en_flag_o,
						result_1, result_dest_1, result_valid_1, result_ROB_1, result_FU_1,
						result_2, result_dest_2, result_valid_2, result_ROB_2, result_FU_2,
						result_3, result_dest_3, result_valid_3, result_ROB_3, result_FU_3);

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
	
	import p::rs;
	import p::p_reg_R;
	import p::rs_row;
	import p::rob_row;
	import p::rob;
	import p::p_regs;
	import p::FU_ready;
		
	reg [4:0] un; //index of first unused
	reg [4:0] un_2; //index of second unused
	integer rob_un;
	integer rob_un_2;
	reg switch = 0;
	integer num;
	reg rob_found = 0;
	reg rs_found = 0;
	reg rob_found_2 = 0;
	reg rs_found_2 = 0;
	reg instr_found_1 = 0;
	reg instr_found_2 = 0;
	reg instr_found_3 = 0;
	rob_row dum;
	rob_row dum2;	

	ALU fu_1(ALU_opcode_1, ALU_func3_1, ALU_func7_1, ALU_source_1_1, ALU_source_2_1, result_dest_1, result_1);
	ALU fu_2(ALU_opcode_2, ALU_func3_2, ALU_func7_2, ALU_source_1_2, ALU_source_2_2, result_dest_2, result_2);
	ALU fu_3(ALU_opcode_3, ALU_func3_3, ALU_func7_3, ALU_source_1_3, ALU_source_2_3, result_dest_3, result_3);
	
	always@(*) begin
		//place instruction in reservation station (RS) --> mark as used, grab which operation, mark which FU
		//find first unused reservation station --> loop to find first unused every time?
		
		$display("Dispatch enabled: %b", en_flag_i);
		
		if(en_flag_i == 1) begin
			
			rs_found = 0;
			
			// Find first unused row in the RS
			for(num = 0; num < 16; num = num + 1) begin
				if (rs[num].in_use == 0 && rs_found == 0) begin
					un = num;
					rs_found = 1;
				end
			end
			
			rs_found_2 = 0;
			
			// Find second unused row in the RS
			for(num = 0; num < 16; num = num + 1) begin
				if (rs[num].in_use == 0 && rs_found_2 == 0 && num != un) begin
					un_2 = num;
					rs_found_2 = 1;
				end
			end
			
			// Issue/Fire Stage
			
			result_valid_1 = 0;
			result_valid_2 = 0;
			result_valid_3 = 0;
			
			// Fire first instruction
			instr_found_1 = 0;
			for(num = 0; num < 16; num = num + 1) begin
			
				if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
						&& FU_ready[rs[num].fu_index] == 1 && instr_found_1 == 0) begin
						
					rs[num].in_use = 0;
					
					ALU_opcode_1 = rs[num].op;
					ALU_func3_1 = rs[num].func3;
					ALU_func7_1 = rs[num].func7;
					ALU_source_1_1 = rs[num].src_data_1;
					ALU_source_2_1 = rs[num].src_data_2;

					result_dest_1 = rs[num].dest_reg;
					
					result_valid_1 = 1;
					result_ROB_1 = rs[num].rob_index;
					result_FU_1 = rs[num].fu_index;
					instr_found_1 = 1;
					$display("INSTRUCTION 1 FIRED");
					$display("%h + %h -> P_reg %b", ALU_source_1_1, ALU_source_2_1, result_dest_1);
				end
			end
			
			// Fire second instruction
			instr_found_2 = 0;
			for(num = 0; num < 16; num = num + 1) begin
			
				if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
						&& FU_ready[rs[num].fu_index] == 1 && instr_found_2 == 0) begin
						
					rs[num].in_use = 0;
					
					ALU_opcode_2 = rs[num].op;
					ALU_func3_2 = rs[num].func3;
					ALU_func7_2 = rs[num].func7;
					ALU_source_1_2 = rs[num].src_data_1;
					ALU_source_2_2 = rs[num].src_data_2;

					result_dest_2 = rs[num].dest_reg;
					
					result_valid_2 = 1;
					result_ROB_2 = rs[num].rob_index;
					result_FU_2 = rs[num].fu_index;
					instr_found_2 = 1;
					$display("INSTRUCTION 2 FIRED");
					$display("%h + %h -> P_reg %b", ALU_source_1_2, ALU_source_2_2, result_dest_2);
				end
			end
			
			// Fire third instruction
			instr_found_3 = 0;
			for(num = 0; num < 16; num = num + 1) begin
			
				if (rs[num].in_use == 1 && rs[num].src1_ready == 1 && rs[num].src2_ready == 1 
						&& FU_ready[rs[num].fu_index] == 1 && instr_found_3 == 0) begin
						
					rs[num].in_use = 0;
					
					ALU_opcode_3 = rs[num].op;
					ALU_func3_3 = rs[num].func3;
					ALU_func7_3 = rs[num].func7;
					ALU_source_1_3 = rs[num].src_data_1;
					ALU_source_2_3 = rs[num].src_data_2;

					result_dest_3 = rs[num].dest_reg;
					
					result_valid_3 = 1;
					result_ROB_3 = rs[num].rob_index;
					result_FU_3 = rs[num].fu_index;
					instr_found_3 = 1;
					$display("INSTRUCTION 3 FIRED");
					$display("%h + %h -> P_reg %b", ALU_source_1_3, ALU_source_2_3, result_dest_3);
				end
			end

			$display("line: %b",un);
			
			rs_line_1 = un; 
			
			rs[un].in_use = 1'b1;
			rs[un].op = opcode_1;
			rs[un].func3 = func3_1;
			rs[un].func7 = func7_1;
			rs[un].dest_reg = pd_1;
			rs[un].src_reg_1 = ps1_1;
			rs[un].src_reg_2 = ps2_1;
			
			//Set source 1 data if possible
			case (opcode_1)
				7'b0010011: begin	// ADDI & ANDI
					rs[un].src_data_1 = p_regs[ps1_1];
					rs[un].src1_ready = p_reg_R[ps1_1];
				end
				7'b0110011: begin	// ADD, SUB, XOR, SRA
					rs[un].src_data_1 = p_regs[ps1_1];
					rs[un].src1_ready = p_reg_R[ps1_1];
				end
				default: begin
					rs[un].src_data_1 = 31'b0;
					rs[un].src1_ready = 1'b0;
					
				end
			endcase
			
			//Set source 2 data/immediate if possible
			case (opcode_1)
				7'b0010011: begin	// ADDI & ANDI
					rs[un].src_data_2 = {20'b0, instr_1[31:20]};
					rs[un].src2_ready = 1'b1;
				end
				7'b0110011: begin	// ADD, SUB, XOR, SRA
					rs[un].src_data_2 = p_regs[ps2_1];
					rs[un].src2_ready = p_reg_R[ps2_1];
				end
				default: begin
					rs[un].src_data_2 = 31'b0;
					rs[un].src2_ready = 1'b0;
				end
			endcase
			
			
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
			
			rob_found = 0;
			
			//store in first unused ROB row
			for(num = 0; num < 16; num = num + 1) begin
				if (rob[num].v == 0 && rob_found == 0) begin
					rs[un].rob_index = num; //also correspond the ROB row to the RS row
					rob_un = num;
					rob_found = 1;
				end
			end
			
			dum.v = 1'b1;
			
			//let ROB know if writing to register or memory
			if (opcode_1 == 7'b0100011) begin //if SW 
				dum.instr_type = 1; //store to mem
			end
			else begin
				dum.instr_type = 0;
			end
			
			dum.phy_reg = pd_1;
			
			rob[rob_un] = dum;
			
			//Mark destination register as not ready
			p_reg_R[pd_1] = 1'b0;
			
			// Update global reservation station
			//rs[un] = dum;
			

			//$display("rs[un] op: %b", rs[un].op);
			
			
			/////////////// OK NOW DO IT AGAIN :) /////////////////////////
			
			rs_found_2 = 0;
			
			//second instruction in the cycle
			for(num = 0; num < 16; num = num + 1) begin
				if (rs[num].in_use == 0 && rs_found_2 == 0) begin
					un_2 = num;
					rs_found_2 = 1;
				end
			end
			
			rs_line_2 = un_2; 
			
			
			rs[un_2].in_use = 1;
			rs[un_2].op = opcode_2;
			rs[un_2].func3 = func3_2;
			rs[un_2].func7 = func7_2;
			rs[un_2].dest_reg = pd_2;
			rs[un_2].src_reg_1 = ps1_2;
			rs[un_2].src_reg_2 = ps2_1;

			//Set source 1 data if possible
			case (opcode_1)
				7'b0010011: begin	// ADDI & ANDI
					rs[un_2].src_data_1 = p_regs[ps1_2];
					rs[un_2].src1_ready = p_reg_R[ps1_2];
				end
				7'b0110011: begin	// ADD, SUB, XOR, SRA
					rs[un_2].src_data_1 = p_regs[ps1_2];
					rs[un_2].src1_ready = p_reg_R[ps1_2];
				end
				default: begin
					rs[un_2].src_data_1 = 31'b0;
					rs[un_2].src2_ready = 1'b0;
				end
			endcase
				
			//Set source 2 data/immediate if possible
			case (opcode_1)
				7'b0010011: begin	// ADDI & ANDI
					rs[un_2].src_data_2 = {20'b0, instr_2[31:20]};
					rs[un_2].src2_ready = 1'b1;
				end
				7'b0110011: begin	// ADD, SUB, XOR, SRA
					rs[un_2].src_data_2 = p_regs[ps2_2];
					rs[un_2].src2_ready = p_reg_R[ps2_2];
				end
				default: begin
					rs[un_2].src_data_2 = 31'b0;
					rs[un_2].src2_ready = 1'b0;
				end
			endcase
					
			//Mark destination register as not ready
			p_reg_R[pd_2] = 0;
			
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
			
			//grab index of first ROB unused
			
			rob_found_2 = 0;
			
			for(num = 0; num < 16; num = num + 1) begin
				if (rob[num].v == 0 && rob_found_2 == 0) begin
					rs[un_2].rob_index = num;
					rob_un_2 = num;
					rob_found_2 = 1;
				end

			end
			
			dum2.v = 1'b1;
			
			//let ROB know if writing to register or memory
			if (opcode_1 == 7'b0100011) begin //if SW 
				dum2.instr_type = 1; //store to mem
			end
			else begin
				dum2.instr_type = 0;
			end
			
			dum2.phy_reg = pd_2;
			
			rob[rob_un_2] = dum2;
			

			//$display("rs[un_2]: %b", rs[un_2].op);

		end
		
	else if (en_flag_i == 0) begin
	
		$stop;
		
	end
	
	else begin
		rs_line_1 = 0;
		rs_line_2 = 0;
	end
	
	
	en_flag_o = en_flag_i;
end

endmodule
