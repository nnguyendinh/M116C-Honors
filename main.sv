
//`include "M116C-Honors/modules.sv"
`timescale 1ns/1ns // Tell Questa what time scale to run at
	
package p;
	typedef struct packed {
		reg in_use; //if the row is in use
		reg[6:0] op;
		reg [2:0] func3;
		reg [6:0] func7;
		reg[5:0] dest_reg;
		reg[5:0] sw_reg;
		reg sw_ready;
		reg[5:0] src_reg_1;
		reg[31:0] src_data_1;
		reg src1_ready;
		reg[5:0] src_reg_2;
		reg[31:0] src_data_2;
		reg src2_ready;
		reg [1:0] fu_index;
		reg [3:0] rob_index;
		reg [6:0] pc;
	} rs_row;

	typedef struct packed {
		reg v; //know if ROB row is in use
		//so you know if store to memory or store to register
		reg [1:0] instr_type; //not necessarily opcode, just need to know if store to memory or register
		// 0 --> store to register, 1 --> store to memory, 2--> load from memory & store to register
		reg [5:0] phy_reg; //index of destination phy reg (or dest. memory address)
		reg [6:0] pc;
		reg[31:0] result; //result from ALU
		reg[31:0] old_phy; //old phy reg
		reg[31:0] old_result; //old result of the dest. phy reg (if it exists at all)
		reg comp; //0 if instruction is incomplete, 1 if instruction is complete
	} rob_row;
	
	reg [5:0] rat[31:0]; //RAT - maps 32 architectural registers to physical register
	//reg [31:0] p_regs[63:0]; //data that physical regs contain
	reg [7:0] main_mem [255:0];
endpackage
	

module main(instr_1, instr_2, rs1_do_1, rs2_do_1, rd_do_1, rs1_do_2, rs2_do_2, rd_do_2, ps1_ro_1, ps2_ro_1, pd_ro_1, ps1_ro_2, ps2_ro_2, pd_ro_2,
				result_d1, result_dest_d1, result_valid_d1, result_d2, result_dest_d2, result_valid_d2,
						result_d3, result_dest_d3, result_valid_d3, update_rob, rob_p_reg_1, rob_p_reg_2,
						forward_flag_1, dest_R_1, forwarded_data_1, forward_flag_2, dest_R_2, forwarded_data_2, forward_flag_3, dest_R_3, forwarded_data_3,
						ps1_dii_1, ps2_dii_1, pd_dii_1, ps1_dii_2, ps2_dii_2, pd_dii_2,
						retire_flag_1, fp_ind_1, retire_flag_2, fp_ind_2, pr_flag,
						retire_index_1, retire_result_1, retire_index_2, retire_result_2, total_instr_count, cycle_count, c_dii, tot_instr_disp,
						PC1_do, PC2_do, PC1_ro, PC2_ro, rob_pc_1, rob_pc_2); 

	
	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10

		clk = ~clk;
	end

	import p::rat;
	//import p::p_regs;
	
	reg [7:0] instr_mem[127:0];	// Instruction Memory
	reg [31:0] p_regs[63:0]; //data that physical regs contain
	output reg [31:0] total_instr_count; //total instruction count
	output reg [31:0] tot_instr_disp;
	output reg [31:0] cycle_count;
	
	// Decode Stage Regs
	//reg enable_flag = 0;
	reg[6:0] PC1_di;
	reg[6:0] PC2_di;
	reg en_flag_di;
	output reg[31:0] instr_1;
	reg[6:0] opcode_do_1;
	reg[2:0] func3_do_1;
	reg[6:0] func7_do_1;
	output reg[4:0] rs1_do_1;
	output reg[4:0] rs2_do_1;
	output reg[4:0] rd_do_1;
	reg[31:0] instr_do_1;
	
	output reg[31:0] instr_2;
	reg[6:0] opcode_do_2;
	reg[2:0] func3_do_2;
	reg[6:0] func7_do_2;
	output reg[4:0] rs1_do_2;
	output reg[4:0] rs2_do_2;
	output reg[4:0] rd_do_2;
	reg[31:0] instr_do_2;
	reg en_flag_do;
	output reg[6:0] PC1_do;
	output reg[6:0] PC2_do;
	
	// Rename Stage Regs
	reg[6:0] PC1_ri;
	reg[6:0] PC2_ri;
	reg en_flag_ri;
	reg [6:0] opcode_ri_1;
	reg [2:0] func3_ri_1;
	reg [6:0] func7_ri_1;
	reg [4:0] rs1_ri_1;
	reg [4:0] rs2_ri_1;
	reg [4:0] rd_ri_1;
	reg [31:0] instr_ri_1;
	output reg [5:0] ps1_ro_1;			
	output reg [5:0] ps2_ro_1;
	output reg [5:0] pd_ro_1;
	reg [6:0] opcode_ro_1;
	reg [2:0] func3_ro_1;
	reg [6:0] func7_ro_1;
	reg [31:0] instr_ro_1;
	
	reg [6:0] opcode_ri_2;
	reg [2:0] func3_ri_2;
	reg [6:0] func7_ri_2;
	reg [4:0] rs1_ri_2;
	reg [4:0] rs2_ri_2;
	reg [4:0] rd_ri_2;
	reg [31:0] instr_ri_2;
	output reg [5:0] ps1_ro_2;			
	output reg [5:0] ps2_ro_2;
	output reg [5:0] pd_ro_2;
	reg [6:0] opcode_ro_2;
	reg [2:0] func3_ro_2;
	reg [6:0] func7_ro_2;
	reg [31:0] instr_ro_2;
	reg en_flag_ro;
	output reg[6:0] PC1_ro;
	output reg[6:0] PC2_ro;
	
	reg [5:0] old_pd_ro_1;
	reg [5:0] old_pd_ro_2;
	
	//Dispatch Stage Regs
	reg[6:0] PC1_dii;
	reg[6:0] PC2_dii;
	reg en_flag_dii;
	reg [6:0] opcode_dii_1;
	reg [2:0] func3_dii_1;
	reg [6:0] func7_dii_1;
	output reg [5:0] ps1_dii_1;
	output reg [5:0] ps2_dii_1;
	output reg [5:0] pd_dii_1;
	reg [31:0] instr_dii_1;
	integer rs_line_dio_1;
	reg [6:0] opcode_dio_1;
	
	reg [6:0] opcode_dii_2;
	reg [2:0] func3_dii_2;
	reg [6:0] func7_dii_2;
	output reg [5:0] ps1_dii_2;
	output reg [5:0] ps2_dii_2;
	output reg [5:0] pd_dii_2;
	reg [31:0] instr_dii_2;
	integer rs_line_dio_2;
	reg [6:0] opcode_dio_2;
	reg en_flag_dio;
	
	output reg [31:0] result_d1;
	output reg [5:0] result_dest_d1;
	output reg result_valid_d1;
	reg [3:0] result_ROB_d1;
	reg [1:0] result_FU_d1;
	reg [6:0] result_pc_d1;
	
	output reg [31:0] result_d2;
	output reg [5:0] result_dest_d2;
	output reg result_valid_d2;
	reg [3:0] result_ROB_d2;
	reg [1:0] result_FU_d2;
	reg [6:0] result_pc_d2;
	
	output reg [31:0] result_d3;
	output reg [5:0] result_dest_d3;
	output reg result_valid_d3;
	reg [3:0] result_ROB_d3;
	reg [1:0] result_FU_d3;
	reg [6:0] result_pc_d3;
	
	output reg update_rob;
	output reg [5:0] rob_p_reg_1;
	reg [6:0] rob_opcode_1;
	output reg [6:0] rob_pc_1;
	
	output reg [5:0] rob_p_reg_2;
	reg [6:0] rob_opcode_2;
	output reg [6:0] rob_pc_2;
	
	output reg forward_flag_1;
	output reg [5:0] dest_R_1;
	output reg [31:0] forwarded_data_1;
	output reg forward_flag_2;
	output reg [5:0] dest_R_2;
	output reg [31:0] forwarded_data_2;
	output reg forward_flag_3;
	output reg [5:0] dest_R_3;
	output reg [31:0] forwarded_data_3;
	
	reg [5:0] old_pd_dii_1;
	reg [5:0] old_pd_dii_2;
	reg [5:0] o_rob_p_reg_1;
	reg [5:0] o_rob_p_reg_2;
	reg [5:0] pd_1_dio;
	
	//Complete stage Regs
	
	reg en_flag_ci;
	
	reg [31:0] result_c1;
	reg [5:0] result_dest_c1;
	reg result_valid_c1;
	reg [3:0] result_ROB_c1;
	reg [1:0] result_FU_c1;
	reg [6:0] result_pc_c1;
	
	reg [31:0] result_c2;
	reg [5:0] result_dest_c2;
	reg result_valid_c2;
	reg [3:0] result_ROB_c2;
	reg [1:0] result_FU_c2;
	reg [6:0] result_pc_c2;
	
	reg [31:0] result_c3;
	reg [5:0] result_dest_c3;
	reg result_valid_c3;
	reg [3:0] result_ROB_c3;
	reg [1:0] result_FU_c3;
	reg [6:0] result_pc_c3;
	
	output reg retire_flag_1; //outputs for retire signals
	output reg [4:0] retire_index_1;
	output reg [31:0] retire_result_1;
	output reg [5:0] fp_ind_1;
	output reg retire_flag_2;
	output reg [4:0] retire_index_2;
	output reg [31:0] retire_result_2;
	output reg [5:0] fp_ind_2;
	output reg pr_flag;

	reg [5:0] pd_1_ci;
	
	reg en_flag_co;
	
	reg[31:0] c_di;
	reg[31:0] c_do;
	reg[31:0] c_ri;
	reg[31:0] c_ro;
	output reg[31:0] c_dii;
	reg[31:0] c_dio;
	reg[31:0] c_ci;
	
	
	integer program_counter = 0;
	integer ready = 0; //flag to start always block
	
	//Decode stage
	decode dec(PC1_di, PC2_di, c_di, en_flag_di, instr_1, opcode_do_1, func3_do_1, func7_do_1, rs1_do_1, rs2_do_1, rd_do_1, instr_do_1, 
					instr_2, opcode_do_2, func3_do_2, func7_do_2, rs1_do_2, rs2_do_2, rd_do_2, instr_do_2, en_flag_do, c_do, PC1_do, PC2_do);
	
	//Rename stage
	rename ren(PC1_ri, PC2_ri, c_ri, en_flag_ri, opcode_ri_1, func3_ri_1, func7_ri_1, rs1_ri_1, rs2_ri_1, rd_ri_1, instr_ri_1, opcode_ro_1, func3_ro_1, func7_ro_1, ps1_ro_1, ps2_ro_1, pd_ro_1, instr_ro_1,
					opcode_ri_2, func3_ri_2, func7_ri_2, rs1_ri_2, rs2_ri_2, rd_ri_2, instr_ri_2, opcode_ro_2, func3_ro_2, func7_ro_2, ps1_ro_2, ps2_ro_2, pd_ro_2, instr_ro_2, en_flag_ro,
					old_pd_ro_1, old_pd_ro_2, retire_flag_1, fp_ind_1, retire_flag_2, fp_ind_2, c_ro, PC1_ro, PC2_ro);
					
	//Dispatch stage
	dispatch disp(PC1_dii, PC2_dii, c_dii, en_flag_dii, opcode_dii_1, func3_dii_1, func7_dii_1, ps1_dii_1, ps2_dii_1, pd_dii_1, instr_dii_1, rs_line_dio_1, 
						opcode_dii_2, func3_dii_2, func7_dii_2, ps1_dii_2, ps2_dii_2, pd_dii_2, instr_dii_2, rs_line_dio_2, en_flag_dio,
						result_d1, result_dest_d1, result_valid_d1, result_ROB_d1, result_FU_d1, result_pc_d1, 
						result_d2, result_dest_d2, result_valid_d2, result_ROB_d2, result_FU_d2, result_pc_d2,
						result_d3, result_dest_d3, result_valid_d3, result_ROB_d3, result_FU_d3, result_pc_d3,
						update_rob, rob_p_reg_1, rob_opcode_1, rob_p_reg_2, rob_opcode_2, rob_pc_1, rob_pc_2,
						forward_flag_1, dest_R_1, forwarded_data_1, forward_flag_2, dest_R_2, forwarded_data_2, forward_flag_3, dest_R_3, forwarded_data_3,
						old_pd_dii_1, old_pd_dii_2, o_rob_p_reg_1, o_rob_p_reg_2, pd_1_dio, p_regs, clk, total_instr_count, tot_instr_disp, c_dio);
	
	//Complete stage
	
	complete comp(c_ci, en_flag_ci, result_c1, result_dest_c1, result_valid_c1, result_ROB_c1, result_FU_c1, result_pc_c1, 
									result_c2, result_dest_c2, result_valid_c2, result_ROB_c2, result_FU_c2, result_pc_c2, 
									result_c3, result_dest_c3, result_valid_c3, result_ROB_c3, result_FU_c3, result_pc_c3, 
									en_flag_co, update_rob, rob_p_reg_1, rob_opcode_1, rob_pc_1, rob_p_reg_2, rob_opcode_2, rob_pc_2,
									forward_flag_1, dest_R_1, forwarded_data_1, forward_flag_2, dest_R_2, forwarded_data_2, forward_flag_3, dest_R_3, forwarded_data_3,
									o_rob_p_reg_1, o_rob_p_reg_2, retire_flag_1, fp_ind_1, retire_flag_2, fp_ind_2, pd_1_ci, pr_flag,
									retire_index_1, retire_result_1, retire_index_2, retire_result_2, p_regs, total_instr_count);
	
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
		//loop so that all rat values are assigned to p1 to p32 and first 32 free_pool are also all 1
		integer n;
		for(n = 0; n < 32; n = n + 1) begin
			rat[n] = n;
		end 
	
		for(n = 0; n < 128; n = n + 1) begin
			instr_mem[n] = 0;
		end
		
		total_instr_count = 0;
		cycle_count = 0;

		$readmemh("C:/Users/geosp/Desktop/M116C_Honors/M116C-Honors/r-test-hex.txt", instr_mem);
		//$readmemh("C:/Users/geosp/Desktop/M116C_Honors/M116C-Honors/evaluation-hex.txt", instr_mem);
		//$readmemh("C:/Users/Nathan Nguyendinh/Documents/Quartus_Projects/M116C/OOP_RISC-V/src/r-test-hex.txt", instr_mem);
		//$readmemh("C:/Users/Nathan Nguyendinh/Documents/Quartus_Projects/M116C/OOP_RISC-V/src/evaluation-hex.txt", instr_mem);
		
		ready = 1;
		
	end
	
	//Pipeline between fetch and decode
	always @(posedge clk) begin
		
		if(ready == 1) begin
			
			cycle_count = cycle_count + 1;
			c_di <= cycle_count;
			
			instr_1 <= {instr_mem[program_counter],instr_mem[program_counter+1],instr_mem[program_counter+2],instr_mem[program_counter+3]};
			if(instr_1 != 0) begin
				total_instr_count = total_instr_count + 1;
			end
			
			instr_2 <= {instr_mem[program_counter+4],instr_mem[program_counter+5],instr_mem[program_counter+6],instr_mem[program_counter+7]};
			if(instr_2 != 0) begin
				total_instr_count = total_instr_count + 1;
			end
			
			$display("TOTAL COUNT: %d", total_instr_count);
			
			if (instr_1 == 0) begin
				en_flag_di <= 1;
			end
			
			else begin
				en_flag_di <= 1;
			end
			
			PC1_di <= program_counter;
			PC2_di <= program_counter + 4;
			
			/*
			if(program_counter) begin
				$stop
			end
			*/
			
			$display("Instr: %b", instr_1);
			$display("Instr: %b", instr_2);
			program_counter = program_counter + 8;
			
			/*
			if (program_counter >= 160) begin
				$stop;
			end
			*/

		end
	end
	
	//Pipeline between decode and rename
	always @(posedge clk) begin
		c_ri <= c_do;
		en_flag_ri <= en_flag_do;
		PC1_ri <= PC1_do;
		PC2_ri <= PC2_do;
		opcode_ri_1 <= opcode_do_1;
		func3_ri_1 <= func3_do_1;
		func7_ri_1 <= func7_do_1;
		rs1_ri_1 <= rs1_do_1;
		rs2_ri_1 <= rs2_do_1;
		rd_ri_1 <= rd_do_1;
		instr_ri_1 <= instr_do_1;
		
		opcode_ri_2 <= opcode_do_2;
		func3_ri_2 <= func3_do_2;
		func7_ri_2 <= func7_do_2;
		rs1_ri_2 <= rs1_do_2;
		rs2_ri_2 <= rs2_do_2;
		rd_ri_2 <= rd_do_2;
		instr_ri_2 <= instr_do_2;
		
	end
	
					
	//Pipeline between rename and dispatch
	always @(posedge clk) begin
		c_dii <= c_ro;
		en_flag_dii <= en_flag_ro;
		PC1_dii <= PC1_ro;
		PC2_dii <= PC2_ro;
		opcode_dii_1 <= opcode_ro_1;
		func3_dii_1 <= func3_ro_1;
		func7_dii_1 <= func7_ro_1;
		ps1_dii_1 <= ps1_ro_1;
		ps2_dii_1 <= ps2_ro_1;
		pd_dii_1 <= pd_ro_1;
		instr_dii_1 <= instr_ro_1;
		
		opcode_dii_2 <= opcode_ro_2;
		func3_dii_2 <= func3_ro_2;
		func7_dii_2 <= func7_ro_2;
		ps1_dii_2 <= ps1_ro_2;
		ps2_dii_2 <= ps2_ro_2;
		pd_dii_2 <= pd_ro_2;
		instr_dii_2 <= instr_ro_2;
		
		old_pd_dii_1 <= old_pd_ro_1;
		old_pd_dii_2 <= old_pd_ro_2;
		
	end
	
	
	//Pipeline between dispatch/issue and complete
	always @(posedge clk) begin
		c_ci <= c_dio;
		en_flag_ci <= en_flag_dio;
		pd_1_ci <= pd_1_dio;
		
		result_c1 <= result_d1;
		result_dest_c1 <= result_dest_d1;
		result_valid_c1 <= result_valid_d1;
		result_ROB_c1 <= result_ROB_d1;
		result_FU_c1 <= result_FU_d1;
		result_pc_c1 <= result_pc_d1;
		
		result_c2 <= result_d2;
		result_dest_c2 <= result_dest_d2;
		result_valid_c2 <= result_valid_d2;
		result_ROB_c2 <= result_ROB_d2;
		result_FU_c2 <= result_FU_d2;
		result_pc_c2 <= result_pc_d2;
		
		result_c3 <= result_d3;
		result_dest_c3 <= result_dest_d3;
		result_valid_c3 <= result_valid_d3;
		result_ROB_c3 <= result_ROB_d3;
		result_FU_c3 <= result_FU_d3;
		result_pc_c3 <= result_pc_d3;
		
	end
	
	
	always @(posedge clk) begin
		/*
		$display("pd_ro_1: %d", pd_ro_1);
		$display("pd_ro_2: %d", pd_ro_2);
		
		$display("pd_dii_1: %d", pd_dii_1);
		$display("pd_dii_2: %d", pd_dii_2);
		*/
	end
	
endmodule


