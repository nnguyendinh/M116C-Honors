

`timescale 1ns/1ns // Tell Questa what time scale to run at

module file1(counter); //declare a new module named test with one port called counter


	reg clk = 0;	// A clock signal that changes from 0 to 1 every 5 ticks
	always begin
		#10
		clk = ~clk;
	end

	
	output reg[3:0] counter = 0;	//i dont think we care about this it was jsut what i copied and pasted
	
	reg [7:0] mem[127:0];	// Instruction Memory I guess
	
	// General Pipeline:
	
	// Instruction Fetch -> Pipeline Buffer #1 -> Decode Stage -> Pipeline Buffer #2 -> Rename Stage
	
	// Pipeline Buffer #1
	reg[31:0] instruction1;
	reg[31:0] instruction2;
	
	// Decode Stage Regs

	reg[31:0] instr1;
	reg[6:0] optcode;
	reg[4:0] rs1;
	reg[4:0] rs2;
	reg[4:0] rd;
	
	
	initial begin 	//block that runs once at the beginning (Note, this only compiles in a testbench)
	
	
	$readmemb("test.txt", mem);

	//Instruction fetch
	//fetch 1 instruction
	//int i = 0;
	instr1 = {mem[0],mem[1],mem[2],mem[3]};

	$display("Instr: %b", instr1);

	

	//if next instruction is 0
	//stop fetching
	
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
	
	optcode = instr1[6:0];
	rs1 = instr1[19:15];
	rs2 = instr1[24:20];
	rd = instr1[11:7];
	

	$display("control: %b", control);
	$display("rs1: %b", rs1);
	$display("rs2: %b", rs2);
	$display("rd: %b", rd);
	
		#100;			//delay for 100 ticks (delcared as 1ns at the top!)
		$stop;		//tell simulator to stop the simuation
		
		
	//Rename stage
	//keep track of the free pool
	//how to represent the P-reg? actual pointers?
	
	//Algorithm: for each destination register, assign a P-reg from the free pool
	//Algorithm: for each source register, access RAT and pick the corresponding P-reg 
	
	//RAT has the registers initially assigned to some pointers
	//x1 --> p1
	//x2 --> p2
	//x3 --> p3
	//x4 --> p4
	//x5 --> p5
	
	//Free pool is initially:
	//p6
	//p7
	//p8
	//p9
	//p10
	
	//essentially: for the destination registers, pick the first free P-reg
	
	//for the source registers, grab the P-reg they're currently assigned to
	
	end
	
	
endmodule


