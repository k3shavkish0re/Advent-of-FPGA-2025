module puzzle1 #(
	parameter NUM_BANKS = 200,
	parameter SIZE_BANK = 128
)(
	input clk,
	input rst_n,
	input bank_en,
	input [NUM_BANKS-1:0][3:0] val,				//bus data which sends one element of each bank simultaneously
	output [14:0] max_joltage
);


logic [NUM_BANKS-1:0][SIZE_BANK-1:0][3:0] bank_d;	//bank to store values
logic [NUM_BANKS-1:0][SIZE_BANK-1:0][3:0] bank_q;	//bank to store values. total size = NUM_BANKS*SIZE_BANK*4.

logic [$clog2(SIZE_BANK)-1:0] bank_index_cnt_d;
logic [$clog2(SIZE_BANK)-1:0] bank_index_cnt_q;		//a counter to iterate over all the bank. counter will not wrap over and needs reset assertion to restart.

logic [NUM_BANKS-1:0][3:0] max_battery_in_bank_d;
logic [NUM_BANKS-1:0][3:0] max_battery_in_bank_q;	//max battery rating
logic [NUM_BANKS-1:0][6:0] max_battery_index_in_bank_d;
logic [NUM_BANKS-1:0][6:0] max_battery_index_in_bank_q;	//max battery rating index

logic [NUM_BANKS-1:0][3:0] max_battery_in_bank_n2_d;
logic [NUM_BANKS-1:0][3:0] max_battery_in_bank_n2_q;	//max battery rating till second last index

logic [NUM_BANKS-1:0][6:0] max_battery_in_bank_i1_n1_d;
logic [NUM_BANKS-1:0][6:0] max_battery_in_bank_i1_n1_q;	//max battery rating till second last index
logic [NUM_BANKS-1:0][6:0] max_battery_in_bank_i1_n1_cnt_d;
logic [NUM_BANKS-1:0][6:0] max_battery_in_bank_i1_n1_cnt_q;	//counter for final sum, max = 99
logic [NUM_BANKS-1:0] done_d;
logic [NUM_BANKS-1:0] done_q;

logic [NUM_BANKS-1:0][7:0] max_in_bank_d;		
logic [NUM_BANKS-1:0][7:0] max_in_bank_q;		//largest joltage possible in each bank

logic [$clog2(NUM_BANKS-1)-1:0] cnt_d;
logic [$clog2(NUM_BANKS-1)-1:0] cnt_q;	//counter for final sum
logic [14:0] sum_d;		//to store sum of all bank max joltage: max = NUM_BANKS * 100
logic [14:0] sum_q;		//to store sum of all bank max joltage

logic [7:0] long_cnt_d;	//makeshift counter to delay sum calculation start
logic [7:0] long_cnt_q;


typedef enum logic [1:0] {
    INIT  = 2'd0,
    STORE = 2'd1,
    CALC  = 2'd2
} state_t;

state_t state_d, state_q;

always_comb begin
	bank_d = bank_q;
	bank_index_cnt_d = bank_index_cnt_q;
	max_battery_in_bank_d = max_battery_in_bank_q;
	max_battery_index_in_bank_d = max_battery_index_in_bank_q;
	max_battery_in_bank_n2_d = max_battery_in_bank_n2_q;
	for (int i = 0; i < NUM_BANKS; i++) begin
		if(state_q == STORE) begin
			bank_d[i][bank_index_cnt_q] = (bank_index_cnt_q != 7'd100) ? val[i] : bank_q[i][bank_index_cnt_q];	//last value might not be written

			bank_index_cnt_d = (bank_index_cnt_q != 7'd100) ?  bank_index_cnt_q + 1'b1 : bank_index_cnt_q;	//don't wrap, wrapping will result in wrong max val, each bank has 99 digits

			max_battery_in_bank_d[i] = (val[i] > max_battery_in_bank_q[i]) && (bank_index_cnt_q != 7'd100) ? val[i] : max_battery_in_bank_q[i];

			max_battery_index_in_bank_d[i] = (val[i] > max_battery_in_bank_q[i]) && (bank_index_cnt_q != 7'd100) ? bank_index_cnt_q : max_battery_index_in_bank_q[i];

			max_battery_in_bank_n2_d[i] = (val[i] > max_battery_in_bank_n2_q[i]) && (bank_index_cnt_q < 7'd99) ? val[i] : max_battery_in_bank_n2_q[i];
		end
	end
end


//calculating final values
always_comb begin
	max_battery_in_bank_i1_n1_d = max_battery_in_bank_i1_n1_q;
	max_battery_in_bank_i1_n1_cnt_d = max_battery_in_bank_i1_n1_cnt_q;
	done_d = done_q;
	for (int i = 0; i < NUM_BANKS; i++) begin
		if((state_q == STORE) && (state_d == CALC)) begin
			max_battery_in_bank_i1_n1_cnt_d[i] = max_battery_index_in_bank_q[i]+1'b1;
			done_d = '0;
		end
		else if(state_q == CALC) begin
				max_battery_in_bank_i1_n1_d[i] = (bank_q[i][max_battery_in_bank_i1_n1_cnt_q[i]] > max_battery_in_bank_i1_n1_q[i]) && (max_battery_in_bank_i1_n1_cnt_q[i] != 7'd100) ? bank_q[i][max_battery_in_bank_i1_n1_cnt_q[i]] : max_battery_in_bank_i1_n1_q[i];
				max_battery_in_bank_i1_n1_cnt_d[i] = (max_battery_in_bank_i1_n1_cnt_q[i] != 7'd100) ?  max_battery_in_bank_i1_n1_cnt_q[i] + 1'b1 : max_battery_in_bank_i1_n1_cnt_q[i];
				done_d[i] = (max_battery_in_bank_i1_n1_cnt_q[i] == 7'd99) ? 1'b1 : done_q;
		end
	end
end

//max in each bank calculation
always_comb begin
    max_in_bank_d = max_in_bank_q;
    if (state_q == CALC) begin
        for (int j = 0; j < NUM_BANKS; j++) begin
            if (max_battery_index_in_bank_q[j] == 7'd99)
                //max_in_bank_d[j] = max_battery_in_bank_n2_q[j] * 10 + max_battery_in_bank_q[j];	//replace with LUT
				case (max_battery_in_bank_n2_q[j])
					4'd0: max_in_bank_d[j] =                max_battery_in_bank_q[j];
					4'd1: max_in_bank_d[j] = 8'd10  +       max_battery_in_bank_q[j];
					4'd2: max_in_bank_d[j] = 8'd20  +       max_battery_in_bank_q[j];
					4'd3: max_in_bank_d[j] = 8'd30  +       max_battery_in_bank_q[j];
					4'd4: max_in_bank_d[j] = 8'd40  +       max_battery_in_bank_q[j];
					4'd5: max_in_bank_d[j] = 8'd50  +       max_battery_in_bank_q[j];
					4'd6: max_in_bank_d[j] = 8'd60  +       max_battery_in_bank_q[j];
					4'd7: max_in_bank_d[j] = 8'd70  +       max_battery_in_bank_q[j];
					4'd8: max_in_bank_d[j] = 8'd80  +       max_battery_in_bank_q[j];
					4'd9: max_in_bank_d[j] = 8'd90  +       max_battery_in_bank_q[j];
					default: max_in_bank_d[j] = 8'd0;
				endcase
            else
                //max_in_bank_d[j] = max_battery_in_bank_q[j] * 10 + max_battery_in_bank_i1_n1_q[j];	//replace with LUT
				case (max_battery_in_bank_q[j])
					4'd0: max_in_bank_d[j] =                 max_battery_in_bank_i1_n1_q[j];
					4'd1: max_in_bank_d[j] = 8'd10  +        max_battery_in_bank_i1_n1_q[j];
					4'd2: max_in_bank_d[j] = 8'd20  +        max_battery_in_bank_i1_n1_q[j];
					4'd3: max_in_bank_d[j] = 8'd30  +        max_battery_in_bank_i1_n1_q[j];
					4'd4: max_in_bank_d[j] = 8'd40  +        max_battery_in_bank_i1_n1_q[j];
					4'd5: max_in_bank_d[j] = 8'd50  +        max_battery_in_bank_i1_n1_q[j];
					4'd6: max_in_bank_d[j] = 8'd60  +        max_battery_in_bank_i1_n1_q[j];
					4'd7: max_in_bank_d[j] = 8'd70  +        max_battery_in_bank_i1_n1_q[j];
					4'd8: max_in_bank_d[j] = 8'd80  +        max_battery_in_bank_i1_n1_q[j];
					4'd9: max_in_bank_d[j] = 8'd90  +        max_battery_in_bank_i1_n1_q[j];
				default: max_in_bank_d[j] = 8'd0;
			endcase
        end
    end
end

//long counter to allow calc of maximum battery value of each bank
assign long_cnt_d = (state_q == CALC) && (long_cnt_q < 8'd110) ? long_cnt_q + 1'b1 : long_cnt_q;


//a counter to iterate over max_in_bank and calc sum, how to start this? a done signal
assign cnt_d = (long_cnt_q == 8'd110) && (&done_q) && (cnt_q != 8'd200) ? cnt_q + 1'b1 : cnt_q;		//$clog2(NUM_BANKS) = 8
assign sum_d = (long_cnt_q == 8'd110) && (&done_q) && (cnt_q != 8'd200) ? sum_q + {7'b0, max_in_bank_q[cnt_q]} : sum_q;

always_comb begin
	state_d = state_q;
	case(state_q)
		INIT: begin
			if(rst_n && bank_en) state_d = STORE;
		end
		STORE: begin
			if(bank_index_cnt_q == 7'd99) state_d = CALC;
		end
		CALC: begin
			if(cnt_q == 8'd200) state_d = INIT;
		end
	endcase
end


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		bank_q <= '0;
		cnt_q  <= '0;
		sum_q  <= '0;
		max_in_bank_q <= '0;
		bank_index_cnt_q <= '0;
		max_battery_in_bank_q <= '0;
		max_battery_index_in_bank_q <= '0;
		state_q <= INIT;
		max_battery_in_bank_i1_n1_q <= '0;
		max_battery_in_bank_i1_n1_cnt_q <= '0;
		done_q <= '0;
		max_battery_in_bank_n2_q <= '0;
		long_cnt_q <= '0;
	end
    else begin
		bank_q <= bank_d;
		cnt_q  <= cnt_d;
		sum_q  <= sum_d;
		max_in_bank_q <= max_in_bank_d;
		bank_index_cnt_q <= bank_index_cnt_d;
		max_battery_in_bank_q <= max_battery_in_bank_d;
		max_battery_index_in_bank_q <= max_battery_index_in_bank_d;
		state_q <= state_d;
		max_battery_in_bank_i1_n1_q <= max_battery_in_bank_i1_n1_d;
		max_battery_in_bank_i1_n1_cnt_q <= max_battery_in_bank_i1_n1_cnt_d;
		done_q <= done_d;
		max_battery_in_bank_n2_q <= max_battery_in_bank_n2_d;
		long_cnt_q <= long_cnt_d;
	end
end

assign max_joltage = (cnt_q == 8'd200) ? sum_q : '0;

endmodule

