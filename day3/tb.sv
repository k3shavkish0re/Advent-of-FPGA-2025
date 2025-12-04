`timescale 1ns/1ns

module tb_puzzle1;

    localparam int NUM_BANKS = 200;
    localparam int SIZE_BANK = 128;
    localparam int EFFECTIVE_DEPTH = 100;   // you said index goes 0..98

    logic clk;
    logic rst_n;
    logic bank_en;
    logic [NUM_BANKS-1:0][3:0] val;
    logic rd_en;
    logic [14:0] max_joltage;

    // Instantiate DUT
    puzzle1 #(
        .NUM_BANKS(NUM_BANKS),
        .SIZE_BANK(SIZE_BANK)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .bank_en(bank_en),
        .val(val),
        .max_joltage(max_joltage)
    );
	
	// ----------------------------------------
    // $monitor — print internal DUT signals
    // ----------------------------------------
    initial begin
        $monitor("[%0t] clk=%0b | rst_n=%0b | bank_en=%0d |state=%0d | bank_idx=%0d | cnt=%0d | sum=%0d | max_joltage=%0d | done_all=%0b | bank0:max=%0d idx=%0d i1n1=%0d max_in=%0d | bank1:max=%0d idx=%0d i1n1=%0d max_in=%0d | bank199:max=%0d idx=%0d i1n1=%0d max_in=%0d",
            $time,
			clk,
			rst_n,
			bank_en,
            dut.state_q,
            dut.bank_index_cnt_q,
            dut.cnt_q,
            dut.sum_q,
            dut.max_joltage,
            &dut.done_q,  
            dut.max_battery_in_bank_q[0],
            dut.max_battery_index_in_bank_q[0],
            dut.max_battery_in_bank_i1_n1_q[0],
            dut.max_in_bank_q[0],
            dut.max_battery_in_bank_q[1],
            dut.max_battery_index_in_bank_q[1],
            dut.max_battery_in_bank_i1_n1_q[1],
            dut.max_in_bank_q[1],
            dut.max_battery_in_bank_q[199],
            dut.max_battery_index_in_bank_q[199],
            dut.max_battery_in_bank_i1_n1_q[199],
            dut.max_in_bank_q[199],
        );
    end
	
	
    // ----------------------------------------
    // Clock generation
    // ----------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // ----------------------------------------
    // Test sequence
    // ----------------------------------------
    initial begin
        // waveform
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_puzzle1);

        // init
        rst_n  = 1;
        bank_en = 0;
        val     = '0;

        // reset
        repeat (5) @(posedge clk);
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // ----------------------------------------
        // Start storing
        // ----------------------------------------
        bank_en = 1;
        @(posedge clk);
        bank_en = 1;   // keep high during storage (change to 0 if your DUT wants pulse-only)

        // Drive val for each of the 100 index cycles
        for (int idx = 0; idx < EFFECTIVE_DEPTH; idx++) begin
            // simple example pattern:
            for (int b = 0; b < NUM_BANKS; b++) begin
                val[b] = (b + idx) % 10;   // same 4-bit digit for all banks; easy to see in waveform
            end
            @(posedge clk);
        end

        // done storing
        bank_en = 0;
        val = '0;

        // ----------------------------------------
        // Now DUT does its internal work
        // You manually inspect waveforms until max_joltage appears.
        // ----------------------------------------

        repeat (2000) @(posedge clk);  // wait some time, adjust as needed

        $finish;
    end

endmodule
