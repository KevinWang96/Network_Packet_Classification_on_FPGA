`timescale 1ns/100ps
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-10 00:38:45
 * @LastEditTime: 2020-04-10 01:52:30
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for bitonic_merge
 * @FilePath: /EE599_FPGA_package_classification/tb/tb_bitonic_merge.v
 */
module tb_bitonic_merge;

    localparam N = 16;
    localparam INPUT_WIDTH = 6;
    localparam CLK = 10;

    reg clk, reset;
    reg [0:N * INPUT_WIDTH - 1] in;
    wire [0:N * INPUT_WIDTH - 1] out;

    // DUT
    bitonic_merge #(
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

        in = 256'hfe_dc_ba_98_01_23_45_67;

        #($clog2(N) * 2 * CLK)
        $finish;
    end

endmodule