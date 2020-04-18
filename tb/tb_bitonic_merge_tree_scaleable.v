`timescale 1ns/1ps
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-18 00:57:57
 * @LastEditTime: 2020-04-18 01:08:26
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for bitonic_merge_tree_scaleable
 * @FilePath: /EE599_FPGA_package_classification/tb/tb_bitonic_merge_tree_scaleable.v
 */
 module tb_bitonic_merge_tree_scaleable;
    
    localparam M = 8;
    localparam log_M = $clog2(M);
    localparam RID_WIDTH = 4;
    localparam NUM_RID = 8;
    localparam log_NUM_RID = 3;

    localparam RIDS_WIDTH = RID_WIDTH * NUM_RID;

    localparam CLK = 10;

    reg clk, reset;
    reg [0:M * RIDS_WIDTH - 1] in;
    wire [0:RIDS_WIDTH - 1] out;

    always #(0.5 * CLK) clk = ~ clk;

    bitonic_merge_tree_scaleable #(
        .M(M),
        .log_M(log_M),
        .RID_WIDTH(RID_WIDTH),
        .NUM_RID(NUM_RID),
        .log_NUM_RID(log_NUM_RID)
    )
    dut
    (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    localparam  RIDS_0 = 32'h01_23_45_67,
                RIDS_1 = 32'h00_01_23_9a,
                RIDS_2 = 32'h00_00_00_23,
                RIDS_3 = 32'h00_01_23_45,
                RIDS_4 = 32'h00_23_ab_cd,
                RIDS_5 = 32'h00_01_23_45,
                RIDS_6 = 32'h00_00_23_79,
                RIDS_7 = 32'h00_00_00_03;


    initial
    begin
        clk = 1;
        reset = 1;

        #(3.5 * CLK)
        reset = 0;

        in = {RIDS_0, RIDS_1, RIDS_2, RIDS_3, RIDS_4, RIDS_5, RIDS_6, RIDS_7};
    end

 endmodule
