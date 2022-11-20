
//`include "M116C-Honors/modules.sv"
`timescale 1ns/1ns // Tell Questa what time scale to run at

package p;
	reg [5:0] rat[31:0]; //RAT - maps 32 architectural registers to physical register
	reg free_pool[63:0]; //kind-of free pool --> contains value that each phy reg points to, and a beginning flag for if there is a current value attached to the phy reg
	reg [31:0] p_regs[63:0]; //data that physical regs contain
endpackage
	

module main(instr_1, instr_2, rs1_do_1, rs2_do_1, rd_do_1, rs1_do_2, rs2_do_2, rd_do_2, ps1_ro_1, ps2_ro_1, pd_ro_1, ps1_ro_2, ps2_ro_2, pd_ro_2); 

	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10
		clk = ~clk;
	end

	import p::rat;
	import p::free_pool;
	
	reg [7:0] mem[127:0];	// Instruction Memory
	
	// Decode Stage Regs
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
	
	// Rename Stage Regs
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
	
	integer program_counter = 0;
	integer ready = 0; //flag to start always block
	
	//Decode stage
	decode dec(instr_1, opcode_do_1, func3_do_1, func7_do_1, rs1_do_1, rs2_do_1, rd_do_1, instr_do_1, 
					instr_2, opcode_do_2, func3_do_2, func7_do_2, rs1_do_2, rs2_do_2, rd_do_2, instr_do_2);
	
	//Rename stage
	rename ren(opcode_ri_1, func3_ri_1, func7_ri_1, rs1_ri_1, rs2_ri_1, rd_ri_1, instr_ri_1, opcode_ro_1, func3_ro_1, func7_ro_1, ps1_ro_1, ps2_ro_1, pd_ro_1, instr_ro_1,
					opcode_ri_2, func3_ri_2, func7_ri_2, rs1_ri_2, rs2_ri_2, rd_ri_2, instr_ri_2, opcode_ro_2, func3_ro_2, func7_ro_2, ps1_ro_2, ps2_ro_2, pd_ro_2, instr_ro_2);
					
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
		//loop so that all rat values are assigned to p1 to p32 and first 32 free_pool are also all 1
		integer n;

		for(n = 0; n < 32; n = n + 1) begin
			rat[n] = n;
			free_pool[n] = 1;
		end 

		for(n = 32; n < 64; n = n + 1) begin
			free_pool[n] = 0;
		end
	
		for(n = 0; n < 128; n = n + 1) begin
			mem[n] = 0;
		end

		//$readmemh("C:/Users/geosp/Desktop/M116C_Honors/M116C-Honors/r-test-hex.txt", mem);
		$readmemh("C:/Users/Nathan Nguyendinh/Documents/Quartus_Projects/M116C/OOP_RISC-V/src/r-test-hex.txt", mem);
		$display("Mem: %p", mem);
		
		ready = 1;
		
	end
	
	//Pipeline between fetch and decode
	always @(posedge clk) begin
		if(ready == 1) begin
			instr_1 <= {mem[program_counter],mem[program_counter+1],mem[program_counter+2],mem[program_counter+3]};
			instr_2 <= {mem[program_counter+4],mem[program_counter+5],mem[program_counter+6],mem[program_counter+7]};
			
			if (instr_1 == 0) begin
				$stop;	
			end
			
			$display("Instr: %b", instr_1);
			program_counter = program_counter + 8;
			
		end
	end
	
	//Pipeline between decode and rename
	always @(posedge clk) begin
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
	
endmodule


