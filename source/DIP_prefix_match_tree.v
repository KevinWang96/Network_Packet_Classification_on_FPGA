`define IP_WIDTH 32 // containing 4 domains, each domain is 8-bit width
`define NUM_RULE_ID 8 // number of rule IDs in rule set
`define RULE_ID_WIDTH 3 // There are 8 rules in rule set, log2(8) = 3
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-07 15:54:16
 * @LastEditTime: 2020-04-08 21:23:45
 * @LastEditors: Please set LastEditors
 * @Description: 
 *           a. Prefix match tree is used for longest prefix matching of destination IP
 *           b. The length of DIP is assumed to be 32-bit （0.0.0.0 - 255.255.255.255）
 *           c. 5-satge pipeline, both input and output are registered
 *           d. It supports rule set with 8 rules:
 *               rule 0: 213.0.0.0-64
 *               rule 1: 213.0.0.65-255
 *               rule 2: 213.0-32.0-255.0-255
 *               rule 3: 213.33-128.0-255.0-255
 *               rule 4: 213.128.0-128.0-255
 *               rule 5: 213.128.129-255.0-255
 *               rule 6: 213-214.0-255.0-255.0-255
 *               rule 7: 213-255.0-255.0-255.0-255
 * @FilePath: /EE599_FPGA_package_classification/source/DIP_prefix_match_tree.v
 */
module DIP_prefix_match_tree (
     input clk, reset, // sync high active reset and positive clk edge triggering
     input [0:`IP_WIDTH] in, // 1-bit(MSB) valid bit and 32-bit IP input

     // outputs one rule ID set; In each rule ID set, each rule ID is attached with one valid bit
     // The rule ID in each rule ID set must be in order and distint
     // For example: {i, i, i, 2, 5, 6, 7}
     output [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out 
);

    // input register
    reg [0:`IP_WIDTH] in_reg; // 1-bit valid bit and 32-bit IP
    always @(posedge clk)
    begin
       if(reset) in_reg <= 0;
       else in_reg <= in;
    end  

//// Stage #0 ///////////////////////////////////////////////////////////////////////////////////

    reg [0:`IP_WIDTH - 1] IP_stage0; // The stage register used to registered 32-bit IP 

    always @(posedge clk)
    begin
        if(reset) IP_stage0 <= 0;
        else IP_stage0 <= in_reg[1:`IP_WIDTH];
    end

    //// Node #0: compared with 213.33.0.0
    reg node0_l_valid, node0_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_33_0_0 = 32'hd5_21_00_00;

    always @(posedge clk)
    begin
        if(reset) {node0_l_valid, node0_r_valid} <= 0;
        else 
        begin
            {node0_l_valid, node0_r_valid} <= 0;

            if(in_reg[0] == 1) // only if the input IP is valid, we start to comparing
            begin
                if(in_reg[1:`IP_WIDTH] >= IP_213_33_0_0) node0_r_valid <= 1;
                else node0_l_valid <= 1;
            end 
        end
    end

//// Stage #1 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`IP_WIDTH - 1] IP_stage1; // The stage register used to registered 32-bit IP     

    always @(posedge clk)
    begin
        if(reset) IP_stage1 <= 0;
        else IP_stage1 <= IP_stage0;
    end

    //// Node #1: compared with 213.0.0.65
    reg node1_l_valid, node1_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_0_0_65 = 32'hd5_00_00_41;

    always @(posedge clk)
    begin
        if(reset) {node1_l_valid, node1_r_valid} <= 0;
        else 
        begin
            {node1_l_valid, node1_r_valid} <= 0;

            if(node0_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage0 >= IP_213_0_0_65) node1_r_valid <= 1;
                else node1_l_valid <= 1;
            end 
        end
    end   

    //// Node #2: compared with 213.128.129.0
    reg node2_l_valid, node2_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_128_129_0 = 32'hd5_80_81_00;

    always @(posedge clk)
    begin
        if(reset) {node2_l_valid, node2_r_valid} <= 0;
        else 
        begin
            {node2_l_valid, node2_r_valid} <= 0;

            if(node0_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage0 >= IP_213_128_129_0) node2_r_valid <= 1;
                else node2_l_valid <= 1;
            end 
        end
    end 

//// Stage #2 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`IP_WIDTH - 1] IP_stage2; // The stage register used to registered 32-bit IP     

    always @(posedge clk)
    begin
        if(reset) IP_stage2 <= 0;
        else IP_stage2 <= IP_stage1;
    end

    //// Node #3: compared with 213.0.0.0
    reg node3_l_valid, node3_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_0_0_0 = 32'hd5_00_00_00;

    always @(posedge clk)
    begin
        if(reset) {node3_l_valid, node3_r_valid} <= 0;
        else 
        begin
            {node3_l_valid, node3_r_valid} <= 0;

            if(node1_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_213_0_0_0) node3_r_valid <= 1;
                else node3_l_valid <= 1;
            end 
        end
    end 

    //// Node #4: compared with 213.0.1.0
    reg node4_l_valid, node4_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_0_1_0 = 32'hd5_00_01_00;

    always @(posedge clk)
    begin
        if(reset) {node4_l_valid, node4_r_valid} <= 0;
        else 
        begin
            {node4_l_valid, node4_r_valid} <= 0;

            if(node1_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_213_0_1_0) node4_r_valid <= 1;
                else node4_l_valid <= 1;
            end 
        end
    end

    //// Node #5: compared with 213.128.0.0
    reg node5_l_valid, node5_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_128_0_0 = 32'hd5_80_00_00;

    always @(posedge clk)
    begin
        if(reset) {node5_l_valid, node5_r_valid} <= 0;
        else 
        begin
            {node5_l_valid, node5_r_valid} <= 0;

            if(node2_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_213_128_0_0) node5_r_valid <= 1;
                else node5_l_valid <= 1;
            end 
        end
    end

    //// Node #6: compared with 213.129.0.0
    reg node6_l_valid, node6_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_213_129_0_0 = 32'hd5_81_00_00;

    always @(posedge clk)
    begin
        if(reset) {node6_l_valid, node6_r_valid} <= 0;
        else 
        begin
            {node6_l_valid, node6_r_valid} <= 0;

            if(node2_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_213_129_0_0) node6_r_valid <= 1;
                else node6_l_valid <= 1;
            end 
        end
    end

    //// Registers left and right valid bit of node3, node4, node5 and node6 to balance the latency
    reg node3_l_valid_r, node3_r_valid_r, node4_l_valid_r, node4_r_valid_r, 
        node5_l_valid_r, node5_r_valid_r, node6_l_valid_r;
    
    always @(posedge clk)
    begin
        if(reset) 
            {node3_l_valid_r, node3_r_valid_r, node4_l_valid_r, node4_r_valid_r,
            node5_l_valid_r, node5_r_valid_r, node6_l_valid_r} <= 0;
        else
        begin
            {node3_l_valid_r, node3_r_valid_r} <= {node3_l_valid, node3_r_valid};
            {node4_l_valid_r, node4_r_valid_r} <= {node4_l_valid, node4_r_valid};
            {node5_l_valid_r, node5_r_valid_r} <= {node5_l_valid, node5_r_valid};
            node6_l_valid_r <= node6_l_valid;
        end
    end

//// Stage #3 /////////////////////////////////////////////////////////////////////////////////// 

    //// Node #7: compared with 215.0.0.0
    reg node7_l_valid, node7_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_215_0_0_0 = 32'hd7_00_00_00;

    always @(posedge clk)
    begin
        if(reset) {node7_l_valid, node7_r_valid} <= 0;
        else 
        begin
            {node7_l_valid, node7_r_valid} <= 0;

            if(node6_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_215_0_0_0) node7_r_valid <= 1;
                else node7_l_valid <= 1;
            end 
        end
    end

//// Stage #4 /////////////////////////////////////////////////////////////////////////////////// 

    // The rule ID set attached to each leaf node (leaf_node0 to leaf_node8)
    // Each 3-bit rule ID is attached with 1-bit valid bit
    localparam  LEAF_NODE_0 = 32'b0, // NULL rule ID set, {}
                LEAF_NODE_1 = 32'b0000_0000_0000_0000_1000_1010_1110_1111, // {0, 2, 6, 7}
                LEAF_NODE_2 = 32'b0000_0000_0000_0000_1001_1010_1110_1111, // {1, 2, 6, 7}
                LEAF_NODE_3 = 32'b0000_0000_0000_0000_0000_1010_1110_1111, // {2, 6, 7}
                LEAF_NODE_4 = 32'b0000_0000_0000_0000_0000_1011_1110_1111, // {3, 6, 7}
                LEAF_NODE_5 = 32'b0000_0000_0000_0000_1011_1100_1110_1111, // {3, 4, 6, 7}
                LEAF_NODE_6 = 32'b0000_0000_0000_0000_1011_1101_1110_1111, // {3, 5, 6, 7}
                LEAF_NODE_7 = 32'b0000_0000_0000_0000_0000_0000_1110_1111, // {6, 7}
                LEAF_NODE_8 = 32'b0000_0000_0000_0000_0000_0000_0000_1111; // {7}

reg [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out_reg; // the output register
    
    always @(posedge clk)
    begin
        if(reset) out_reg <= 0;
        else
        begin
            out_reg <= 0;

            // Because there should be only one asserted valid bit 
            // Using parallel if statement to implement output MUX
            if(node3_l_valid_r == 1) out_reg <= LEAF_NODE_0;
            if(node3_r_valid_r == 1) out_reg <= LEAF_NODE_1;
            if(node4_l_valid_r == 1) out_reg <= LEAF_NODE_2;
            if(node4_r_valid_r == 1) out_reg <= LEAF_NODE_3;
            if(node5_l_valid_r == 1) out_reg <= LEAF_NODE_4;
            if(node5_r_valid_r == 1) out_reg <= LEAF_NODE_5;
            if(node6_l_valid_r == 1) out_reg <= LEAF_NODE_6;
            if(node7_l_valid == 1) out_reg <= LEAF_NODE_7;
            if(node7_r_valid == 1) out_reg <= LEAF_NODE_8;

        end
    end          

    // Generates output
    assign out = out_reg;

endmodule 
`undef IP_WIDTH
`undef NUM_RULE_ID
`undef RULE_ID_WIDTH