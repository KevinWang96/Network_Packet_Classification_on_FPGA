`define PORT_WIDTH 16 // 16-bit port ID
`define NUM_RULE_ID 8 // number of rule IDs in rule set
`define RULE_ID_WIDTH 3 // There are 8 rules in rule set, log2(8) = 3
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-07 20:57:41
 * @LastEditTime: 2020-04-08 21:23:53
 * @LastEditors: Please set LastEditors
 * @Description: 
 *           a. Range match tree is used for range matching of destination port ID
 *           b. The length of SP is assumed to be 16-bit width （0 - 65535）
 *           c. 5-satge pipeline, both input and output are registered
 *           d. It supports rule set with 8 rules:
 *               rule 0: 0 - 1023
 *               rule 1: 256 - 10000
 *               rule 2: 512 - 10000
 *               rule 3: 2048 - 20000
 *               rule 4: 256 - 2048
 *               rule 5: 30000 - 60000
 *               rule 6: 40000 - 65535
 *               rule 7: 0 - 65535
 * @FilePath: /EE599_FPGA_package_classification/source/DP_range_match_tree.v
 */
 module DP_range_match_tree (
     input clk, reset, // positive edge triggering and sync hign active reset
     input [0:`PORT_WIDTH] in, // 1-bit valid bit and 16-bit port ID

     // outputs one rule ID set; In each rule ID set, each rule ID is attached with one valid bit
     // The rule ID in each rule ID set must be in order and distint
     // For example: {i, i, i, 2, 5, 6, 7}
     output [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out   
 );

    // input register
    reg [0:`PORT_WIDTH] in_reg; // 1-bit valid bit and 16-bit port ID
    always @(posedge clk)
    begin
       if(reset) in_reg <= 0;
       else in_reg <= in;
    end   

//// Stage #0 ///////////////////////////////////////////////////////////////////////////////////

    reg [0:`PORT_WIDTH - 1] PORT_stage0; // The stage register used to registered 16-bit port ID

    always @(posedge clk)
    begin
        if(reset) PORT_stage0 <= 0;
        else PORT_stage0 <= in_reg[1:`PORT_WIDTH];
    end

    //// Node #0: compared with 2049
    reg node0_l_valid, node0_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_2049 = 16'h08_01;

    always @(posedge clk)
    begin
        if(reset) {node0_l_valid, node0_r_valid} <= 0;
        else 
        begin
            {node0_l_valid, node0_r_valid} <= 0;

            if(in_reg[0] == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(in_reg[1:`PORT_WIDTH] >= PORT_2049) node0_r_valid <= 1;
                else node0_l_valid <= 1;
            end 
        end
    end

//// Stage #1 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`PORT_WIDTH - 1] PORT_stage1; // The stage register used to registered 16-bit port ID   

    always @(posedge clk)
    begin
        if(reset) PORT_stage1 <= 0;
        else PORT_stage1 <= PORT_stage0;
    end

    //// Node #1: compared with 512
    reg node1_l_valid, node1_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_512 = 16'h02_00;

    always @(posedge clk)
    begin
        if(reset) {node1_l_valid, node1_r_valid} <= 0;
        else 
        begin
            {node1_l_valid, node1_r_valid} <= 0;

            if(node0_l_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage0 >= PORT_512) node1_r_valid <= 1;
                else node1_l_valid <= 1;
            end 
        end
    end   

    //// Node #2: compared with 20001
    reg node2_l_valid, node2_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_20001 = 16'h4e_21;

    always @(posedge clk)
    begin
        if(reset) {node2_l_valid, node2_r_valid} <= 0;
        else 
        begin
            {node2_l_valid, node2_r_valid} <= 0;

            if(node0_r_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage0 >= PORT_20001) node2_r_valid <= 1;
                else node2_l_valid <= 1;
            end 
        end
    end 

//// Stage #2 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`PORT_WIDTH - 1] PORT_stage2; // The stage register used to registered 16-bit port ID   

    always @(posedge clk)
    begin
        if(reset) PORT_stage2 <= 0;
        else PORT_stage2 <= PORT_stage1;
    end

    //// Node #3: compared with 256
    reg node3_l_valid, node3_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_256 = 16'h01_00;

    always @(posedge clk)
    begin
        if(reset) {node3_l_valid, node3_r_valid} <= 0;
        else 
        begin
            {node3_l_valid, node3_r_valid} <= 0;

            if(node1_l_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage1 >= PORT_256) node3_r_valid <= 1;
                else node3_l_valid <= 1;
            end 
        end
    end 

    //// Node #4: compared with 1024
    reg node4_l_valid, node4_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_1024 = 16'h04_00;

    always @(posedge clk)
    begin
        if(reset) {node4_l_valid, node4_r_valid} <= 0;
        else 
        begin
            {node4_l_valid, node4_r_valid} <= 0;

            if(node1_r_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage1 >= PORT_1024) node4_r_valid <= 1;
                else node4_l_valid <= 1;
            end 
        end
    end

    //// Node #5: compared with 10001
    reg node5_l_valid, node5_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_10001 = 16'h27_11;

    always @(posedge clk)
    begin
        if(reset) {node5_l_valid, node5_r_valid} <= 0;
        else 
        begin
            {node5_l_valid, node5_r_valid} <= 0;

            if(node2_l_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage1 >= PORT_10001) node5_r_valid <= 1;
                else node5_l_valid <= 1;
            end 
        end
    end

    //// Node #6: compared with 30000
    reg node6_l_valid, node6_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_30000 = 16'h75_30;

    always @(posedge clk)
    begin
        if(reset) {node6_l_valid, node6_r_valid} <= 0;
        else 
        begin
            {node6_l_valid, node6_r_valid} <= 0;

            if(node2_r_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage1 >= PORT_30000) node6_r_valid <= 1;
                else node6_l_valid <= 1;
            end 
        end
    end

    //// Registers left and right valid bit of node3, node4, node5 and node6 to balance the latency
    reg node3_l_valid_r, node3_r_valid_r, node4_l_valid_r,
        node5_l_valid_r, node5_r_valid_r, node6_l_valid_r;
    
    always @(posedge clk)
    begin
        if(reset) 
            {node3_l_valid_r, node3_r_valid_r, node4_l_valid_r,
            node5_l_valid_r, node5_r_valid_r, node6_l_valid_r} <= 0;
        else
        begin
            {node3_l_valid_r, node3_r_valid_r} <= {node3_l_valid, node3_r_valid};
            node4_l_valid_r <= node4_l_valid;
            {node5_l_valid_r, node5_r_valid_r} <= {node5_l_valid, node5_r_valid};
            node6_l_valid_r <= node6_l_valid;
        end
    end
    
//// Stage #3 /////////////////////////////////////////////////////////////////////////////////// 

    //// Node #7: compared with 2048
    reg node7_l_valid, node7_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_2048 = 16'h08_00;

    always @(posedge clk)
    begin
        if(reset) {node7_l_valid, node7_r_valid} <= 0;
        else 
        begin
            {node7_l_valid, node7_r_valid} <= 0;

            if(node4_r_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage2 >= PORT_2048) node7_r_valid <= 1;
                else node7_l_valid <= 1;
            end 
        end
    end

    //// Node #8: compared with 40000
    reg node8_l_valid, node8_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PORT_40000 = 16'h9c_40;

    always @(posedge clk)
    begin
        if(reset) {node8_l_valid, node8_r_valid} <= 0;
        else 
        begin
            {node8_l_valid, node8_r_valid} <= 0;

            if(node6_r_valid == 1) // only if the input port ID is valid, we start to comparing
            begin
                if(PORT_stage2 >= PORT_40000) node8_r_valid <= 1;
                else node8_l_valid <= 1;
            end 
        end
    end

//// Stage #4 /////////////////////////////////////////////////////////////////////////////////// 

    // The rule ID set attached to each leaf node (leaf_node0 to leaf_node8)
    // Each 3-bit rule ID is attached with 1-bit valid bit
    localparam  LEAF_NODE_0 = 32'b0000_0000_0000_0000_0000_0000_1000_1111, // {0, 7}
                LEAF_NODE_1 = 32'b0000_0000_0000_0000_1000_1001_1100_1111, // {0, 1, 4, 7}
                LEAF_NODE_2 = 32'b0000_0000_0000_1000_1001_1010_1100_1111, // {0, 1, 2, 4, 7}
                LEAF_NODE_3 = 32'b0000_0000_0000_0000_1001_1010_1100_1111, // {1, 2, 4, 7}
                LEAF_NODE_4 = 32'b0000_0000_0000_1001_1010_1011_1100_1111, // {1, 2, 3, 4, 7}
                LEAF_NODE_5 = 32'b0000_0000_0000_0000_1001_1010_1011_1111, // {1, 2, 3, 7}
                LEAF_NODE_6 = 32'b0000_0000_0000_0000_0000_0000_1011_1111, // {3, 7}
                LEAF_NODE_7 = 32'b0000_0000_0000_0000_0000_0000_0000_1111, // {7}
                LEAF_NODE_8 = 32'b0000_0000_0000_0000_0000_0000_1101_1111, // {5, 7}
                LEAF_NODE_9 = 32'b0000_0000_0000_0000_0000_0000_1110_1111, // {6, 7}

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
            if(node7_l_valid == 1) out_reg <= LEAF_NODE_3;
            if(node7_r_valid == 1) out_reg <= LEAF_NODE_4;
            if(node5_l_valid_r == 1) out_reg <= LEAF_NODE_5;
            if(node5_r_valid_r == 1) out_reg <= LEAF_NODE_6;
            if(node6_l_valid_r == 1) out_reg <= LEAF_NODE_7;
            if(node8_l_valid == 1) out_reg <= LEAF_NODE_8;
            if(node8_r_valid == 1) out_reg <= LEAF_NODE_9;

        end
    end          

    // Generates output
    assign out = out_reg;

endmodule 
`undef PORT_WIDTH
`undef NUM_RULE_ID
`undef RULE_ID_WIDTH 