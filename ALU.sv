module ALU(opcode, func3, func7, source_1, source_2, pd, result);

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
	
	input [6:0] opcode;
	input [2:0] func3;
	input [6:0] func7;
	input [31:0] source_1;
	input [31:0] source_2;
	input [5:0] pd;
	output reg [31:0] result;

	always@(*) begin
	
		if (pd == 0 && opcode != 7'b0100011) begin
			result = 0;
		end
		
		else begin
		
			case (opcode) 	// r-type
				7'b0110011: begin
					case (func7)		// 4 cases, and default case does nothing
						7'b0000000: begin
							if (func3 == 3'b000) begin							// ADD
								result = source_1 + source_2;
							end
							
							else if (func3 == 3'b100) begin 					// XOR
								result = source_1 ^ source_2;
							end
						end
						7'b0100000: begin
							if (func3 == 3'b000) begin							// SUB
								result = source_1 - source_2;
							end
							
							else if (func3 == 3'b101) begin					// SRA
								result = source_1 >>> source_2;
							end
						end

					endcase
				end
				
				7'b0010011: begin
					if (func3 == 3'b000) begin									// ADDI
						result = source_1 + source_2;
					end
					
					else if (func3 == 3'b111) begin							// ANDI
						result = source_1 & source_2;
					end
				end
				
				7'b0000011: begin		// LW
					result = source_1 + source_2;
				end
				
				7'b0100011: begin		// SW
					result = source_1 + source_2;
				end
	
			endcase
		end		
	end
	
endmodule