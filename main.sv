
//`include "M116C-Honors/modules.sv"
`timescale 1ns/1ns // Tell Questa what time scale to run at

package p;
	reg [5:0] rat[31:0]; //RAT - maps 32 architectural registers to physical register
	reg [8:0] p_regs[63:0]; //kind-of free pool --> contains value that each phy reg points to, and a beginning flag for if there is a current value attached to the phy reg
endpackage
	

module main(counter); //declare a new module named test with one port called counter


	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10
		clk = ~clk;
	end

	
	output reg[3:0] counter = 0;	//i dont think we care about this it was jsut what i copied and pasted
	
	import p::rat;
	import p::p_regs;
	
	reg [7:0] mem[127:0];	// Instruction Memory I guess
	
	// General Pipeline:
	
	// Pipeline Buffer #1
	reg[31:0] instruction1;
	reg[31:0] instruction2;
	
	// Decode Stage Regs

	reg[31:0] instr1;
	reg[6:0] opcode;
	reg[4:0] rs1;
	reg[4:0] rs2;
	reg[4:0] rd;
	reg[31:0] instr_d;
	reg[31:0] instr_;
	reg [5:0] ps1;			// Physical registers are 6 bit because we have 128 of them
	reg [5:0] ps2;
	reg [5:0] pd;
	reg [6:0] opcode_;
	
	//Decode stage
	decode dec(instr1, opcode, rs1, rs2, rd, instr_d);
	
	//Rename stage
	rename ren(opcode, rs1, rs2, rd, instr_d, opcode_, ps1, ps2, pd, instr_);
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
	//loop so that all rat values are assigned to p1 to p32 and first 32 p_regs are also all 1
	integer n;

	for(n = 0; n < 32; n = n + 1) begin
		rat[n] = n;
		p_regs[n][0] = 1;
	end 

	
	
	$readmemb("C:/Users/Nathan Nguyendinh/Documents/Quartus_Projects/M116C/OOP_RISC-V/src/test.txt", mem);

	instr1 = {mem[0],mem[1],mem[2],mem[3]};

	$display("Instr: %b", instr1);

	#100;			//delay for 100 ticks (delcared as 1ns at the top!)
	
	//Decode stage
	//ADD, SUB, ADDI, XOR, ANDI, SRA, LW, SW
	//ADD: 0000000 rs2 rs1 000 rd 0110011
	//SUB: 0100000 rs2 rs1 000 rd 0110011
	//ADDI: imm[11:0] rs1 000 rd 0010011
	//XOR: 0000000 rs2 rs1 100 rd 0110011
	//ANDI: imm[11:0] rs1 111 rd 0010011
	//SRA: 0100000 rs2 rs1 101 rd 0110011
	//LW: imm[11;0] rs1 010 rd 0000011
	//SW: imm[11:5] rs2 rs1 010 imm[4:0] 0100011

	$display("opcode: %b", opcode);
	$display("rs1: %b", rs1);
	$display("rs2: %b", rs2);
	$display("rd: %b", rd);
	
	$display("ps1: %b", ps1);
	$display("ps2: %b", ps2);
	$display("pd: %b", pd);
	
	#100;			//delay for 100 ticks (delcared as 1ns at the top!)
	$stop;		//tell simulator to stop the simuation
	
	
	//Dispatch stage
	//place instruction in reservation station (RS) --> mark as used, grab which operation, mark which FU
	//Re-order buffer (ROB) --> increase ROB index by 1
	//grab register values --> grab register values from the pointers into temp registers
	//Mark sr regs as ready/not ready --> have "sr1 ready" and "sr2 ready" flags for each instruction
	//How to tell if sr regs are ready or not?
	
	//Issue stage
	//Excecute only if source registers and FU are all ready --> check the flags
	//Execute based on what OP the instruction is --> might have to put extra consideration for lw and sw
	//Mark FU being used as not ready
	
	
	//Complete stage
	//copy result to ROB and mark as complete --> Have an array for ROB with the instruction and complete flag
	//Mark FU that was being used as ready again
	//Mark registers being used as ready
	
	
	//Retire stage 
	//Overwrite reg file with result from execution
	//erase instruction from RS?
	//retire instruction at top of ROB --> ?
	//release "old" regs to architectural reg mapping --> back into RAT and free pool?
	
	end
	
	
endmodule


