`timescale 1 ns / 1 ns 

module complete(en_flag_i, FU_result, rob_row, en_flag_o);

import p::p_reg_R;
import p::rob;
import p::rs;

input reg en_flag_i;
input reg [31:0] FU_result;
input reg rob_row; //index of ROB row being changed
output reg en_flag_o;

reg [5:0] dest_index;
integer n;

always@(*) begin

if(en_flag_i == 1) begin
	dest_index = rob[rob_row].phy_reg; //just so you don't have to keep calling the rob
	
	//store old result
	rob[rob_row].old_result = rob[rob_row].result;
	
	//store new result from ALU
	rob[rob_row].result = FU_result;
	
	//mark destination register used as ready
	p_reg_R[rob[rob_row].phy_reg] = 1;
	
	//mark FU as ready
	
	
	//go through reservation station and mark source registers as ready
	for(n = 0; n < 16; n = n + 1) begin
		if (rs[n].src_reg_1 == dest_index) begin
			rs[n].src_data_1 = FU_result;
			rs[n].src1_ready = 1;
		end
		
		if (rs[n].src_reg_2 == dest_index) begin
			rs[n].src_data_2 = FU_result;
			rs[n].src2_ready = 1;
		end
	end
	
end

else begin
	

end

	en_flag_o = en_flag_i;
end

endmodule