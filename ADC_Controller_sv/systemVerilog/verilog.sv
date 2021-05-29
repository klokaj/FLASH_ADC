//systemVerilog HDL for "FLASH_ADC", "ADC_Controller_sv" "systemVerilog"


module ADC_Controller_sv #(parameter int CLK_Period_ns = 2, string corner_name = "def", int Temp_deg_C = -1)  (
	output reg clk,
	input wire [30:0] Q,
	output reg [15:0] DAC_ctl,
	output reg [247:0] cal
 );

	//localparam temp = 27;
//localparam corner_name = "def";

	initial begin
		clk = 1;
		DAC_ctl = 0;
	end

	always begin 
		#( CLK_Period_ns/2 ) clk = !clk;
	end


integer comp = 0;
localparam START = 0;
localparam STOP = 31;
integer step = 0;

localparam TH0 = 0.21875;
localparam LSB = 0.01875;

typedef enum {PMOS, NMOS} CmpType;
typedef enum {E_OK, E_NOT_OK} Std_ReturnType;

function real rabs(real a);
	if(a >= 0) return a;
	else return -a;
endfunction


class Comparator;
	int nr;
	int gen;
	real th_ideal;
	real th_meas_pre;
	real th_meas_after;

	reg [7:0] callib_data;
	CmpType typ;

	function new(int number, int generation = 0);
		nr = number;
		gen = generation; 
		th_ideal = TH0 + nr*LSB;
		if(nr >15) typ = NMOS;
		else typ = PMOS;

		this.init_calibration();
	endfunction

	task find_th(output real th, input int res = 16);
		DAC_ctl = 0;
		@(posedge clk)
		DAC_ctl[15] = 1;
		for(int i = 14; i >= (16-res); i --) begin
			@(posedge clk);
			if(Q[nr] == 1) DAC_ctl[i+1] = 0;
			DAC_ctl[i] = 1; 	
		end
		@(posedge clk);
		if(Q[nr] == 1) DAC_ctl[16-res] = 0;
		th = (DAC_ctl*1.1/65536.0);
	endtask

	virtual function string convert2string();
		real INL_pre;
		real INL_after;
		string s;
		INL_pre = (th_meas_pre-th_ideal)/LSB;
		INL_after = (th_meas_after-th_ideal)/LSB;
		$sformat(s, "CMP_NR %d, %f, %f, %f, %f, '%b'", nr, th_meas_pre, th_meas_after, INL_pre, INL_after, callib_data);
		return s;
	endfunction

	function void updata_callib_reg();
		if(typ == PMOS) cal[8*( 1 + nr)-1 -: 8] = callib_data;
		else if(typ == NMOS) cal[8*( 1 + nr)-1 -: 8] = ~callib_data;
	endfunction

	function Std_ReturnType increase_th();
		if(callib_data[3:0] == 4'b1111) return E_NOT_OK;
		callib_data[3:0] = callib_data[3:0] + 1;	
		this.updata_callib_reg();
		return E_OK;

	endfunction
	
	function Std_ReturnType decrease_th();
		if(callib_data[7:4] == 4'b1111) return E_NOT_OK;
		callib_data[7:4]  = callib_data[7:4] + 1;	
		this.updata_callib_reg();
		return E_OK;
	endfunction


	function void callib_step_back();
		$display("callib step back");
		if(callib_data != 0) begin 
			if(callib_data[7:4] != 0) callib_data[7:4] = callib_data[7:4] - 1;
			else if (callib_data[3:0] != 0) callib_data[3:0] = callib_data[3:0] - 1;

			$display("stepping back, data: %B", callib_data);
		end

		this.updata_callib_reg();

	endfunction

	function real set_callib_voltage(int res);
		reg [15:0] DAC_ctl_new = 0;
		real voltage; 
		DAC_ctl = th_ideal/(1.1/(1 << res));
		DAC_ctl = DAC_ctl << (16-res);
		voltage = DAC_ctl * 0.00001678466; // DAC ctl * 16b 1.1V range DAC lsb
		return voltage;
	endfunction

	function void init_calibration();
		callib_data = 0;
		this.updata_callib_reg();
	endfunction


	task callibrate(output real th, input int res = 10);
		real th_tmp = 0;
		reg [7:0] cal = 0;
		real set_voltage;
		integer dir; 
		Std_ReturnType retv = E_OK;
		
		this.init_calibration();
	
		set_voltage = this.set_callib_voltage(res);
		$display("CMP %0d callibrating, set voltage: %f", this.nr, set_voltage);
	
		@(posedge clk);
		dir = Q[nr];
		while(retv == E_OK) begin
			@(posedge clk);
			if(Q[nr] != dir) break;			
			if(dir == 1) retv = this.decrease_th();
			else retv = this.increase_th();
		end

	
		

		$display("Finding best callibration data");
		this.find_th(th_meas_after, 16);
		$display("Threshold: %f, callib_data: %b", th_meas_after, callib_data);
		this.callib_step_back();
		this.find_th(th_tmp, 16);
		$display("Threshold: %f, callib_data: %b", th_tmp, callib_data);
		$display("ERR1: %f, ERR2: %f", rabs(th_tmp - set_voltage),  rabs(th_meas_after - set_voltage));
		if(rabs(th_tmp - set_voltage) < rabs(th_meas_after - set_voltage)) begin
			th_meas_after = th_tmp;
		end
		else begin
			if(dir == 1) retv = this.decrease_th();
			else retv = this.increase_th();
		end
	endtask 

endclass 





Comparator cmp_list[31];

localparam RES = 8;
localparam PRECISION_16B = 16;




function int T2B_Encoder();
	bit b0, b1, b2, b3, b4;
	int s1, s2, s3, s4;
	int shift;
	int val;

	$display("*********************************************");
	$display("input voltage: %f", DAC_ctl * 0.00001678466);
	shift = 15;
	b4 = Q[shift];
	$display("B4: %b, shift: %0d", b4, shift);
	shift = shift - 8 + (b4 << 4);
	b3 = Q[shift];
	$display("B3: %b, shift: %0d", b3, shift);
	shift = shift - 4 + (b3 << 3);
	b2 = Q[shift];
	$display("B2: %b, shift: %0d", b2, shift);
	shift = shift -2 + (b2 << 2);
	b1 = Q[shift];
	$display("B1: %b, shift: %0d", b1, shift);
	shift = shift -1 + (b1 << 1);
	b0 = Q[shift];
	$display("B0: %b, shift: %0d", b0, shift);
	
	// $display("cmp_output: %b", Q[30:0]);
	// $display("output code: %b", val);
	// $display("%b%b%b%b%b", b4, b3, b2, b1, b0);
	// $display(" %d, %d, %d, %d", s4, s3, s2, s1);

	val = (b4 << 4) + (b3 << 3) + (b2 << 2) + (b1 << 1) + b0;
	$display("Output code: %0d", val); 

	return  val;
endfunction 



function void init_cmp_list();
	cmp_list[0] = new(15, 0);

	cmp_list[1] = new(7, 1);
	cmp_list[2] = new(23, 1);

	cmp_list[3] = new(3, 2);
	cmp_list[4] = new(11, 2);
	cmp_list[5] = new(19, 2);
	cmp_list[6] = new(27, 2);

	cmp_list[7] = new(1, 3);
	cmp_list[8] = new(6, 3);
	cmp_list[9] = new(9, 3);
	cmp_list[10] = new(13, 3);
	cmp_list[11] = new(17, 3);
	cmp_list[12] = new(21, 3);
	cmp_list[13] = new(25, 3);
	cmp_list[14] = new(29, 3);

	cmp_list[15] = new(0, 3);
	cmp_list[16] = new(16, 3);
	cmp_list[17] = new(8, 3);
	cmp_list[18] = new(24, 3);
	cmp_list[19] = new(4, 3);
	cmp_list[20] = new(20, 3);
	cmp_list[21] = new(12, 3);
	cmp_list[22] = new(28, 3);
	cmp_list[23] = new(2, 3);
	cmp_list[24] = new(18, 3);
	cmp_list[25] = new(10, 3);
	cmp_list[26] = new(26, 3);
	cmp_list[27] = new(6, 3);
	cmp_list[28] = new(22, 3);
	cmp_list[29] = new(14, 3);
	cmp_list[30] = new(30, 3);
endfunction 



initial begin 
	real th;
	real th_callib;
	int fd;
	string s;
	string filepath;


	for (int i = 0; i < 31; i++)begin
		@(posedge clk)
		DAC_ctl = (0.205 + i*0.01875)/(1.1/(1 << 16));
		@(posedge clk)
		@(posedge clk)
		T2B_Encoder();
		//$display("Output code: %d", T2B_Encoder());
	end
	

	$finish();

	$display(corner_name);
	$display("%d", Temp_deg_C);
	//$display(cds_globals);
	$sformat(filepath, "/home/student/klokaj/ADC_Meas/Meas3_%s_%0dC.txt", corner_name, Temp_deg_C);

	init_cmp_list();
	fd = $fopen(filepath, "w+");


	foreach(cmp_list[i]) begin
		cmp_list[i].find_th(th, PRECISION_16B);
		cmp_list[i].th_meas_pre = th;
		cmp_list[i].callibrate(th_callib);
		$display("Output code: %d", T2B_Encoder());
		s = cmp_list[i].convert2string();
		$fdisplay(fd, s);
		$display(s);
	end
	$fclose(fd);



	$finish;
end

endmodule


