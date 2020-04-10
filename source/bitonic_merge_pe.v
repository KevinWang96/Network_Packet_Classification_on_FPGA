`define RIDS_WIDTH 32 // the width of rule ID set
`define NUM_RULE_ID 8 // number of rule IDs in rule set
/*
 * @Author: Yihao Wang
 * @Date: 2020-04-08 21:25:30
 * @LastEditTime: 2020-04-09 02:26:26
 * @LastEditors: Please set LastEditors
 * @Description: a. Processing element of bitonic merging tree
 *               b. Inputs two 8-rule rule ID set, output the commom rule IDs in these two set
 *               c. The input rule ID must be in a bitonic fashion
 *               d. The bitonic sort network will sort input rule IDs 
 *                  and neighborhood checker will find common rule ID based on sorted rule IDs.
 *              
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_merge_pe.v
 */
 module bitonic_merge_pe (
     input clk, reset, // sync high active reset and positive clk edge triggering
     input [0:2 * `RIDS_WIDTH - 1] in; // inputs two RIDS and they must be in bitonic fashion
     output [0:`RIDS_WIDTH - 1] out; // outputs at most one RIDS width
 );
    
    // input register
    reg [0:2 * `RIDS_WIDTH - 1] in_reg;
    always @(posedge clk)
    begin
        if(reset) in_reg <= 0;
        else in_reg <= in;
    end

//// Stage #0 ///////////////////////////////////////////////////////////////////////////////////

    reg [0:2 * `RIDS_WIDTH - 1] stage_reg_0;

    always @(posedge clk)
    begin : stage_0
        integer i;
        
        if(reset) stage_reg_0 <= 0;
        else
            // Compare i and (i + `NUM_RULE_ID) elements
            for(i = 0; i < `NUM_RULE_ID; i = i + 1)
            begin
                if(in_reg[(i * 4)+:4] > in_reg[((i + `NUM_RULE_ID) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_0[(i * 4)+:4] <= in_reg[((i + `NUM_RULE_ID) * 4)+:4];
                    stage_reg_0[((i + `NUM_RULE_ID) * 4)+:4] <= in_reg[(i * 4)+:4];
                end
                else
                    stage_reg_0 <= in_reg;
            end
    
    end

//// Stage #1 ///////////////////////////////////////////////////////////////////////////////////

    reg [0:2 * `RIDS_WIDTH - 1] stage_reg_1;

    always @(posedge clk)
    begin : stage_1
        integer i;
        
        if(reset) stage_reg_1 <= 0;
        else
        begin 
            // compare i with (i + `NUM_RULE_ID / 2) elements
            for(i = 0; i < `NUM_RULE_ID / 2; i = i + 1)
            begin
                if(stage_reg_0[(i * 4)+:4] > stage_reg_0[((i + `NUM_RULE_ID / 2) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_1[(i * 4)+:4] <= stage_reg_0[((i + `NUM_RULE_ID / 2) * 4)+:4];
                    stage_reg_1[((i + `NUM_RULE_ID / 2) * 4)+:4] <= stage_reg_0[(i * 4)+:4];
                end
                else
                    stage_reg_1 <= stage_reg_0;
            end
            for(i = `NUM_RULE_ID; i < `NUM_RULE_ID * 1.5; i = i + 1)
            begin
                if(stage_reg_0[(i * 4)+:4] > stage_reg_0[((i + `NUM_RULE_ID / 2) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_1[(i * 4)+:4] <= stage_reg_0[((i + `NUM_RULE_ID / 2) * 4)+:4];
                    stage_reg_1[((i + `NUM_RULE_ID / 2) * 4)+:4] <= stage_reg_0[(i * 4)+:4];
                end
                else
                    stage_reg_1 <= stage_reg_0;
            end
        end
    end 

//// Stage #2 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:2 * `RIDS_WIDTH - 1] stage_reg_2;

    always @(posedge clk)
    begin : stage_2
        integer i;
        
        if(reset) stage_reg_2 <= 0;
        else
        begin 
            // compare i with (i + `NUM_RULE_ID / 4) elements
            for(i = 0; i < `NUM_RULE_ID / 4; i = i + 1)
            begin
                if(stage_reg_1[(i * 4)+:4] > stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_2[(i * 4)+:4] <= stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4];
                    stage_reg_2[((i + `NUM_RULE_ID / 4) * 4)+:4] <= stage_reg_1[(i * 4)+:4];
                end
                else
                    stage_reg_2 <= stage_reg_1;
            end

            for(i = `NUM_RULE_ID * 0.5; i < `NUM_RULE_ID; i = i + 1)
            begin
                if(stage_reg_1[(i * 4)+:4] > stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_2[(i * 4)+:4] <= stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4];
                    stage_reg_2[((i + `NUM_RULE_ID / 4) * 4)+:4] <= stage_reg_1[(i * 4)+:4];
                end
                else
                    stage_reg_2 <= stage_reg_1;
            end

            for(i = `NUM_RULE_ID; i < `NUM_RULE_ID * 1.5; i = i + 1)
            begin
                if(stage_reg_1[(i * 4)+:4] > stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_2[(i * 4)+:4] <= stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4];
                    stage_reg_2[((i + `NUM_RULE_ID / 4) * 4)+:4] <= stage_reg_1[(i * 4)+:4];
                end
                else
                    stage_reg_2 <= stage_reg_1;
            end

            for(i = `NUM_RULE_ID * 1.5; i < 2 * `NUM_RULE_ID; i = i + 1)
            begin
                if(stage_reg_1[(i * 4)+:4] > stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_2[(i * 4)+:4] <= stage_reg_1[((i + `NUM_RULE_ID / 4) * 4)+:4];
                    stage_reg_2[((i + `NUM_RULE_ID / 4) * 4)+:4] <= stage_reg_1[(i * 4)+:4];
                end
                else
                    stage_reg_2 <= stage_reg_1;
            end
        end
    end 

//// Stage #3 /////////////////////////////////////////////////////////////////////////////////// 

    reg [0:2 * `RIDS_WIDTH - 1] stage_reg_3;

    always @(posedge clk)
    begin : stage_3
        integer i;

        if(reset) stage_reg_3 <= 0;
        else
            // compare i with (i + `NUM_RULE_ID / 8) elements
            for(i = 0; i < `NUM_RULE_ID - 1; i = i + 2)
            begin
                if(stage_reg_2[(i * 4)+:4] > stage_reg_2[((i + `NUM_RULE_ID / 8) * 4)+:4])
                begin
                    // switch two elements
                    stage_reg_3[(i * 4)+:4] <= stage_reg_2[((i + `NUM_RULE_ID / 8) * 4)+:4];
                    stage_reg_3[((i + `NUM_RULE_ID / 4) * 4)+:4] <= stage_reg_2[(i * 4)+:4];
                end
                else
                    stage_reg_3 <= stage_reg_2;
            end
        
    end

//// Stage #4 /////////////////////////////////////////////////////////////////////////////////// 
    // Neignborhood Checker: using parallel searching to find common elements in sorted list
    reg [0:`RIDS_WIDTH - 1] stage_reg_4;

    wire check_results [0:2 * `NUM_RULE_ID - 2]; // N - 1 checkers are needed to check N elements

    genvar count;
    generate 
    begin
        for(count = 0; count < 2 * `NUM_RULE_ID - 1; count = count + 1)
        begin : NC
            // Equality checker
            assign check_results[count] = ( (stage_reg_3[(i * 4)+:4] == stage_reg_2[((i + 1) * 4)+:4]) 
                                            && (stage_reg_3[(i * 4) == 1])  );
        end
    end
    endgenerate

    always @(posedge clk)
    begin : stage_4
        integer i;

        if(reset) stage_reg_4 <= 0;
        else
            for(i = 0; i < 2 * `NUM_RULE_ID - 1; i = i + 2)
            begin
                stage_reg_4[((i / 2) * 4)+:4] <= 0;

                if(i == 2 * `NUM_RULE_ID - 2) // if i == 14
                begin
                    if(check_results[i] == 1)
                        stage_reg_4[((i / 2) * 4)+:4] <= stage_reg_3[(i * 4)+:4];
                end
                else
                begin
                    if((check_results[i] == 1) && (check_results[i + 1] == 0))
                        stage_reg_4[((i / 2) * 4)+:4] <= stage_reg_3[(i * 4)+:4]; 

                    if((check_results[i + 1] == 1) && (check_results[i] == 0))
                        stage_reg_4[((i / 2) * 4)+:4] <= stage_reg_3[((i + 1) * 4)+:4]; 
                end
            end
    end

//// Stage #5 /////////////////////////////////////////////////////////////////////////////////// 
    
    // Becasue there are invalid rule ID (0000) at random location of rule ID set we got in stage 4
    // The valid rule IDs are in order but invalid rule IDs are not in order, for example {x, 2, 3, x, x, 5,9}
    // We need to sort it to make a monotonic which is used by next bitonic_merge_pe, for example {x, x, x, 2, 3, 5, 9}

    reg [0:`RIDS_WIDTH - 1] stage_reg_5;

    always @(posedge clk)
    begin
        if(reset) stage_reg_5 <= 0;
        else
        begin

            stage_reg_5 <= 0;
            
            // using priority MUX network

            

        




