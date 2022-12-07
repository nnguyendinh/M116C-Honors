
//`include "M116C-Honors/modules.sv"
`timescale 1ns/1ns // Tell Questa what time scale to run at
	
package p;
	typedef struct packed {
		reg in_use; //if the row is in use
		reg[6:0] op;
		reg [2:0] func3;
		reg [6:0] func7;
		reg[5:0] dest_reg;
		reg[5:0] src_reg_1;
		reg[31:0] src_data_1;
		reg src1_ready;
		reg[5:0] src_reg_2;
		reg[31:0] src_data_2;
		reg src2_ready;
		reg [1:0] fu_index;
		reg [3:0] rob_index;
	} rs_row;

	typedef struct packed {
		reg v; //know if ROB row is in use
		//so you know if store to memory or store to register
		reg instr_type; //not necessarily opcode, just need to know if store to memory or register
		// 0 --> store to register, 1 --> store to memory
		reg [5:0] phy_reg; //index of destination phy reg (or dest. memory address)
		reg[31:0] result; //result from ALU
		reg[31:0] old_result; //old result of the dest. phy reg (if it exists at all)
		reg comp; //0 if instruction is incomplete, 1 if instruction is complete
	} rob_row;
	
	reg [5:0] rat[31:0]; //RAT - maps 32 architectural registers to physical register
	reg free_pool[63:0]; //kind-of free pool --> contains value that each phy reg points to, and a beginning flag for if there is a current value attached to the phy reg
	reg [31:0] p_regs[63:0]; //data that physical regs contain
	rs_row rs [16]; //reservation Station (16 rows)
	reg p_reg_R[63:0]; //array of flags if p_reg is ready
	rob_row rob [16]; //re-order buffer (16 rows)
	reg FU_ready [2:0];
endpackage
	

module main(instr_1, instr_2, rs1_do_1, rs2_do_1, rd_do_1, rs1_do_2, rs2_do_2, rd_do_2, ps1_ro_1, ps2_ro_1, pd_ro_1, ps1_ro_2, ps2_ro_2, pd_ro_2,
				result_1, result_dest_1, result_valid_1, result_2, result_dest_2, result_valid_2,
						result_3, result_dest_3, result_valid_3); 

	
	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10

		clk = ~clk;
	end

	import p::rat;
	import p::free_pool;
	import p::p_reg_R;
	import p::p_regs;
	import p::rs;
	import p::rob;
	import p::FU_ready;
	
	reg [7:0] mem[127:0];	// Instruction Memory
	
	// Decode Stage Regs
	//reg enable_flag = 0;
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
	
	// Rename Stage Regs
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
	
	//Dispatch Stage Regs
	reg en_flag_dii;
	reg [6:0] opcode_dii_1;
	reg [2:0] func3_dii_1;
	reg [6:0] func7_dii_1;
	reg [5:0] ps1_dii_1;
	reg [5:0] ps2_dii_1;
	reg [5:0] pd_dii_1;
	reg [31:0] instr_dii_1;
	integer rs_line_dio_1;
	reg [6:0] opcode_dio_1;
	
	reg [6:0] opcode_dii_2;
	reg [2:0] func3_dii_2;
	reg [6:0] func7_dii_2;
	reg [5:0] ps1_dii_2;
	reg [5:0] ps2_dii_2;
	reg [5:0] pd_dii_2;
	reg [31:0] instr_dii_2;
	integer rs_line_dio_2;
	reg [6:0] opcode_dio_2;
	reg en_flag_dio;
	
	output reg [31:0] result_1;
	output reg [5:0] result_dest_1;
	output reg result_valid_1;
	
	output reg [31:0] result_2;
	output reg [5:0] result_dest_2;
	output reg result_valid_2;
	
	output reg [31:0] result_3;
	output reg [5:0] result_dest_3;
	output reg result_valid_3;
	
	integer program_counter = 0;
	integer ready = 0; //flag to start always block
	
	//Decode stage
	decode dec(en_flag_di, instr_1, opcode_do_1, func3_do_1, func7_do_1, rs1_do_1, rs2_do_1, rd_do_1, instr_do_1, 
					instr_2, opcode_do_2, func3_do_2, func7_do_2, rs1_do_2, rs2_do_2, rd_do_2, instr_do_2, en_flag_do);
	
	//Rename stage
	rename ren(en_flag_ri, opcode_ri_1, func3_ri_1, func7_ri_1, rs1_ri_1, rs2_ri_1, rd_ri_1, instr_ri_1, opcode_ro_1, func3_ro_1, func7_ro_1, ps1_ro_1, ps2_ro_1, pd_ro_1, instr_ro_1,
					opcode_ri_2, func3_ri_2, func7_ri_2, rs1_ri_2, rs2_ri_2, rd_ri_2, instr_ri_2, opcode_ro_2, func3_ro_2, func7_ro_2, ps1_ro_2, ps2_ro_2, pd_ro_2, instr_ro_2, en_flag_ro);
					
	//Dispatch stage
	dispatch disp(en_flag_dii, opcode_dii_1, func3_dii_1, func7_dii_1, ps1_dii_1, ps2_dii_1, pd_dii_1, instr_dii_1, rs_line_dio_1, 
						opcode_dii_2, func3_dii_2, func7_dii_2, ps1_dii_2, ps2_dii_2, pd_dii_2, instr_dii_2, rs_line_dio_2, en_flag_dio,
						result_1, result_dest_1, result_valid_1, result_2, result_dest_2, result_valid_2,
						result_3, result_dest_3, result_valid_3);
	
	//Complete stage
	
	
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
		//loop so that all rat values are assigned to p1 to p32 and first 32 free_pool are also all 1
		integer n;

		for(n = 0; n < 3; n = n + 1) begin
			FU_ready[n] = 1;
		end 
		
		for(n = 0; n < 16; n = n + 1) begin
			rs[n].in_use = 0;
			rob[n].v = 0;
		end 
		
		for(n = 0; n < 32; n = n + 1) begin
			rat[n] = n;
			free_pool[n] = 1;
			p_reg_R[n] = 1;
			p_regs[n] = 0;
		end 

		for(n = 32; n < 64; n = n + 1) begin
			free_pool[n] = 0;
			p_reg_R[n] = 1;
			p_regs[n] = 0;
		end
	
		for(n = 0; n < 128; n = n + 1) begin
			mem[n] = 0;
		end

		//$readmemh("C:/Users/geosp/Desktop/M116C_Honors/M116C-Honors/r-test-hex.txt", mem);
		$readmemh("C:/Users/Nathan Nguyendinh/Documents/Quartus_Projects/M116C/OOP_RISC-V/src/r-test-hex.txt", mem);
		//$display("Mem: %p", mem);
		
		ready = 1;
		
	end
	
	//Pipeline between fetch and decode
	always @(posedge clk) begin
		
		if(ready == 1) begin
			instr_1 <= {mem[program_counter],mem[program_counter+1],mem[program_counter+2],mem[program_counter+3]};
			instr_2 <= {mem[program_counter+4],mem[program_counter+5],mem[program_counter+6],mem[program_counter+7]};
			
			if (instr_1 == 0) begin
				en_flag_di <= 0;
			end
			
			else begin
				en_flag_di <= 1;
			end
			
			/*
			if(program_counter) begin
				$stop
			end
			*/
			
			$display("Instr: %b", instr_1);
			program_counter = program_counter + 8;

		end
	end
	
	//Pipeline between decode and rename
	always @(posedge clk) begin
		en_flag_ri <= en_flag_do;
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
		en_flag_dii <= en_flag_ro;
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
		
	end
	
	always @(posedge clk) begin
		$display("RS ROB Index 1: %b", rs[rs_line_dio_1].rob_index);
		$display("RS Dest Reg 1: %b", rs[rs_line_dio_1].dest_reg);
		$display("ROB in use 1: %b", rob[rs_line_dio_1].v);
		$display("ROB instr_type 1: %b", rob[rs_line_dio_1].instr_type);
		$display("ROB phy reg 1: %b", rob[rs_line_dio_1].phy_reg);
		
		$display("RS ROB Index 2: %b", rs[rs_line_dio_2].rob_index);
		$display("RS Dest Reg 2: %b", rs[rs_line_dio_2].dest_reg);
		$display("ROB in use 2: %b", rob[rs_line_dio_2].v);
		$display("ROB instr_type 2: %b", rob[rs_line_dio_2].instr_type);
		$display("ROB phy reg 2: %b", rob[rs_line_dio_2].phy_reg);


		/*
		$display("In Use 1: %b", rs[rs_line_dio_1].in_use);
		$display("Op 1: %b", rs[rs_line_dio_1].op);
		$display("Func3 1: %b", rs[rs_line_dio_1].func3);
		$display("Func7 1: %b", rs[rs_line_dio_1].func7);
		$display("Dest Reg 1: %b", rs[rs_line_dio_1].dest_reg);
		$display("Src 1 Reg 1: %b", rs[rs_line_dio_1].src_reg_1);
		$display("Src 1 Data 1: %b", rs[rs_line_dio_1].src_data_1);
		$display("Src 1 Ready 1: %b", rs[rs_line_dio_1].src1_ready);
		$display("Src 2 Reg 1: %b", rs[rs_line_dio_1].src_reg_2);
		$display("Src 2 Data 1: %b", rs[rs_line_dio_1].src_data_2);
		$display("Src 2 Ready 1: %b", rs[rs_line_dio_1].src2_ready);
		$display("FU Index 1: %b", rs[rs_line_dio_1].fu_index);
		$display("ROB Index 1: %b", rs[rs_line_dio_1].rob_index);

		$display("In Use 2: %b", rs[rs_line_dio_1].in_use);
		$display("Op 2: %b", rs[rs_line_dio_2].op);
		$display("Func3 2: %b", rs[rs_line_dio_2].func3);
		$display("Func7 2: %b", rs[rs_line_dio_2].func7);
		$display("Dest Reg 2: %b", rs[rs_line_dio_2].dest_reg);
		$display("Src 1 Reg 2: %b", rs[rs_line_dio_2].src_reg_1);
		$display("Src 1 Data 2: %b", rs[rs_line_dio_2].src_data_1);
		$display("Src 1 Ready 2: %b", rs[rs_line_dio_2].src1_ready);
		$display("Src 2 Reg 2: %b", rs[rs_line_dio_2].src_reg_2);
		$display("Src 2 Data 2: %b", rs[rs_line_dio_2].src_data_2);
		$display("Src 2 Ready 2: %b", rs[rs_line_dio_2].src2_ready);
		$display("FU Index 2: %b", rs[rs_line_dio_2].fu_index);
		$display("ROB Index 2: %b", rs[rs_line_dio_2].rob_index);
		*/
	end
	
endmodule


