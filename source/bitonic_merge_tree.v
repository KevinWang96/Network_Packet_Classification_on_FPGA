`define NUM_RIDS 5 // number of RIDS need to merge
`define NUM_RID 8 // number of rule ID in each RIDS
`define log_NUM_RID 3 // log2(NUM_RID)
`define RID_WIDTH 4 // the width of each rule ID
`define RIDS_WIDTH 32 // the width of each RIDS, RIDS_WIDTH = NUM_RID * RID_WIDTH
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-12 16:48:13
 * @LastEditTime: 2020-04-13 02:11:26
 * @LastEditors: Please set LastEditors
 * @Description: a. A bitonic merge tree used to merge (NUM_RIDS) RIDSs and find common elements
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_merge_tree.v
 */
 module bitonic_merge_tree (
     input clk, reset,
     input [0:`NUM_RIDS * `RIDS_WIDTH - 1] in,
     output [0:`RIDS_WIDTH - 1] out
 );

//// Merge RIDS #0 and RIDS #1
    wire [0:`RIDS_WIDTH - 1] RIDS_0_1; // new RIDS which contains common rule IDs in RIDS #0 and RIDS #1

    wire [0:`RIDS_WIDTH - 1] RIDS_0 = in[(0 * `RIDS_WIDTH)+:`RIDS_WIDTH];
    wire [0:`RIDS_WIDTH - 1] RIDS_1 = in[(1 * `RIDS_WIDTH)+:`RIDS_WIDTH];

    // We need to inverse RIDS #1 to make {RIDS_0, RIDS_1_r} a bitonic sequence
    wire [0:`RIDS_WIDTH - 1] RIDS_1_r;

    genvar i;
    generate 
    begin
        for(i = 0; i < `NUM_RID; i = i + 1)
        begin : for_loop_0
            assign RIDS_1_r[(i * `RID_WIDTH)+:`RID_WIDTH]
                = RIDS_1[((`NUM_RID - 1 - i) * `RID_WIDTH)+:`RID_WIDTH];
        end
    end
    endgenerate

    BMNC_bitonic #(
        .N(`NUM_RID),
        .log_N(`log_NUM_RID),
        .elements_width(`RID_WIDTH)
    )
    BMNC_0
    (
        .clk(clk),
        .reset(reset),
        .in({RIDS_0, RIDS_1_r}),
        .out(RIDS_0_1)
    );

//// Merge RIDS #2 and RIDS #3
    wire [0:`RIDS_WIDTH - 1] RIDS_2_3; // new RIDS which contains common rule IDs in RIDS #2 and RIDS #3

    wire [0:`RIDS_WIDTH - 1] RIDS_2 = in[(2 * `RIDS_WIDTH)+:`RIDS_WIDTH];
    wire [0:`RIDS_WIDTH - 1] RIDS_3 = in[(3 * `RIDS_WIDTH)+:`RIDS_WIDTH];

    // We need to inverse RIDS #3 to make {RIDS_2, RIDS_3_r} a bitonic sequence
    wire [0:`RIDS_WIDTH - 1] RIDS_3_r;

    generate 
    begin
        for(i = 0; i < `NUM_RID; i = i + 1)
        begin : for_loop_0
            assign RIDS_3_r[(i * `RID_WIDTH)+:`RID_WIDTH]
                = RIDS_3[((`NUM_RID - 1 - i) * `RID_WIDTH)+:`RID_WIDTH];
        end
    end
    endgenerate

    BMNC_bitonic #(
        .N(`NUM_RID),
        .log_N(`log_NUM_RID),
        .elements_width(`RID_WIDTH)
    )
    BMNC_1
    (
        .clk(clk),
        .reset(reset),
        .in({RIDS_2, RIDS_3_r}),
        .out(RIDS_2_3)
    ); 

//// Merge RIDS_0_1 with RIDS_2_3

    wire [0:`RIDS_WIDTH - 1] RIDS_01_23; // new RIDS which contains common rule IDs in RIDS_0_1 and RIDS_2_3 
    
    BMNC_random #(
        .N(`NUM_RID),
        .log_N(`log_NUM_RID),
        .elements_width(`RID_WIDTH)
    )
    BMNC_2
    (
        .clk(clk),
        .reset(reset),
        .in({RIDS_0_1, RIDS_2_3}),
        .out(RIDS_01_23)
    ); 

//// Merge RIDS_01_23 with RIDS #4

    wire [0:`RIDS_WIDTH - 1] RIDS_4 = in[(4 * `RIDS_WIDTH)+:`RIDS_WIDTH];
    
    BMNC_random #(
        .N(`NUM_RID),
        .log_N(`log_NUM_RID),
        .elements_width(`RID_WIDTH)
    )
    BMNC_3
    (
        .clk(clk),
        .reset(reset),
        .in({RIDS_01_23, RIDS_4}),
        .out(out)
    ); 

 endmodule
`undef NUM_RIDS 
`undef NUM_RID 
`undef log_NUM_RID 
`undef RID_WIDTH 
`undef RIDS_WIDTH 