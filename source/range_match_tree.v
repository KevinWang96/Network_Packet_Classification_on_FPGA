`define data_width 32 // IP is assumed to be 32-bit width
`define RIDS_width 32 // eight 4-bit rule ID, each rule ID is 3-bit and 1-bit valid bit is attached
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-11 17:37:54
 * @LastEditTime: 2020-05-06 07:27:44
 * @LastEditors: Please set LastEditors
 * @Description: a. Source IP range match tree used to match each field of network packet
 *               b. Used binary search tree to achieve range matching 
 *               c. The boundry of each node are stored in BRAM
 *               d. Not a scaleable design, the depth of this tree is 4
 *               e. The root node is node #0 and the tree is a full binary tree
 *               f. This network is implemented using 5-stage pipeline a
 *                  and the output is rule ID set which is attached to one of leaf node
 * @FilePath: /EE599_FPGA_package_classification/source/range_match_tree.v
 */
module range_match_tree (
    input clk, reset, // positive edge triggering and sync hign active reset
    input [0:`data_width - 1] in,
    output reg [0:`RIDS_width - 1] out
);

    // Instantiation of two 16 X (data_width) bits dual port BRAMs used for parallel searching by four PEs
    // n-depth tree will has (2 ** n - 1) nodes, so n-bit address are needed
    wire [0:3] bound_mem_addr_0, bound_mem_addr_1, bound_mem_addr_2, bound_mem_addr_3;
    wire [0:31] bound_mem_do_0, bound_mem_do_1, bound_mem_do_2, bound_mem_do_3;

    blk_mem_gen_0 bound_mem_0 (
    .clka(clk),    // input wire clka
    .addra(bound_mem_addr_0),  // input wire [3 : 0] addra
    .douta(bound_mem_do_0),  // output wire [31 : 0] douta
    .clkb(clk),    // input wire clkb
    .addrb(bound_mem_addr_1),  // input wire [3 : 0] addrb
    .doutb(bound_mem_do_1)  // output wire [31 : 0] doutb
    );

    blk_mem_gen_1 bound_mem_1 (
    .clka(clk),    // input wire clka
    .addra(bound_mem_addr_2),  // input wire [3 : 0] addra
    .douta(bound_mem_do_2),  // output wire [31 : 0] douta
    .clkb(clk),    // input wire clkb
    .addrb(bound_mem_addr_3),  // input wire [3 : 0] addrb
    .doutb(bound_mem_do_3)  // output wire [31 : 0] doutb
    );

    // Instantiation of one 16 X (RIDS_width) bits single port BRAM used to store 16 RIDS 
    wire [0:3] RIDS_mem_addr;
    wire [0:`RIDS_width - 1] RIDS_mem_do;

    blk_mem_gen_2 RIDS_mem (
    .clka(clk),    // input wire clka
    .addra(RIDS_mem_addr),  // input wire [3 : 0] addra
    .douta(RIDS_mem_do)  // output wire [31 : 0] douta
    );

    // Load input data into input register
    reg [0:`data_width + 4 - 1] in_reg; // in_reg = {data[0:31], node_id[0:depth - 1]}
    always @(posedge clk)
    begin
        if(reset) in_reg <= 0;
        else in_reg <= {in, bound_mem_addr_0};
    end

    // Assign BRAM address becasue BRAM is flow-through 
    assign bound_mem_addr_0 = 0;

//// Stage #0 ///////////////////////////////////////////////////////////////////////////////////

    wire LT_0, GTET_0;

    range_match_tree_pe #(
        .data_width(`data_width)
    )
    pe_0
    (
        .in(in_reg[0:`data_width - 1]),
        .target(bound_mem_do_0),
        .LT(LT_0),
        .GTET(GTET_0)
    );

    reg [0:`data_width + 4 - 1] stage_reg_0; // stage_reg_0 = {data[0:31], node_id[0:depth - 1]} 

    assign bound_mem_addr_1 = ({LT_0, GTET_0} == 2'b10) ? (2 * in_reg[`data_width+:4] + 1) : (2 * in_reg[`data_width+:4] + 2);

    always @(posedge clk)
    begin
        if(reset) stage_reg_0 <= 0;
        else stage_reg_0 <= {in_reg[0:`data_width - 1], bound_mem_addr_1};
    end

//// Stage #1 ///////////////////////////////////////////////////////////////////////////////////

    wire LT_1, GTET_1;

    range_match_tree_pe #(
        .data_width(`data_width)
    )
    pe_1
    (
        .in(stage_reg_0[0:`data_width - 1]),
        .target(bound_mem_do_1),
        .LT(LT_1),
        .GTET(GTET_1)
    );

    reg [0:`data_width + 4 - 1] stage_reg_1; // stage_reg_1 = {data[0:31], node_id[0:depth - 1]} 

    assign bound_mem_addr_2 = ({LT_1, GTET_1} == 2'b10) ? 
                                (2 * stage_reg_0[`data_width+:4] + 1) : (2 * stage_reg_0[`data_width+:4] + 2);

    always @(posedge clk)
    begin
        if(reset) stage_reg_1 <= 0;
        else stage_reg_1 <= {stage_reg_0[0:`data_width - 1], bound_mem_addr_2};
    end

//// Stage #2 ///////////////////////////////////////////////////////////////////////////////////

    wire LT_2, GTET_2;

    range_match_tree_pe #(
        .data_width(`data_width)
    )
    pe_2
    (
        .in(stage_reg_1[0:`data_width - 1]),
        .target(bound_mem_do_2),
        .LT(LT_2),
        .GTET(GTET_2)
    );

    reg [0:`data_width + 4 - 1] stage_reg_2; // stage_reg_2 = {data[0:31], node_id[0:depth - 1]} 

    assign bound_mem_addr_3 = ({LT_2, GTET_2} == 2'b10) ? 
                                (2 * stage_reg_1[`data_width+:4] + 1) : (2 * stage_reg_1[`data_width+:4] + 2);

    always @(posedge clk)
    begin
        if(reset) stage_reg_2 <= 0;
        else stage_reg_2 <= {stage_reg_1[0:`data_width - 1], bound_mem_addr_3};
    end

//// Stage #3 ///////////////////////////////////////////////////////////////////////////////////

    wire LT_3, GTET_3;

    range_match_tree_pe #(
        .data_width(`data_width)
    )
    pe_3
    (
        .in(stage_reg_2[0:`data_width - 1]),
        .target(bound_mem_do_3),
        .LT(LT_3),
        .GTET(GTET_3)
    );

    assign RIDS_mem_addr = ({LT_3, GTET_3} == 2'b10) ?
                                (2 * stage_reg_1[`data_width+:4] + 1 - (2 ** 4 - 1)) 
                                    : (2 * stage_reg_1[`data_width+:4] + 2 - (2 ** 4 - 1));

//// Stage #3 ///////////////////////////////////////////////////////////////////////////////////

    // Output register
    always @(posedge clk)
    begin
        if(reset) out <= 0;
        else out <= RIDS_mem_do;
    end

endmodule
`undef data_width
`undef RIDS_width