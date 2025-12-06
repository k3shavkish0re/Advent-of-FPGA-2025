# generate_tb.py
# ----------------------------------------------------------
# Reads input ranges, converts to BCD, and produces a
# SystemVerilog testbench WITHOUT self-checking.
# ----------------------------------------------------------

import re

# ---------- BCD utilities ----------
def int_to_bcd40(n: int) -> str:
    s = str(n).rjust(10, "0")  # exactly 10 digits
    bits = []
    for ch in s[::-1]:  # LSB digit first
        d = int(ch)
        bits.append(f"{d:04b}")
    bcd_bin = "".join(bits[::-1])  # MSB digit first
    return bcd_bin  # string of 40 bits


# ---------- Read input ranges ----------
with open("input.txt") as f:
    txt = f.read().strip()

pairs = txt.split(",")

low_list = []
high_list = []

for p in pairs:
    lo, hi = map(int, p.split("-"))
    low_list.append(lo)
    high_list.append(hi)

NUM_RANGES = len(low_list)
print("Parsed ranges =", NUM_RANGES)

# ---------- Convert to BCD ----------
bcd_low  = [int_to_bcd40(x) for x in low_list]
bcd_high = [int_to_bcd40(x) for x in high_list]


# ---------- Generate SystemVerilog testbench ----------
tb = []

tb.append("""
`timescale 1ns/1ps

module tb_puzzle1;

    localparam MAX_LENGTH = 10;
    localparam SUM_SIZE   = 50;
    localparam NUM_RANGES = %d;

    logic clk;
    logic rst_n;
    logic vld;

    logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] low;
    logic [NUM_RANGES-1:0][MAX_LENGTH*4-1:0] high;

    logic [SUM_SIZE-1:0] out;

    puzzle1 dut (
        .clk(clk),
        .rst_n(rst_n),
        .vld(vld),
        .low(low),
        .high(high),
        .out(out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        vld   = 0;
        #20;
        rst_n = 1;
        vld   = 1;

        // Load BCD low/high values
""" % NUM_RANGES)

# add low[]
for i, bits in enumerate(bcd_low):
    tb.append(f"        low[{i}]  = 40'b{bits};")

tb.append("")
# add high[]
for i, bits in enumerate(bcd_high):
    tb.append(f"        high[{i}] = 40'b{bits};")

tb.append("""

        // Run long enough for DUT to complete internal accumulation
        #200000;

        $display("\\nDUT OUT = %0d (decimal)", out);
        $display("DUT OUT (hex) = %h", out);
        $display("DUT OUT (binary) = %b", out);

        $finish;
    end

endmodule
""")

with open("tb_puzzle1.sv", "w") as f:
    f.write("\n".join(tb))

print("Generated testbench: tb_puzzle1.sv")
