//Verilog HDL for "FLASH_ADC", "CMP_Offset_Finder" "functional"
`timescale 1ns/1ps




module FLASH_Controller_v2_2 #(parameter CLK_Period_ns=2, code=0, bits=16) (
	input wire [31:0] Q,
	output wire [127:0] cal_bot,
	output wire [127:0] cal_top,
	output reg [15:0] DAC_ctl,

    output reg clk,
	output reg rdy
);

	reg [255:0] callib;

	assign cal_bot = callib[127:0];
	assign cal_top = callib[255:128];

	initial begin
		clk = 1;
		DAC_ctl = 0;
		rdy = 0;
		callib = 0;
	end

	always begin 
		#( CLK_Period_ns/2 ) clk = !clk;
	end

integer step = 0;
integer comp = 0;


//initial begin
//
//	for(comp = 0; comp < 32; comp = comp + 1) begin
//		@(negedge clk);
//		rdy = 0;
//		step = bits-1;
//		DAC_ctl = 0;
//		@(negedge clk);
//		DAC_ctl[step] = 1;
//
//		for(step = bits-2; step >= 0; step = step - 1) begin
//			@(negedge clk);
//			if(Q[comp] == 1) DAC_ctl[step+1] = 0;
//			DAC_ctl[step] = 1;
//		end
//		rdy = 1;
//	end

//end


localparam START = 16, STOP = 32;

integer state_prev = 0; 
integer break = 0;
integer ctr; 
reg [7:0] tmp;

initial begin 
comp = 0;
	for(comp = START; comp < STOP; comp = comp + 1) begin
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

	DAC_ctl = 0;

	for(comp  = START; comp < STOP; comp = comp + 1) begin
		@(negedge clk);
		tmp = 0;
		rdy = 0;
		ctr = 0;
		DAC_ctl = (218.75+18.75*comp)/0.01678466;  
	
		@(negedge clk);
		state_prev = Q[comp];
		break = 0;

		while(!break && !(ctr >= 15)) begin
			ctr = ctr + 1;
			@(negedge clk);
			if(Q[comp] != state_prev) break = 1;
			else begin
				if(Q[comp] == 1) tmp = ctr << 4;
				else tmp = ctr;
			end
			
			callib[(comp+1)*8 - 1 -:8] = tmp;
			
			
		end
		$display("%d", tmp);
		//callib[(comp+1)*7 -: 7] = tmp;
	end


	for(comp =  START; comp < STOP; comp = comp + 1) begin
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


