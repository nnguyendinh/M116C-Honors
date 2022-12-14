`timescale 1 ns / 1 ns 

/*
module ALU(instr, opcode, func3, func7, ps1, ps2, pd);

	//based on op code, assign each variable
	//ADD, SUB, ADDI, XOR, ANDI, SRA
	
	//ADD: 0000000 rs2 rs1 000 rd 			0110011
	//SUB: 0100000 rs2 rs1 000 rd 			0110011
	//ADDI: imm[11:0] rs1 000 rd 				0010011	immediate
	//XOR: 0000000 rs2 rs1 100 rd 			0110011
	//ANDI: imm[11:0] rs1 111 rd 				0010011	immediate
	//SRA: 0100000 rs2 rs1 101 rd 			0110011	
	//LW: imm[11;0] rs1 010 rd 				0000011	immediate
	//SW: imm[11:5] rs2 rs1 010 imm[4:0] 	0100011	immediate
	
	input [31:0] instr;
	input [6:0] opcode;
	input [2:0] func3;
	input [6:0] func7;
	input [5:0] ps1;
	input [5:0] ps2;
	input [5:0] pd;
	
	reg [11:0] imm = instr[31:20];
	
	
	always@(*) begin
	
		case (opcode) 	// r-type
			7'b0110011: begin
				case (func7)		// 4 cases, and default case does nothing
					7'b0000000: begin
						if (func3 == 3'b000) begin							// ADD
							p_regs[pd] = p_regs[ps1] + p_regs[ps2];
						end
						else if (func3 == 3'b100) begin 					// XOR
							p_regs[pd] = p_regs[ps1] + p_regs[ps2];
						end
					end
					7'b0100000: begin
						if (func3 == 3'b000) begin							// SUB
							p_regs[pd] = p_regs[ps1] - p_regs[ps2];
						end
						else if (func3 == 3'b101) begin					// SRA
							p_regs[pd] = p_regs[ps1] >>> p_regs[ps2];
						end
					end
				endcase
			7'b0010011: begin
				if (func3 == 3'b000) begin									// ADDI
					p_regs[pd] = p_regs[ps1] + imm;
				end
				else if (func3 == 3'b111) begin							// ANDI
					p_regs[pd] = p_regs[ps1] & imm;
				end
			end
		endcase
		
		if (pd == 0) begin
			p_regs[pd] = 0;
		end
	
	end
	
endmodule
*/				
 


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
