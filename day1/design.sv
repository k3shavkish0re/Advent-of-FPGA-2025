module puzzle1 #(
	parameter PWD_SIZE = 15
)
(
    input clk,
    input rst_n,   // active-low reset
	input vld,
    input dir,
    input [9:0] steps,
	input read_en, 
	output [PWD_SIZE-1:0] pwd
);

logic [9:0] actual_steps_d;	//keeping extra bit to prevent loss of data
logic [9:0] actual_steps_q;	//keeping extra bit to prevent loss of data

logic [7:0] position_d;		//keeping extra bit to prevent loss of data
logic [7:0] position_q;		//keeping extra bit to prevent loss of data

logic [PWD_SIZE-1:0] cnt_d;			//size depends on the number of instructions
logic [PWD_SIZE-1:0] cnt_q;

logic [7:0] sum_position_actual_steps; //extra bit to prevent overflow

logic vld_q;
logic vld_qq;
logic dir_q;

assign sum_position_actual_steps = actual_steps_q + position_q;

assign cnt_d = vld_qq && (position_q == '0) ? cnt_q + 1 : cnt_q;

always_comb begin
	if(!vld_q) position_d = position_q;
	//Left
	else if(vld_q & !dir_q) begin
		if(actual_steps_q[7:0] > position_q) position_d = 8'd100 - actual_steps_q + position_q;
		else position_d = position_q - actual_steps_q;
	end
	//Right
	else begin
		if(sum_position_actual_steps > 7'd99) position_d = actual_steps_q - 8'd100 + position_q;
		else position_d = sum_position_actual_steps;
	end
end


always_comb begin
	if(vld) begin
		if(steps < 10'd100) actual_steps_d = steps;
		else if (steps >= 10'd100 && steps < 10'd200) actual_steps_d = steps - 10'd100; 
		else if (steps >= 10'd200 && steps < 10'd300) actual_steps_d = steps - 10'd200;
		else if (steps >= 10'd300 && steps < 10'd400) actual_steps_d = steps - 10'd300;
		else if (steps >= 10'd400 && steps < 10'd500) actual_steps_d = steps - 10'd400;
		else if (steps >= 10'd500 && steps < 10'd600) actual_steps_d = steps - 10'd500;
		else if (steps >= 10'd600 && steps < 10'd700) actual_steps_d = steps - 10'd600;
		else if (steps >= 10'd700 && steps < 10'd800) actual_steps_d = steps - 10'd700;
		else if (steps >= 10'd800 && steps < 10'd900) actual_steps_d = steps - 10'd800;
		else if (steps >= 10'd900 && steps < 10'd1000) actual_steps_d = steps - 10'd900;
		else actual_steps_d = steps - 10'd1000;
	end
	else actual_steps_d = '0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt_q      <= '0;
        position_q <= 8'd50;
		actual_steps_q <= '0;
		vld_q          <= '0;
		vld_qq         <= '0;
		dir_q          <= '0;
	end
    else begin
		cnt_q      <= cnt_d;
        position_q <= position_d;
		actual_steps_q <= actual_steps_d;
		vld_q          <= vld;
		vld_qq         <= vld_q;
		dir_q          <= dir;
	end
end

assign pwd = {PWD_SIZE{read_en}} & cnt_q;

endmodule