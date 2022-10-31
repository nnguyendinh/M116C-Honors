

`timescale 1ns/1ns // Tell Questa what time scale to run at

module file1(counter); //declare a new module named test with one port called counter
	
	output reg[3:0] counter = 0;	//declare counter as a 4-bit output register that initializes to 0
	
	reg [7:0] mem[127:0];
	reg[31:0] instr1;
	
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
	//ADD
	
		#100;			//delay for 100 ticks (delcared as 1ns at the top!)
		$stop;		//tell simulator to stop the simuation
	end
	
	
endmodule


