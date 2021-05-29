//Verilog HDL for "FLASH_ADC", "CMP_Offset_Finder" "functional"
`timescale 1ns/1ns




module CMP_Offset_Finder #(parameter CLK_Period_ns=2, code=0, bits=16, break=0) (
	input cmp_out,
	output wire [3:0] b_left,
	output wire [3:0] b_right,
	output reg [15:0] DAC_ctl,
    output reg clk
);



	reg [3:0] b_left_nxt, b_right_nxt;

//	assign b_left = {1'b1, b_left_nxt[2:0]};
//	assign b_right = {1'b1, b_right_nxt[2:0]};
	assign b_left =  b_left_nxt;
	assign b_right =  b_right_nxt;

	initial begin
	clk = 1;
	b_right_nxt = 0;
	b_left_nxt = 0;
	DAC_ctl = 0;
	

	if(code > 0) b_right_nxt = code;
	else b_left_nxt = -code;

	end

	always begin 
		#( CLK_Period_ns/2 ) clk = !clk;
	end

integer step = 0;
integer c = -15;
	
always begin
	
	
	//if(c > 0) b_right_nxt = c;
	//else b_left_nxt = -c;
	
	b_right_nxt = 4'b1111;
	b_left_nxt = 4'b1111;

	DAC_ctl = 0;

	


	@(negedge clk);
	@(negedge clk);
	step = bits-1;
	DAC_ctl[step] = 1;
	for(step = bits-2; step >= 0; step = step - 1) begin
		@(negedge clk);
		if(cmp_out == 1) DAC_ctl[step+1] = 0;
		DAC_ctl[step] = 1;
	end


	//c = c +  1;
end
	

endmodule

