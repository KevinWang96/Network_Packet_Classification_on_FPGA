`define NUM_RIDS 5 // number of RIDS need to merge
`define NUM_RID 8 // number of rule ID in each RIDS
`define RID_WIDTH 4 // the width of each rule ID
`define RIDS_WIDTH 32 // the width of each RIDS, RIDS_WIDTH = NUM_RID * RID_WIDTH
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-12 16:48:13
 * @LastEditTime: 2020-04-12 17:16:24
 * @LastEditors: Please set LastEditors
 * @Description: 
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_merge_tree.v
 */
 module bitonic_merge_tree (
     input clk, reset,
     input [0:NUM_RIDS * RIDS_WIDTH - 1] in,
     output [0:RIDS_WIDTH - 1] out
 );

    // Merge RIDS #0 and RIDS #1
    wire [0:RIDS_WIDTH - 1] RIDS_0_1; // new RIDS which contains common rule IDs in RIDS #0 and RIDS #1

    wire [0:RIDS_WIDTH - 1] RIDS_0 = in[(0 * RIDS_WIDTH)+:RIDS_WIDTH]
    wire [0:RIDS_WIDTH - 1] RIDS_1 = in[(1 * RIDS_WIDTH)+:RIDS_WIDTH];

    reg [0:RIDS_WIDTH - 1] RIDS_1_r; // the reverse sequence of RIDS #1
    
    always @(*)
    begin : reverse_loop_0
        integer i;

        for(i = 0; i < NUM_RID; i = i + 1)
            RIDS_1_r[(i * RID_WIDTH)+:RID_WIDTH] = RIDS_1[((NUM_RID - 1 - i) * RID_WIDTH)+:RID_WIDTH];

    end

    // Use BM(2 * RIDS_WIDTH) to merge two bitoic sequence
    wire [0:2 * RIDS_WIDTH - 1] merge_res_0_1; // the sorting results of two input RIDS
    bitonic_merge #(
        .N(2 * NUM_RID),
        .log_N($clog2(2 * NUM_RID)),
        .INPUT_WIDTH(RID_WIDTH),
        .polarity(0)
    )
    BM_0_1
    (
        .clk(clk),
        .reset(reset),
        .in({RIDS_0, RIDS_1_r}),
        .out(merge_res_0_1)
    );

    



