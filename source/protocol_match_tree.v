`define PROTOCOL_WIDTH 8 // 8-bit protocol
`define NUM_RULE_ID 8 // number of rule IDs in rule set
`define RULE_ID_WIDTH 3 // There are 8 rules in rule set, log2(8) = 3
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-07 23:37:34
 * @LastEditTime: 2020-04-08 21:23:23
 * @LastEditors: Please set LastEditors
 * @Description:
 *           a. Exact match tree is used for exact matching of protocol ID
 *           b. The length of protocol ID is assumed to be 8-bit width （0x00 - 0xFF）
 *           c. 5-satge pipeline, both input and output are registered
 *           d. It supports rule set with 8 rules:
 *               rule 0: 0x03
 *               rule 1: 0x06
 *               rule 2: 0x06
 *               rule 3: 0x1C
 *               rule 4: 0xAB
 *               rule 5: 0x65
 *               rule 6: 0x03
 *               rule 7: 0xF4
 * @FilePath: /EE599_FPGA_package_classification/source/protocol_match_tree.v
 */
 module protocol_match_tree (
     input clk, reset, // positive edge triggering and sync hign active reset
     input [0:`PROTOCOL_WIDTH] in, // 1-bit valid bit and 8-bit protocol ID

     // outputs one rule ID set; In each rule ID set, each rule ID is attached with one valid bit
     // The rule ID in each rule ID set must be in order and distint
     // For example: {i, i, i, 2, 5, 6, 7}
     output [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out 
 );

    // input register
    reg [0:`PROTOCOL_WIDTH] in_reg; // 1-bit valid bit and 8-bit protocol ID
    always @(posedge clk)
    begin
       if(reset) in_reg <= 0;
       else in_reg <= in;
    end 

//// Stage #0 ///////////////////////////////////////////////////////////////////////////////////

    reg [0:`PROTOCOL_WIDTH - 1] PROTOCOL_stage0; // The stage register used to registered 8-bit protocol ID

    always @(posedge clk)
    begin
        if(reset) PROTOCOL_stage0 <= 0;
        else PROTOCOL_stage0 <= in_reg[1:`PROTOCOL_WIDTH];
    end

    //// Node #0: compared with 0x1D
    reg node0_l_valid, node0_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x1D = 8'h1d;

    always @(posedge clk)
    begin
        if(reset) {node0_l_valid, node0_r_valid} <= 0;
        else 
        begin
            {node0_l_valid, node0_r_valid} <= 0;

            if(in_reg[0] == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(in_reg[1:`PROTOCOL_WIDTH] >= PROTOCOL_0x1D) node0_r_valid <= 1;
                else node0_l_valid <= 1;
            end 
        end
    end

//// Stage #1 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`PROTOCOL_WIDTH - 1] PROTOCOL_stage1; // The stage register used to registered 8-bit protocol ID   

    always @(posedge clk)
    begin
        if(reset) PROTOCOL_stage1 <= 0;
        else PROTOCOL_stage1 <= PROTOCOL_stage0;
    end

    //// Node #1: compared with 0x06
    reg node1_l_valid, node1_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x06 = 8'h06;

    always @(posedge clk)
    begin
        if(reset) {node1_l_valid, node1_r_valid} <= 0;
        else 
        begin
            {node1_l_valid, node1_r_valid} <= 0;

            if(node0_l_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage0 >= PROTOCOL_0x06) node1_r_valid <= 1;
                else node1_l_valid <= 1;
            end 
        end
    end   

    //// Node #2: compared with 0xAB
    reg node2_l_valid, node2_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0xAB = 8'hab;

    always @(posedge clk)
    begin
        if(reset) {node2_l_valid, node2_r_valid} <= 0;
        else 
        begin
            {node2_l_valid, node2_r_valid} <= 0;

            if(node0_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage0 >= PROTOCOL_0xAB) node2_r_valid <= 1;
                else node2_l_valid <= 1;
            end 
        end
    end 

//// Stage #2 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`PROTOCOL_WIDTH - 1] PROTOCOL_stage2; // The stage register used to registered 8-bit protocol ID   

    always @(posedge clk)
    begin
        if(reset) PROTOCOL_stage2 <= 0;
        else PROTOCOL_stage2 <= PROTOCOL_stage1;
    end

    //// Node #3: compared with 0x03
    reg node3_l_valid, node3_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x03 = 8'h03;

    always @(posedge clk)
    begin
        if(reset) {node3_l_valid, node3_r_valid} <= 0;
        else 
        begin
            {node3_l_valid, node3_r_valid} <= 0;

            if(node1_l_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage1 >= PROTOCOL_0x03) node3_r_valid <= 1;
                else node3_l_valid <= 1;
            end 
        end
    end 

    //// Node #4: compared with 0x07
    reg node4_l_valid, node4_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x07 = 8'h07;

    always @(posedge clk)
    begin
        if(reset) {node4_l_valid, node4_r_valid} <= 0;
        else 
        begin
            {node4_l_valid, node4_r_valid} <= 0;

            if(node1_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage1 >= PROTOCOL_0x07) node4_r_valid <= 1;
                else node4_l_valid <= 1;
            end 
        end
    end

    //// Node #5: compared with 0x65
    reg node5_l_valid, node5_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x65 = 8'h65;

    always @(posedge clk)
    begin
        if(reset) {node5_l_valid, node5_r_valid} <= 0;
        else 
        begin
            {node5_l_valid, node5_r_valid} <= 0;

            if(node2_l_valid == 1) // only if the input  ID is protocol valid, we start to comparing
            begin
                if(PROTOCOL_stage1 >= PROTOCOL_0x65) node5_r_valid <= 1;
                else node5_l_valid <= 1;
            end 
        end
    end

    //// Node #6: compared with 0xF4
    reg node6_l_valid, node6_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0xF4 = 8'hf4;

    always @(posedge clk)
    begin
        if(reset) {node6_l_valid, node6_r_valid} <= 0;
        else 
        begin
            {node6_l_valid, node6_r_valid} <= 0;

            if(node2_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage1 >= PROTOCOL_0xF4) node6_r_valid <= 1;
                else node6_l_valid <= 1;
            end 
        end
    end

    //// Registers left valid bit of node3, node4 and node5 to balance the latency
    reg node3_l_valid_r, node4_l_valid_r, node5_l_valid_r;
    
    always @(posedge clk)
    begin
        if(reset) 
            {node3_l_valid_r, node4_l_valid_r, node5_l_valid_r} <= 0;
        else
        begin
            node3_l_valid_r <= node3_l_valid;
            node4_l_valid_r <= node4_l_valid;
            node5_l_valid_r <= node5_l_valid;
        end
    end

//// Stage #3 /////////////////////////////////////////////////////////////////////////////////// 

    //// Node #7: compared with 0x04
    reg node7_l_valid, node7_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x04 = 8'h04;

    always @(posedge clk)
    begin
        if(reset) {node7_l_valid, node7_r_valid} <= 0;
        else 
        begin
            {node7_l_valid, node7_r_valid} <= 0;

            if(node3_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage2 >= PROTOCOL_0x04) node7_r_valid <= 1;
                else node7_l_valid <= 1;
            end 
        end
    end

    //// Node #8: compared with 0x1C
    reg node8_l_valid, node8_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x1C = 8'h1c;

    always @(posedge clk)
    begin
        if(reset) {node8_l_valid, node8_r_valid} <= 0;
        else 
        begin
            {node8_l_valid, node8_r_valid} <= 0;

            if(node4_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage2 >= PROTOCOL_0x1C) node8_r_valid <= 1;
                else node8_l_valid <= 1;
            end 
        end
    end

    //// Node #9: compared with 0x66
    reg node9_l_valid, node9_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0x66 = 8'h66;

    always @(posedge clk)
    begin
        if(reset) {node9_l_valid, node9_r_valid} <= 0;
        else 
        begin
            {node9_l_valid, node9_r_valid} <= 0;

            if(node5_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage2 >= PROTOCOL_0x66) node9_r_valid <= 1;
                else node9_l_valid <= 1;
            end 
        end
    end

    //// Node #10: compared with 0xAC
    reg node10_l_valid, node10_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0xAC = 8'hac;

    always @(posedge clk)
    begin
        if(reset) {node10_l_valid, node10_r_valid} <= 0;
        else 
        begin
            {node10_l_valid, node10_r_valid} <= 0;

            if(node6_l_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage2 >= PROTOCOL_0xAC) node10_r_valid <= 1;
                else node10_l_valid <= 1;
            end 
        end
    end

    //// Node #11: compared with 0xF5
    reg node11_l_valid, node11_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam PROTOCOL_0xF5 = 8'hf5;

    always @(posedge clk)
    begin
        if(reset) {node11_l_valid, node11_r_valid} <= 0;
        else 
        begin
            {node11_l_valid, node11_r_valid} <= 0;

            if(node6_r_valid == 1) // only if the input protocol ID is valid, we start to comparing
            begin
                if(PROTOCOL_stage2 >= PROTOCOL_0xF5) node11_r_valid <= 1;
                else node11_l_valid <= 1;
            end 
        end
    end

//// Stage #4 /////////////////////////////////////////////////////////////////////////////////// 

    // The rule ID set attached to each leaf node (leaf_node0 to leaf_node8)
    // Each 3-bit rule ID is attached with 1-bit valid bit
    localparam  LEAF_NULL = 32'b0, // NULL rule ID set {}
                LEAF_NODE_1 = 32'b0000_0000_0000_0000_0000_0000_1000_1110, // {0, 6}
                LEAF_NODE_3 = 32'b0000_0000_0000_0000_1001_1011_1100_1101, // {1, 2}
                LEAF_NODE_5 = 32'b0000_0000_0000_0000_0000_0000_0000_1011, // {3}
                LEAF_NODE_7 = 32'b0000_0000_0000_0000_0000_0000_0000_1101, // {5}
                LEAF_NODE_9 = 32'b0000_0000_0000_0000_0000_0000_0000_1100, // {4}
                LEAF_NODE_11 = 32'b0000_0000_0000_0000_0000_0000_0000_1111; // {7}

reg [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out_reg; // the output register
    
    always @(posedge clk)
    begin
        if(reset) out_reg <= 0;
        else
        begin
            out_reg <= LEAF_NULL;

            // Because there should be only one asserted valid bit 
            // Using parallel if statement to implement output MUX
            if(node7_l_valid == 1) out_reg <= LEAF_NODE_1;
            if(node4_l_valid_r == 1) out_reg <= LEAF_NODE_3;
            if(node8_r_valid == 1) out_reg <= LEAF_NODE_5;
            if(node9_l_valid == 1) out_reg <= LEAF_NODE_7;
            if(node10_l_valid == 1) out_reg <= LEAF_NODE_9;
            if(node11_l_valid == 1) out_reg <= LEAF_NODE_11;

        end
    end          

    // Generates output
    assign out = out_reg;

endmodule 
`undef PORT_WIDTH
`undef NUM_RULE_ID
`undef RULE_ID_WIDTH 