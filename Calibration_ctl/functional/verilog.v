//Verilog HDL for "FLASH_ADC", "Calibration_ctl" "functional"
`timescale 1ns/1ps



module Calibration_ctl #(parameter CODE=0) (cap_out, clk, b_left, b_right);
	output reg [4:0] b_left;
	output reg [4:0] b_right;

	input cap_out;
	input clk;


	initial begin
		b_left = 0; 
	    b_right = 0;
	    #1;
			
		if(CODE>0)
			b_right = CODE;
		else if(CODE < 0)
			b_left = -CODE;



    end



endmodule
