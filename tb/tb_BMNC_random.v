`timescale 1ns/1ps
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-13 01:24:53
 * @LastEditTime: 2020-04-13 01:39:27
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for BMNC_random
 * @FilePath: /EE599_FPGA_package_classification/tb/tb_BMNC_random.v
 */
module tb_BMNC_random;

    localparam CLK = 10;
    localparam N = 8;
    localparam log_N = 3;
    localparam elements_width = 4;

    reg clk, reset;
    reg [0:2 * N * elements_width - 1] in;
    wire [0:N * elements_width - 1] out;

    always #(0.5 * CLK) clk = ~ clk;

    BMNC_random #(
        .N(N),
        .log_N(log_N),
        .elements_width(elements_width)
    )
    BMNC_random_dut
    (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    initial
    begin
        clk = 1;
        reset = 1;

        #(3.5 * CLK)
        reset = 0;

        in = 64'h01_23_45_67_01_23_45_67;

        #(100 * CLK)
        $finish;        
    end

endmodule
