`timescale 1ns/1ps

`define IP_WIDTH 32 // containing 4 domains, each domain is 8-bit width
`define NUM_RULE_ID 8 // number of rule IDs in rule set
`define RULE_ID_WIDTH 3 // There are 8 rules in rule set, log2(8) = 3
`define CYCLE_TIME 10
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-07 02:43:31
 * @LastEditTime: 2020-04-07 15:51:01
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for SIP_prefix_match_tree.v
 * @FilePath: /EE599_FPGA_package_classification/source/tb_SIP_prefix_match_tree.v
 */
 module tb_SIP_prefix_match_tree;
    
    reg clk, reset;
    reg [0:`IP_WIDTH] in; // 1-bit valid bit and 32-bit IP address

    parameter   IP_FIELD_0 = 192,
                IP_FIELD_1 = 168,
                IP_FIELD_2 = 0,
                IP_FIELD_3 = 128;

    // output rule ID set, each 3-bit rule ID is attached with 1-bit valid bit
    wire [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out; 
    
    // Instantiation of DUT
    SIP_prefix_match_tree SIP_prefix_match_tree_dut
    (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    // Generates clock signal
    always #(0.5 * `CYCLE_TIME) clk = ~ clk;

    initial
    begin
        clk = 1;
        reset = 1;

        #(3.5 * `CYCLE_TIME)
        reset = 0; // deasserts reset after 3.5 clocks
        
        in[0] = 1; // valid bit = 1;
        in[1:8] = IP_FIELD_0;
        in[9:16] = IP_FIELD_1;
        in[17:24] = IP_FIELD_2;
        in[25:32] = IP_FIELD_3;

        #(10 * `CYCLE_TIME) 
        $finish;

    end

 endmodule
`undef IP_WIDTH
`undef NUM_RULE_ID
`undef RULE_ID_WIDTH
`undef CYCLE_TIME