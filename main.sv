
//`include "M116C-Honors/modules.sv"
`timescale 1ns/1ns // Tell Questa what time scale to run at
	
package p;
	typedef struct packed {
		bit in_use; //if the row is in use
		reg[6:0] op;
		reg[4:0] dest_reg;
		reg[4:0] src_reg_1;
		bit src1_ready;
		reg[4:0] src_reg_2;
		bit src2_ready;
		reg [1:0] fu_index;
		reg [3:0] rob_index;
	} rs_row;

	typedef struct packed {
		bit v;
		reg[4:0] dest_reg;
		reg[4:0] old_dest_reg;
		reg[31:0] pc;
	} rob_row;
	
	reg [5:0] rat[31:0]; //RAT - maps 32 architectural registers to physical register
	reg free_pool[63:0]; //kind-of free pool --> contains value that each phy reg points to, and a beginning flag for if there is a current value attached to the phy reg
	reg [31:0] p_regs[63:0]; //data that physical regs contain
	rs_row rs [16]; //reservation Station (16 rows)
	reg p_reg_R[63:0]; //array of flags if p_reg is ready
	rob_row rob [16]; //re-order buffer (16 rows)
endpackage
	

module main(instr1, rs1_ri, rs2_ri, rd_ri, ps1_ro, ps2_ro, pd_ro); //declare a new module named main with one port called counter

	
	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10
		clk = ~clk;
	end

	
	//output reg[3:0] counter = 0;	//i dont think we care about this it was jsut what i copied and pasted
	
	import p::rat;
	import p::free_pool;
	import p::p_reg_R;
	
	reg [7:0] mem[127:0];	// Instruction Memory I guess
	
	// General Pipeline:
	
	// Pipeline Buffer #1
	reg[31:0] instruction1;
	reg[31:0] instruction2;
	
	// Decode Stage Regs
	output reg[31:0] instr1;
	reg[6:0] opcode_do;
	reg[4:0] rs1_do;
	reg[4:0] rs2_do;
	reg[4:0] rd_do;
	reg[31:0] instr_do;
	
	// Rename Stage Regs
	reg[6:0] opcode_ri;
	output reg[4:0] rs1_ri;
	output reg[4:0] rs2_ri;
	output reg[4:0] rd_ri;
	reg[31:0] instr_ri;
	output reg [5:0] ps1_ro;			// Physical registers are 6 bit because we have 128 of them
	output reg [5:0] ps2_ro;
	output reg [5:0] pd_ro;
	reg [6:0] opcode_ro;
	reg[31:0] instr_ro;
	
	integer program_counter = 0;
	integer ready = 0; //flag to start always block
	
	//Decode stage
	decode dec(instr1, opcode_do, rs1_do, rs2_do, rd_do, instr_do);
	
	//Rename stage
	rename ren(opcode_ri, rs1_ri, rs2_ri, rd_ri, instr_ri, opcode_ro, ps1_ro, ps2_ro, pd_ro, instr_ro);
	
	dispatch dispatch(opcode_dii_1, ps1_dii_1, ps2_dii_1, pd_dii_1, instr_dii_1, rs_line_dio_1, opcode_dio_1, opcode_dii_2, ps1_dii_2, ps2_dii_2, pd_dii_2, instr_dii_2, rs_line_dio_2, opcode_dio_2);
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
		//loop so that all rat values are assigned to p1 to p32 and first 32 free_pool are also all 1
		integer n;

		for(n = 0; n < 32; n = n + 1) begin
			rat[n] = n;
			free_pool[n] = 1;
			p_reg_R[n] = 0;
		end 

		for(n = 32; n < 64; n = n + 1) begin
			free_pool[n] = 0;
			p_reg_R[n] = 0;
		end
	
		for(n = 0; n < 128; n = n + 1) begin
			mem[n] = 0;
		end


		$readmemh("C:/Users/geosp/Desktop/M116C_Honors/M116C-Honors/r-test-hex.txt", mem);
		$display("Mem: %p", mem);
		
		ready = 1;
		
	end
	

	
	//Pipeline between fetch and decode
	always @(posedge clk) begin
		if(ready == 1) begin
			instr1 <= {mem[program_counter],mem[program_counter+1],mem[program_counter+2],mem[program_counter+3]};
			
			
			if (instr1 == 0) begin
				$stop;	
			end
			
			
			$display("Instr: %b", instr1);
			program_counter = program_counter + 4;
			
			/*
			#100;			//delay for 100 ticks (delcared as 1ns at the top!)
			$stop;		//tell simulator to stop the simuation
			*/
		end
	end
	
	//Pipeline between decode and rename
	always @(posedge clk) begin
		opcode_ri <= opcode_do;
		rs1_ri <= rs1_do;
		rs2_ri <= rs2_do;
		rd_ri <= rd_do;
		instr_ri <=	instr_do;
	end
	
	//Pipeline between rename and dispatch
	always @(posedge clk) begin
		opcode_dii_1 <= opcode_ro;
		ps1_dii_1 <= ps1_ro;
		ps2_dii_1 <= ps2_ro;
		pd_dii_1 <= pd_ro;
		instr_dii_1 <= instr_ro;
		
		opcode_dii_2 <= opcode_ro;
		ps1_dii_2 <= ps1_ro;
		ps2_dii_2 <= ps2_ro;
		pd_dii_2 <= pd_ro;
		instr_dii_2 <= instr_ro;
	end
	
endmodule


