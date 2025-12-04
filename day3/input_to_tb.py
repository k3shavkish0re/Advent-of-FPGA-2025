#!/usr/bin/env python3
import sys

INPUT_FILE = "input.txt"
OUTPUT_TB  = "tb_puzzle1.sv"

NUM_BANKS = 200
EFFECTIVE_DEPTH = 100    

def read_input():
    banks = []
    with open(INPUT_FILE, "r") as f:
        for line_no, line in enumerate(f, start=1):
            s = line.strip()
            if not s:
                continue
            if len(s) != EFFECTIVE_DEPTH:
                raise ValueError(
                    f"Line {line_no}: expected {EFFECTIVE_DEPTH} digits, got {len(s)}"
                )
            row = [int(c) for c in s]
            banks.append(row)
    if len(banks) != NUM_BANKS:
        raise ValueError(
            f"Expected {NUM_BANKS} rows but found {len(banks)}"
        )
    return banks


def generate_tb(banks):
    with open(OUTPUT_TB, "w") as f:

        # BEGIN TESTBENCH EXACT REPLICA
        f.write("""`timescale 1ns/1ns

module tb_puzzle1;

    localparam int NUM_BANKS = 200;
    localparam int SIZE_BANK = 128;
    localparam int EFFECTIVE_DEPTH = 100;

    logic clk;
    logic rst_n;
    logic bank_en;
    logic [NUM_BANKS-1:0][3:0] val;
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
        $monitor("[%0t] clk=%0b | rst_n=%0b | bank_en=%0d |state=%0d | max_in_bank_q=%0d | cnt=%0d | sum=%0d | max_joltage=%0d | done_all=%0b | bank0:max=%0d idx=%0d i1n1=%0d max_in=%0d | bank1:max=%0d idx=%0d i1n1=%0d max_in=%0d | bank199:max=%0d idx=%0d i1n1=%0d max_in=%0d",
            $time,
			clk,
			rst_n,
			bank_en,
            dut.state_q,
            dut.max_in_bank_q[dut.cnt_q],
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
	
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_puzzle1);

        rst_n  = 1;
        bank_en = 0;
        val     = '0;

        repeat (5) @(posedge clk);
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Start storing
        bank_en = 1;
        @(posedge clk);
        bank_en = 1;   // keep high during storage
""")

        # INSERT GENERATED VAL ASSIGNMENTS
        f.write("\n        // ---------------- INPUT-DRIVEN VAL PATTERN ----------------\n")
        for idx in range(EFFECTIVE_DEPTH):
            # build `' { val0, val1, ... }`
            row_vals = ", ".join(str(banks[b][idx]) for b in range(NUM_BANKS))
            f.write(f"        val = '{{ {row_vals} }};\n")
            f.write("        @(posedge clk);\n")

        # finish testbench
        f.write("""
        // done storing
        bank_en = 0;
        val = '0;

        repeat (2000) @(posedge clk);

        $finish;
    end

endmodule
""")


# MAIN
banks = read_input()
generate_tb(banks)
print("Generated tb_puzzle1.sv successfully.")
