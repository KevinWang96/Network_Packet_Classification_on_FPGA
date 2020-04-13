`timescale 1ns/100ps
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-10 00:38:45
 * @LastEditTime: 2020-04-12 01:58:21
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for bitonic_sort
 * @FilePath: /EE599_FPGA_package_classification/tb/tb_bitonic_merge.v
 */
module tb_bitonic_sort;

    localparam N = 8;
    localparam INPUT_WIDTH = 4;
    localparam CLK = 10;

    reg clk, reset;
    reg [0:N * INPUT_WIDTH - 1] in;
    wire [0:N * INPUT_WIDTH - 1] out;

    // DUT
    bitonic_sort #(
        .N(N),
        .INPUT_WIDTH(INPUT_WIDTH),
        .log_N($clog2(N)),
        .polarity(0)
    )
    bitonic_merge_dut
    (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    always #(0.5 * CLK) clk = ~ clk;

    initial 
    begin
        clk = 1;
        reset = 1;

        #(3.5 * CLK) 
        reset = 0;

        in = 32'h09_23_58_f4;

        #($clog2(N) * 20 * CLK)
        $finish;
    end

endmodule