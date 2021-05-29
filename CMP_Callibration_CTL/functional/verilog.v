//Verilog HDL for "FLASH_ADC", "Calibration_ctl" "functional"
`timescale 1ns/1ps



module CMP_Callibration_CTL  #(parameter CLK_Period=1, code = 0) (en, cmp_out, b_left, b_right, clk);
	output reg [4:0] b_left;
	output reg [4:0] b_right;

	input cmp_out;
	input en; 
	output reg clk;

	integer counter; 	// CMP output HIGH value counter
	integer samples;			// Ilo sampli countera
	integer last_diff; 
	integer diff;
	reg calibrated;

	localparam CAL_SAMPLES = 250;	//ilo sampli brana do kalibracji
	localparam ALLOWED_DIFF = 10;	//maksymalna rnica pomidzy wartoci zmierzon (counter) 
								// a wartoci oczekiwan (CAL_SAMPLES/2)


	//Variables 
	initial begin 
		calibrated = 0;
		samples = 0;
		counter = 0;
		last_diff = 2*CAL_SAMPLES; 
		diff = CAL_SAMPLES;
		clk = 1;
		b_left = 0;
		b_right = 0;
	end


   always begin 
		#CLK_Period;
		clk = ~clk; 
	end
	
integer i = 0;

	always @(posedge clk) begin 

	samples = samples + 1;

	if(cmp_out == 1) begin
		counter = counter + 1;
	end
	
i = i +1;
if(i > 25) $finish;
	

	if(en == 0) begin
		//b_right = (1 << 4);
		//b_left = (1 << 4);

		//if(code > 0) b_right = (1 << 4) + (code);
		//else b_left = (1 << 4) + (-code);
		b_right = 0;
		b_left = 0;

	if(code > 0) b_right = code;
	else b_left = -code;

	end
	

	else if(samples > CAL_SAMPLES & calibrated == 0) begin
		
		diff = counter - CAL_SAMPLES / 2;

		if (diff > 0) begin 
			if (diff <= last_diff) begin 
				b_left = b_left + 1;
			end
			else begin
				if(b_left > 0) 	b_left = b_left - 1;
			
				calibrated = 1;
			end
		end
		else if(diff < 0) begin 
			if (diff >= last_diff) begin 
				b_right = b_right + 1;
			end
			else begin
				
				if(b_right > 0) b_right = b_right - 1;
				calibrated = 1;
			end
		end
		else begin 
			calibrated = 1;
		end
		
		samples = 0;
		counter = 0;

	end

	

	end


endmodule
