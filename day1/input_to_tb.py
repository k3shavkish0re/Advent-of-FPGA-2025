import re

INPUT_FILE = "input.txt"
OUTPUT_FILE_PUZZLE1 = "generated_tb_puzzle1.sv"
OUTPUT_FILE_PUZZLE2 = "generated_tb_puzzle2.sv"

def parse_line(line):
    line = line.strip()
    if not line:
        return None
    
    match = re.match(r"([LR])(\d+)", line)
    if not match:
        return None
    
    direction = match.group(1)
    steps = int(match.group(2))

    # clamp steps to 1023
    steps = min(steps, 1023)

    return direction, steps


def write_testbench(filename, module_name, commands):
    with open(filename, "w") as f:
        f.write(f"// Auto-generated Verilog testbench for {module_name}\n")
        f.write(f"module tb_{module_name};\n\n")

        # Declare signals
        f.write("  reg clk;\n")
        f.write("  reg rst_n;\n")
        f.write("  reg vld;\n")
        f.write("  reg dir;\n")
        f.write("  reg [9:0] steps;\n")
        f.write("  reg read_en;\n")
        f.write("  wire [9:0] pwd;\n\n")

        # DUT instantiation
        f.write(f"  {module_name} dut (\n")
        f.write("    .clk(clk),\n")
        f.write("    .rst_n(rst_n),\n")
        f.write("    .vld(vld),\n")
        f.write("    .dir(dir),\n")
        f.write("    .steps(steps),\n")
        f.write("    .read_en(read_en),\n")
        f.write("    .pwd(pwd)\n")
        f.write("  );\n\n")

        # INITIAL BLOCK 1 — initialize signals
        f.write("  initial begin\n")
        f.write("    clk     = 0;\n")
        f.write("    rst_n   = 1;\n")
        f.write("    vld     = 0;\n")
        f.write("    dir     = 0;\n")
        f.write("    steps   = 0;\n")
        f.write("    read_en = 0;\n")
        f.write("  end\n\n")

        # INITIAL BLOCK 2 — clock generation
        f.write("  initial begin\n")
        f.write("    forever #5 clk = ~clk;\n")
        f.write("  end\n\n")

        # INITIAL BLOCK 3 — reset
        f.write("  initial begin\n")
        f.write("    rst_n = 0;\n")
        f.write("    repeat (5) @(posedge clk);\n")
        f.write("    rst_n = 1;\n")
        f.write("  end\n\n")

        # TASK apply_move
        f.write("  task apply_move(input string d, input int s);\n")
        f.write("    begin\n")
        f.write("      @(posedge clk);\n")
        f.write("      dir = (d == \"R\");\n")
        f.write("      steps = s;\n")
        f.write("      vld = 1;\n")
        f.write("      @(posedge clk);\n")
        f.write("      vld = 0;\n")
        f.write("    end\n")
        f.write("  endtask\n\n")

        # MAIN INITIAL BLOCK — apply commands
        f.write("  initial begin\n")
        f.write("    @(posedge rst_n);\n")
        f.write("    @(posedge clk);\n\n")

        for d, s in commands:
            f.write(f"    apply_move(\"{d}\", {s});\n")
            f.write("    // Assert read_en to read pwd\n")

        f.write("    @(posedge clk); read_en = 1;\n")
        f.write("    @(posedge clk); read_en = 0;\n\n")
        f.write("    $finish;\n")
        f.write("  end\n\n")

        # MONITOR BLOCK
        f.write("  initial begin\n")
        f.write('    $monitor(\n')
        f.write(
            '      "T=%0t | clk=%b rst_n=%b vld=%b dir=%b steps=%0d read_en=%b | '
            'actual_steps_d=%0d actual_steps_q=%0d | '
            'position_d=%0d position_q=%0d | '
            'cnt_d=%0d cnt_q=%0d | sum_pos_act_steps=%0d | pwd=%0d",\n'
        )
        f.write("      $time,\n")
        f.write("      clk, rst_n, vld, dir, steps, read_en,\n")
        f.write("      dut.actual_steps_d,\n")
        f.write("      dut.actual_steps_q,\n")
        f.write("      dut.position_d,\n")
        f.write("      dut.position_q,\n")
        f.write("      dut.cnt_d,\n")
        f.write("      dut.cnt_q,\n")
        f.write("      dut.sum_position_actual_steps,\n")
        f.write("      dut.pwd\n")
        f.write("    );\n")
        f.write("  end\n\n")

        # WAVEFORM DUMP
        f.write("  initial begin\n")
        f.write(f"    $dumpfile(\"{module_name}_wave.vcd\");\n")
        f.write(f"    $dumpvars(0, tb_{module_name});\n")
        f.write("  end\n\n")

        f.write("endmodule\n")

    print(f"Generated {filename} with {len(commands)} commands.")


def main():
    commands = []

    # Read commands
    with open(INPUT_FILE, "r") as f:
        for line in f:
            parsed = parse_line(line)
            if parsed:
                commands.append(parsed)

    write_testbench(OUTPUT_FILE_PUZZLE1, "puzzle1", commands)
    write_testbench(OUTPUT_FILE_PUZZLE2, "puzzle2", commands)


if __name__ == "__main__":
    main()
