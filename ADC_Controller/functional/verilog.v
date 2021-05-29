//Verilog HDL for "FLASH_ADC", "CMP_Offset_Finder" "functional"
`timescale 1ns/1ps




module ADC_Controller #(parameter CLK_Period_ns=2, code=0, bits=16) (
	output reg clk,
	input wire [30:0] Q,
	output reg [15:0] DAC_ctl,
	output wire [247:0] cal,
	output reg rdy
);

	reg [255:0] callib;

	assign cal[127:0] = callib[127:0];
	assign cal[247:128] = ~callib[247:128];

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

localparam START = 0, STOP = 31;

integer state_prev = 0; 
integer break = 0;
integer ctr; 
reg [7:0] tmp;

initial begin 
	callib = 0;
	
	comp = 0;
	for(comp = START; comp < STOP; comp = comp + 1) begin
		@(posedge clk);
		rdy = 0;
		step = bits-1;
		DAC_ctl = 0;
		@(posedge clk);
		DAC_ctl[step] = 1;

		for(step = bits-2; step >= 0; step = step - 1) begin
			@(posedge clk);
			if(Q[comp] == 1) DAC_ctl[step+1] = 0;
			DAC_ctl[step] = 1;
		end
		rdy = 1;
	end

	DAC_ctl = 0;

	for(comp  = START; comp < STOP; comp = comp + 1) begin
		@(posedge clk);
		tmp = 0;
		rdy = 0;
		ctr = 0;
		DAC_ctl = (218.75+18.75*comp)/0.01678466;  
	
		@(posedge clk);
		state_prev = Q[comp];
		break = 0;

		while(!break && !(ctr >= 15)) begin
			ctr = ctr + 1;
			@(posedge clk);
			if(Q[comp] != state_prev) break = 1;
			else begin
				if(Q[comp] == 1) tmp = ctr << 4;
				else tmp = ctr;
			end
			
			callib[(comp+1)*8 - 1 -:8] = tmp;
			
			
		end
		$display("%d", tmp);

	end


	for(comp =  START; comp < STOP; comp = comp + 1) begin
		@(posedge clk);
		rdy = 0;
		step = bits-1;
		DAC_ctl = 0;
		@(posedge clk);
		DAC_ctl[step] = 1;

		for(step = bits-2; step >= 0; step = step - 1) begin
			@(posedge clk);
			if(Q[comp] == 1) DAC_ctl[step+1] = 0;
			DAC_ctl[step] = 1;
		end
		rdy = 1;
	end
end
	

endmodule


