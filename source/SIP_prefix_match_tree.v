`define IP_WIDTH 32 // containing 4 domains, each domain is 8-bit width
`define NUM_RULE_ID 8 // number of rule IDs in rule set
`define RULE_ID_WIDTH 3 // There are 8 rules in rule set, log2(8) = 3
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-05 16:28:05
 * @LastEditTime: 2020-04-05 22:57:18
 * @LastEditors: Please set LastEditors
 * @Description: 
 *           a. Prefix match tree is used for longest prefix matching
 *           b. Only responsible for prefix matching for SIP
 *           c. The length of IP is assumed to be 32-bit （0.0.0.0 - 255.255.255.255）
 *           d. It supports rule set with 8 rules:
 *               rule 0: 192.168.0.0-255
 *               rule 1: 192.168.0.32-128
 *               rule 2: 192.168.32-128.0-255
 *               rule 3: 192.168.0-255.0-255
 *               rule 4: 192.200.0-64.0-255
 *               rule 5: 192.128-255.0-255.0-255
 *               rule 6: 192.0-255.0-255.0-255
 *               rule 7: 192-255.0-255.0-255.0-255
 * @FilePath: /EE599_FPGA_package_classification/source/SIP_prefix_match_tree.v
 */
 module SIP_prefix_match_tree (
     input clk, reset, // sync high active reset and positive clk edge triggering
     input [0:`IP_WIDTH] in, // 1-bit valid bit and 32-bit IP input

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

    //// Node #0: compared with 192.168.32.0 
    reg node0_l_valid, node0_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_32_0 = 32'hc0_a8_20_00;

    always @(posedge clk)
    begin
        if(reset) {node0_l_valid, node0_r_valid} <= 0;
        else 
        begin
            {node0_l_valid, node0_r_valid} <= 0;

            if(in_reg[0] == 1) // only if the input IP is valid, we start to comparing
            begin
                if(in_reg[1:`IP_WIDTH] >= IP_192_168_32_0) node0_r_valid <= 1;
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

    //// Node #1: compared with 192.168.0.32
    reg node1_l_valid, node1_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_0_32 = 32'hc0_a8_00_32;

    always @(posedge clk)
    begin
        if(reset) {node1_l_valid, node1_r_valid} <= 0;
        else 
        begin
            {node1_l_valid, node1_r_valid} <= 0;

            if(node0_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage0 >= IP_192_168_0_32) node1_r_valid <= 1;
                else node1_l_valid <= 1;
            end 
        end
    end   

    //// Node #2: compared with 192.200.0.0
    reg node2_l_valid, node2_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_200_0_0 = 32'hc0_c8_00_00;

    always @(posedge clk)
    begin
        if(reset) {node2_l_valid, node2_r_valid} <= 0;
        else 
        begin
            {node2_l_valid, node2_r_valid} <= 0;

            if(node0_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage0 >= IP_192_200_0_0) node2_r_valid <= 1;
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

    //// Node #3: compared with 192.128.0.0
    reg node3_l_valid, node3_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_128_0_0 = 32'hc0_80_00_00;

    always @(posedge clk)
    begin
        if(reset) {node3_l_valid, node3_r_valid} <= 0;
        else 
        begin
            {node3_l_valid, node3_r_valid} <= 0;

            if(node1_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_192_128_0_0) node3_r_valid <= 1;
                else node3_l_valid <= 1;
            end 
        end
    end 

    //// Node #4: compared with 192.168.1.0
    reg node4_l_valid, node4_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_1_0 = 32'hc0_a8_01_00;

    always @(posedge clk)
    begin
        if(reset) {node4_l_valid, node4_r_valid} <= 0;
        else 
        begin
            {node4_l_valid, node4_r_valid} <= 0;

            if(node1_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_192_168_1_0) node4_r_valid <= 1;
                else node4_l_valid <= 1;
            end 
        end
    end

    //// Node #5: compared with 192.168.129.0
    reg node5_l_valid, node5_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_129_0 = 32'hc0_a8_81_00;

    always @(posedge clk)
    begin
        if(reset) {node5_l_valid, node5_r_valid} <= 0;
        else 
        begin
            {node5_l_valid, node5_r_valid} <= 0;

            if(node2_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_192_168_129_0) node5_r_valid <= 1;
                else node5_l_valid <= 1;
            end 
        end
    end

    //// Node #6: compared with 193.0.0.0
    reg node6_l_valid, node6_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_193_0_0_0 = 32'hc1_00_00_00;

    always @(posedge clk)
    begin
        if(reset) {node6_l_valid, node6_r_valid} <= 0;
        else 
        begin
            {node6_l_valid, node6_r_valid} <= 0;

            if(node2_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage1 >= IP_193_0_0_0) node6_r_valid <= 1;
                else node6_l_valid <= 1;
            end 
        end
    end

//// Stage #3 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:`IP_WIDTH - 1] IP_stage3; // The stage register used to registered 32-bit IP     

    always @(posedge clk)
    begin
        if(reset) IP_stage3 <= 0;
        else IP_stage3 <= IP_stage2;
    end

    //// Node #7: compared with 192.0.0.0
    reg node7_l_valid, node7_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_0_0_0 = 32'hc0_00_00_00;

    always @(posedge clk)
    begin
        if(reset) {node7_l_valid, node7_r_valid} <= 0;
        else 
        begin
            {node7_l_valid, node7_r_valid} <= 0;

            if(node3_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_192_0_0_0) node7_r_valid <= 1;
                else node7_l_valid <= 1;
            end 
        end
    end

    //// Node #8: compared with 192.168.0.0
    reg node8_l_valid, node8_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_0_0 = 32'hc0_a8_00_00;

    always @(posedge clk)
    begin
        if(reset) {node8_l_valid, node8_r_valid} <= 0;
        else 
        begin
            {node8_l_valid, node8_r_valid} <= 0;

            if(node3_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_192_168_0_0) node8_r_valid <= 1;
                else node8_l_valid <= 1;
            end 
        end
    end

    //// Node #9: compared with 192.168.0.129
    reg node9_l_valid, node9_r_valid;   // two valid bit used for two kid nodes: left and right
                                        // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_168_0_129 = 32'hc0_a8_00_81;

    always @(posedge clk)
    begin
        if(reset) {node9_l_valid, node9_r_valid} <= 0;
        else 
        begin
            {node9_l_valid, node9_r_valid} <= 0;

            if(node4_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_192_168_0_129) node9_r_valid <= 1;
                else node9_l_valid <= 1;
            end 
        end
    end

    //// Node #10: compared with 192.169.0.0
    reg node10_l_valid, node10_r_valid;   // two valid bit used for two kid nodes: left and right
                                          // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_169_0_0 = 32'hc0_a9_00_00;

    always @(posedge clk)
    begin
        if(reset) {node10_l_valid, node10_r_valid} <= 0;
        else 
        begin
            {node10_l_valid, node10_r_valid} <= 0;

            if(node5_r_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_192_169_0_0) node10_r_valid <= 1;
                else node10_l_valid <= 1;
            end 
        end
    end  

    //// Node #11: compared with 192.200.65.0
    reg node11_l_valid, node11_r_valid;   // two valid bit used for two kid nodes: left and right
                                          // l_valid = 1 means the left kid node will be activated in next stage

    localparam IP_192_200_65_0 = 32'hc0_c8_41_00;

    always @(posedge clk)
    begin
        if(reset) {node11_l_valid, node11_r_valid} <= 0;
        else 
        begin
            {node11_l_valid, node11_r_valid} <= 0;

            if(node6_l_valid == 1) // only if the input IP is valid, we start to comparing
            begin
                if(IP_stage2 >= IP_192_200_65_0) node11_r_valid <= 1;
                else node11_l_valid <= 1;
            end 
        end
    end  

    //// Registers node4_r_valid to balance the latency
    reg node4_r_valid_r;
    always @(posedge clk)
    begin 
        if(reset) node4_r_valid_r <= 0;
        else node4_r_valid_r <= node4_r_valid;
    end

    //// Registers node5_l_valid to balance the latency
    reg node5_l_valid_r;
    always @(posedge clk)
    begin 
        if(reset) node5_l_valid_r <= 0;
        else node5_l_valid_r <= node5_l_valid;
    end

    //// Registers node6_r_valid to balance the latency
    reg node6_r_valid_r;
    always @(posedge clk)
    begin 
        if(reset) node6_r_valid_r <= 0;
        else node6_r_valid_r <= node6_r_valid;
    end

//// Stage #4 /////////////////////////////////////////////////////////////////////////////////// 

    // The rule ID set attached to each leaf node (leaf_node0 to lead_node12)
    // Each 3-bit rule ID is attached with 1-bit valid bit
    localparam  LEAF_NODE_0 = 32'b0, // no rules in this rule ID set
                LEAF_NODE_1 = 32'b0000_0000_0000_0000_0000_0000_1110_1111,
                LEAF_NODE_2 = 32'b0000_0000_0000_0000_0000_1101_1110_1111,
                LEAF_NODE_3 = 32'b0000_0000_0000_0000_1000_1011_1110_1111,
                LEAF_NODE_4 = 32'b0000_0000_0000_1001_1011_1101_1110_1111,
                LEAF_NODE_5 = 32'b0000_0000_0000_1000_1011_1101_1110_1111,
                LEAF_NODE_6 = 32'b0000_0000_0000_0000_1011_1101_1110_1111,
                LEAF_NODE_7 = 32'b0000_0000_0000_1010_1011_1101_1110_1111,
                LEAF_NODE_8 = 32'b0000_0000_0000_0000_1011_1101_1110_1111,
                LEAF_NODE_9 = 32'b0000_0000_0000_0000_0000_1101_1110_1111,
                LEAF_NODE_10 = 32'b0000_0000_0000_0000_1100_1101_1110_1111,
                LEAF_NODE_11 = 32'b0000_0000_0000_0000_0000_1101_1110_1111,
                LEAF_NODE_12 = 32'b0000_0000_0000_0000_0000_0000_0000_1111;

    reg [0:`NUM_RULE_ID + `RULE_ID_WIDTH * `NUM_RULE_ID - 1] out_reg; // the output register
    
    always @(posedge clk)
    begin
        if(reset) out_reg <= 0;
        else
        begin
            out_reg <= 0;

            // Because there should be only one asserted valid bit 
            // Using parallel if statement to implement output MUX
            if(node7_l_valid == 1) out_reg <= LEAF_NODE_0;
            if(node7_r_valid == 1) out_reg <= LEAF_NODE_1;
            if(node8_l_valid == 1) out_reg <= LEAF_NODE_2;
            if(node8_r_valid == 1) out_reg <= LEAF_NODE_3;
            if(node9_l_valid == 1) out_reg <= LEAF_NODE_4;
            if(node9_r_valid == 1) out_reg <= LEAF_NODE_5;
            if(node4_r_valid_r == 1) out_reg <= LEAF_NODE_6;
            if(node5_l_valid_r == 1) out_reg <= LEAF_NODE_7;
            if(node10_l_valid == 1) out_reg <= LEAF_NODE_8;
            if(node10_r_valid == 1) out_reg <= LEAF_NODE_9;
            if(node11_l_valid == 1) out_reg <= LEAF_NODE_10;
            if(node11_r_valid == 1) out_reg <= LEAF_NODE_11; 
            if(node6_r_valid_r == 1) out_reg <= LEAF_NODE_12;

        end
    end          

    // Generates output
    assign out = out_reg;

 endmodule            
`undef IP_WIDTH
`undef NUM_RULE_ID
`undef RULE_ID_WIDTH