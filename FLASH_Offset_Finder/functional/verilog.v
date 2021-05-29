//Verilog HDL for "FLASH_ADC", "CMP_Offset_Finder" "functional"
`timescale 1ns/1ps




module FLASH_Offset_Finder #(parameter CLK_Period_ns=2, code=0, bits=16) (
	input wire [31:0] Q,
	output wire [3:0] b_left,
	output wire [3:0] b_right,
	output reg [15:0] DAC_ctl,
    output reg clk,
	output reg rdy
);



	reg [3:0] b_left_nxt, b_right_nxt;

	assign b_left = !b_left_nxt;
	assign b_right = !b_right_nxt;


	initial begin
	clk = 1;
	b_right_nxt = 0;
	b_left_nxt = 0;
	DAC_ctl = 0;
	rdy = 0;
	

	if(code > 0) b_right_nxt = code;
	else b_left_nxt = -code;

	end

	always begin 
		#( CLK_Period_ns/2 ) clk = !clk;
	end

integer step = 0;
integer comp = 0;



initial begin

	for(comp = 0; comp < 32; comp = comp + 1) begin

		@(negedge clk);
		rdy = 0;
		step = bits-1;
		DAC_ctl = 0;
		@(negedge clk);
		DAC_ctl[step] = 1;

		for(step = bits-2; step >= 0; step = step - 1) begin
			@(negedge clk);
			if(Q[comp] == 1) DAC_ctl[step+1] = 0;
			DAC_ctl[step] = 1;
		end
		rdy = 1;
	end

end
	

endmodule

