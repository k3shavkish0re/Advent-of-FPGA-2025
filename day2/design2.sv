module puzzle2 #(
	parameter MAX_LENGTH = 10,	//In the input largest number has 10 digits
	parameter SUM_SIZE = 64,		//Large sum size value in binary. used to store the maximum sum in binary notation. largest input value is 33 bit binary long and there are 30 ranges. so need atleast 38 binary bits
	//parameter CNT_SIZE = 64,		//Large cnt size value. largest possible value of cnt is high
	parameter NUM_RANGES = 30
)(
	input 										clk,
	input 										rst_n,
	input 										vld,
	input [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] 	low,		//can exploit parallelism here too, can have all lows and highs
	input [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] 	high,		//input has to be bcd because division by 10 to detect individual digit is not synthesizable
	output [SUM_SIZE-1:0]						out			
);

logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] num_d;
logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] num_q;		//current number in BCD

logic [NUM_RANGES-1:0][SUM_SIZE-1:0] sum_d;		//sum in binary of each range
logic [NUM_RANGES-1:0][SUM_SIZE-1:0] sum_q;		

logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] direct_sum;
logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] correct_sum;
logic [NUM_RANGES-1:0][MAX_LENGTH-1:0] carry;

logic [NUM_RANGES-1:0][3:0] num_vld_digit;
logic [NUM_RANGES-1:0][5:0] val1;
logic [NUM_RANGES-1:0][5:0] val2;
logic [NUM_RANGES-1:0][5:0] val3;
logic [NUM_RANGES-1:0]		invalid_id;		//NOTE: invalid means not add. opposite of invalid in the question

logic [NUM_RANGES-1:0][SUM_SIZE-1:0] num_to_binary;


logic [NUM_RANGES-1:0] done_d;
logic [NUM_RANGES-1:0] done_q;
logic [4:0] cnt_d;
logic [4:0] cnt_q; 
logic [SUM_SIZE-1:0] all_range_sum_d;	//if its purely combinational remove this. combinational output of bcd_to_binary block
logic [SUM_SIZE-1:0] all_range_sum_q;



genvar i;
generate
    for (i = 0; i < NUM_RANGES; i++) begin
        bcd_to_binary #(
            .SIZE(MAX_LENGTH*4),
            .SUM_SIZE(SUM_SIZE)
        ) bcd_2_bin (
            .bcd    (num_q[i]),    
            .binary (num_to_binary[i])
        );
    end
endgenerate


always_comb begin
	for(int i=0;i<NUM_RANGES;i++) begin				//for all ranges
		direct_sum[i] = num_q[i] + {39'b0, 1'b1};	//not the final sum as this is bcd addition
		val1[i] = (num_vld_digit[i] << 1) - 1'b1; 	//2*num_vld_digit - 1, used for array indexing to compare
		val2[i] = (num_vld_digit[i] << 1); 			//2*num_vld_digit, used for array indexing to compare
		val3[i] = (num_vld_digit[i] << 2) - 1'b1; 	//4*num_vld_digit - 1, used for array indexing to compare
		
		//num_d starts from low till high
		num_d[i] = vld && (num_q[i] == 40'b0) ? low[i] : (vld && (num_q[i] != 40'b0) && (num_q[i] < high[i]) ? correct_sum[i] : num_q[i]); 
		
		//calculate sum_d
		//sum_d = binary addition of all 30 bcd_to_binary converted num_q;
		sum_d[i] = ((num_q[i] <= high[i]) && !invalid_id[i]) ? sum_q[i] + num_to_binary[i] : sum_q[i];
		done_d[i] = (num_q[i] == high[i]) && (high[i] > 40'b1);
	end
end

always_comb begin
    for (int k = 0; k < NUM_RANGES; k++) begin
        carry[k][0] = 1'b1;  // increment by +1 for lsb digit
        for (int i = 0; i < MAX_LENGTH; i++) begin
            logic [4:0] digit_sum;
            // add carry to the digit
            digit_sum = {1'b0, num_q[k][i*4 +: 4]} + carry[k][i];
            if (digit_sum > 5'd9) begin
                correct_sum[k][i*4 +: 4] = digit_sum - 5'd10;
                carry[k][i+1] = 1'b1;
            end
            else begin
                correct_sum[k][i*4 +: 4] = digit_sum[3:0];
                carry[k][i+1] = 1'b0;
            end
        end
    end
end


//logic to determine number of valid decimal digits
//midpoint generation of when to add
//priority logic, start from MSB
always_comb begin
	for(int k=0;k<NUM_RANGES;k++) begin
		if(num_q[k][39:36] & 4'b1111) num_vld_digit[k] = 4'd10;
		else if(num_q[k][35:32] & 4'b1111) num_vld_digit[k] = 4'd9;
		else if(num_q[k][31:28] & 4'b1111) num_vld_digit[k] = 4'd8;
		else if(num_q[k][27:24] & 4'b1111) num_vld_digit[k] = 4'd7;
		else if(num_q[k][23:20] & 4'b1111) num_vld_digit[k] = 4'd6;
		else if(num_q[k][19:16] & 4'b1111) num_vld_digit[k] = 4'd5;
		else if(num_q[k][15:12] & 4'b1111) num_vld_digit[k] = 4'd4;
		else if(num_q[k][11:8] & 4'b1111) num_vld_digit[k] = 4'd3;
		else if(num_q[k][7:4] & 4'b1111) num_vld_digit[k] = 4'd2;
		else if(num_q[k][3:0] & 4'b1111) num_vld_digit[k] = 4'd1;
		else num_vld_digit[k] = 4'd0;
	end
end



logic [NUM_RANGES-1:0][3:0] d1;
logic [NUM_RANGES-1:0][3:0] d2;
logic [NUM_RANGES-1:0][3:0] d3;
logic [NUM_RANGES-1:0][3:0] d4;
logic [NUM_RANGES-1:0][3:0] d5;
logic [NUM_RANGES-1:0][3:0] d6;
logic [NUM_RANGES-1:0][3:0] d7;
logic [NUM_RANGES-1:0][3:0] d8;
logic [NUM_RANGES-1:0][3:0] d9;
logic [NUM_RANGES-1:0][3:0] d10;

logic [NUM_RANGES-1:0] temp;
logic [NUM_RANGES-1:0] temp2;


always_comb begin
	for(int k=0;k<NUM_RANGES;k++) begin
		d1[k] = num_q[k][0  +: 4];
		d2[k] = num_q[k][4  +: 4];
		d3[k] = num_q[k][8  +: 4];
		d4[k] = num_q[k][12 +: 4];
		d5[k] = num_q[k][16 +: 4];
		d6[k] = num_q[k][20  +: 4];
		d7[k] = num_q[k][24  +: 4];
		d8[k] = num_q[k][28  +: 4];
		d9[k] = num_q[k][32 +: 4];
		d10[k] = num_q[k][36 +: 4];
		temp[k] = (({d9[k],d8[k],d7[k]} == {d6[k],d5[k],d4[k]}) && ({d6[k],d5[k],d4[k]} == {d3[k],d2[k],d1[k]}));
	end
end



//flag generation of when to add, keep it purely combinational
always_comb begin
	for(int k=0;k<NUM_RANGES;k++) begin
			case(num_vld_digit[k])			//slicing index must be constant
				4'd0: invalid_id[k] = 1'b1;		
				4'd1: invalid_id[k] = 1'b1;
				4'd2: begin
					if(num_q[k][0+:4] == num_q[k][4+:4]) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd3: begin
					if((d3[k] == d2[k]) && (d2[k] == d1[k])) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd4: begin
					if(num_q[k][0+:8] == num_q[k][8+:8]) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd5: begin
					if((d1[k] == d2[k]) && (d2[k] == d3[k]) && (d3[k] == d4[k]) && (d4[k] == d5[k])) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd6: begin
					if((num_q[k][0+:12] == num_q[k][12+:12]) || (({d6[k],d5[k]} == {d4[k], d3[k]}) && ({d4[k],d3[k]} == {d2[k],d1[k]}))) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd7: begin
					if((d1[k] == d2[k]) && (d2[k] == d3[k]) && (d3[k] == d4[k]) && (d4[k] == d5[k]) && (d5[k] == d6[k]) && (d6[k] == d7[k])) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd8: begin
					if((num_q[k][0+:16] == num_q[k][16+:16]) || (({d8[k],d7[k]} == {d6[k], d5[k]}) && ({d6[k],d5[k]} == {d4[k], d3[k]}) && ({d4[k],d3[k]} == {d2[k],d1[k]}))) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd9: begin
					if (temp[k]) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				4'd10: begin
					if((num_q[k][0+:20] == num_q[k][20+:20]) || (({d10[k],d9[k]} == {d8[k], d7[k]}) && ({d8[k],d7[k]} == {d6[k], d5[k]}) && ({d6[k],d5[k]} == {d4[k], d3[k]}) && ({d4[k],d3[k]} == {d2[k],d1[k]}))) invalid_id[k] = 1'b0;
					else invalid_id[k] = 1'b1;
				end
				default invalid_id[k] = 1'b1;
			endcase
	end
end


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		num_q <= '0;
		sum_q <= '0;
		done_q <= '0;
		cnt_q <= '0;
		all_range_sum_q <= '0;
	end
    else begin
		num_q <= num_d;
		sum_q <= sum_d;
		done_q <= done_d;
		cnt_q <= cnt_d;
		all_range_sum_q <= all_range_sum_d;
	end
end

assign cnt_d = (&done_q) && (cnt_q < 5'd30) ? cnt_q + 1'b1 : cnt_q;

//need to sum all sum_q, start a counter when &done_q asserts. count till 30
assign all_range_sum_d = (&done_q) && (cnt_q < 5'd30) ? all_range_sum_q + sum_q[cnt_q] : all_range_sum_q; 

assign out = all_range_sum_q;

endmodule


//bcd represenation to binary representation
module bcd_to_binary #(
	parameter SIZE = 40, //MAX_LENGTH*4
	parameter SUM_SIZE = 50
)(
	input [SIZE-1:0] bcd,
	output [SUM_SIZE-1:0] binary		//size in binary = size in bcd/4
);

assign binary = bcd[39:36]*50'd1000000000 + bcd[35:32]*50'd100000000 + bcd[31:28]*50'd10000000 + bcd[27:24]*50'd1000000 + bcd[23:20]*50'd100000 + bcd[19:16]*50'd10000 + bcd[15:12]*50'd1000 + bcd[11:8]*50'd100 + bcd[7:4]*50'd10 + bcd[3:0];

endmodule