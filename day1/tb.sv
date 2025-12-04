// Auto-generated Verilog testbench for puzzle1
module tb_puzzle1;

  reg clk;
  reg rst_n;
  reg vld;
  reg dir;
  reg [9:0] steps;
  reg read_en;
  wire [9:0] pwd;

  puzzle2 dut (
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .dir(dir),
    .steps(steps),
    .read_en(read_en),
    .pwd(pwd)
  );

  initial begin
    clk     = 0;
    rst_n   = 1;
    vld     = 0;
    dir     = 0;
    steps   = 0;
    read_en = 0;
  end

  initial begin
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  task apply_move(input string d, input int s);
    begin
      @(posedge clk);
      dir = (d == "R");
      steps = s;
      vld = 1;
      @(posedge clk);
      vld = 0;
    end
  endtask

  initial begin
    // Wait for reset deassertion
    @(posedge rst_n);
    @(posedge clk);


   
    // Assert read_en to read pwd
    apply_move("L", 68);
    // Assert read_en to read pwd
    apply_move("L", 30);
    // Assert read_en to read pwd
    apply_move("R", 48);
    // Assert read_en to read pwd
    apply_move("L", 5);
    // Assert read_en to read pwd
    apply_move("R", 60);
    // Assert read_en to read pwd
    apply_move("L", 55);
    // Assert read_en to read pwd
    apply_move("L", 1);
    // Assert read_en to read pwd
    apply_move("L", 99);
    // Assert read_en to read pwd
    apply_move("R", 14);
    // Assert read_en to read pwd
    apply_move("L", 82);

    @(posedge clk); read_en = 1;
    @(posedge clk); read_en = 0;

    $finish;
  end

  initial begin
    $monitor(
      "T=%0t | clk=%b rst_n=%b vld=%b dir=%b steps=%0d read_en=%b | actual_steps_d=%0d actual_steps_q=%0d | position_d=%0d position_q=%0d | cnt_d=%0d cnt_q=%0d | sum_pos_act_steps=%0d | pwd=%0d",
      $time,
      clk, rst_n, vld, dir, steps, read_en,
      dut.actual_steps_d,
      dut.actual_steps_q,
      dut.position_d,
      dut.position_q,
      dut.cnt_d,
      dut.cnt_q,
      dut.sum_position_actual_steps,
      dut.pwd
    );
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_puzzle1);
  end

endmodule
