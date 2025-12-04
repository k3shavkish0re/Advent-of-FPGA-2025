module puzzle2 #(
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

logic [3:0] increment_val_d;
logic [3:0] increment_val_q;

logic [3:0] final_increment_val_d;
logic [3:0] final_increment_val_q;

assign sum_position_actual_steps = actual_steps_q + position_q;

assign cnt_d = vld_qq ? cnt_q + final_increment_val_q : cnt_q;	//REPLACE 1 with new increment val

always_comb begin
	if(!vld_q) begin
		position_d = position_q;
		final_increment_val_d = '0;
	end
	//Left
	else if(vld_q & !dir_q) begin
		if(actual_steps_q[7:0] > position_q) begin		
			position_d = 8'd100 - actual_steps_q + position_q;
			final_increment_val_d = (position_q == '0) ? increment_val_q : increment_val_q + 1'd1;	//if position_q is at 0, it gets counted twice.
		end
		else if(actual_steps_q[7:0] == position_q) begin
			position_d = position_q - actual_steps_q;
			final_increment_val_d = increment_val_q + 1'd1;
		end
		else begin
			position_d = position_q - actual_steps_q;
			final_increment_val_d = increment_val_q;
		end
	end
	//Right
	else begin
		if(sum_position_actual_steps > 7'd99) begin
			position_d = actual_steps_q - 8'd100 + position_q;
			final_increment_val_d = increment_val_q + 1'd1;
		end
		else begin
			position_d = sum_position_actual_steps;
			final_increment_val_d = increment_val_q;
		end
	end
end

//can be replaced with modulo logic
always_comb begin
	if(vld) begin
		if(steps < 10'd100) begin 
			actual_steps_d = steps;
			increment_val_d = 4'd0;
		end
		else if (steps >= 10'd100 && steps < 10'd200) begin
			actual_steps_d = steps - 10'd100;
			increment_val_d = 4'd1;
		end
		else if (steps >= 10'd200 && steps < 10'd300) begin
			actual_steps_d = steps - 10'd200;
			increment_val_d = 4'd2;
		end
		else if (steps >= 10'd300 && steps < 10'd400) begin
			actual_steps_d = steps - 10'd300;
			increment_val_d = 4'd3;
		end
		else if (steps >= 10'd400 && steps < 10'd500) begin
			actual_steps_d = steps - 10'd400;
			increment_val_d = 4'd4;
		end
		else if (steps >= 10'd500 && steps < 10'd600) begin
			actual_steps_d = steps - 10'd500;
			increment_val_d = 4'd5;
		end
		else if (steps >= 10'd600 && steps < 10'd700) begin
			actual_steps_d = steps - 10'd600;
			increment_val_d = 4'd6;
		end
		else if (steps >= 10'd700 && steps < 10'd800) begin
			actual_steps_d = steps - 10'd700;
			increment_val_d = 4'd7;
		end
		else if (steps >= 10'd800 && steps < 10'd900) begin
			actual_steps_d = steps - 10'd800;
			increment_val_d = 4'd8;
		end
		else if (steps >= 10'd900 && steps < 10'd1000) begin
			actual_steps_d = steps - 10'd900;
			increment_val_d = 4'd9;
		end
		else begin
			actual_steps_d = steps - 10'd1000;
			increment_val_d = 4'd10;
		end
	end
	else begin
		actual_steps_d = '0;
		increment_val_d = '0;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt_q      <= '0;
        position_q <= 8'd50;
		actual_steps_q <= '0;
		vld_q          <= '0;
		vld_qq         <= '0;
		dir_q          <= '0;
		increment_val_q <= '0;
		final_increment_val_q <= '0;
	end
    else begin
		cnt_q      <= cnt_d;
        position_q <= position_d;
		actual_steps_q <= actual_steps_d;
		vld_q          <= vld;
		vld_qq         <= vld_q;
		dir_q          <= dir;
		increment_val_q <= increment_val_d;
		final_increment_val_q <= final_increment_val_d;
	end
end

assign pwd = {PWD_SIZE{read_en}} & cnt_q;

endmodule