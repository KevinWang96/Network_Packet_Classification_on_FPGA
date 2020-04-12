/*
 * @Author: Yihao Wang
 * @Date: 2020-04-09 20:41:34
 * @LastEditTime: 2020-04-12 01:31:01
 * @LastEditors: Please set LastEditors
 * @Description: a. Scaleable N-input Bitonic Merge Network, N must be (2 ^ (x)), x is integer
 *               b. Pipelined structure and both input and output are registered
 *               c. Step (time) complexity is O(log(n))  
 *               d. Input sequence must be a bitonic sequence
 *               e. This network will output a monotonic sequence (sorted) based on polarity value
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_merge.v
 */
 module bitonic_merge #(
     parameter N = 16, // the number of inputs log(N) must be an positive integer
     parameter log_N = 4, // clogb2(N)
     parameter INPUT_WIDTH = 4, // the width for each input
     parameter polarity = 0 // 0 means: positive sorting; 1 means negative sorting
 )
 (
     input clk, reset, // positve edge triggering and sync high active reset
     input [0:INPUT_WIDTH * N - 1] in, 
     output [0:INPUT_WIDTH * N - 1] out
 );
    
    // Stage registers: log(NUM_INPUTS) stage registers are needed
    (* ram_style = "block" *) reg [0:INPUT_WIDTH * N - 1] stage_reg [0:log_N]; // log(N) stage registers and one input register

    // Loads data into input register
    always @(posedge clk)
    begin
        if(reset) stage_reg[0] <= 0;
        else stage_reg[0] <= in;
    end

    genvar i, j, k; // for loop index
    
    generate
    begin
        if(polarity == 0)
            for(i = 0; i < log_N; i = i + 1) // there are log_N stages
            begin : i_loop
                for(j = 0; j < 2 ** i; j = j + 1) // there are (2 ** i) sub-sequence
                begin : j_loop
                    for(k = 0; k < N / (2 ** (i + 1)); k = k + 1) // do compare-exchange in each sub-sequence
                    begin : k_loop

                        always @(posedge clk)
                        begin
                            if(reset) 
                            begin
                                stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] <= 0;
                                stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] <= 0;
                            end
                            else
                            begin
                                // if x elements is greater than (x + n / 2) elements, switch them
                                if( stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                    > stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] )
                                begin
                                    stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH];
                                    stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH];
                                end
                                else // don't switch
                                begin
                                    stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH];
                                    stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH];
                                end
                            end
                        end

                    end // end k_loop
                end // end j_loop
            end // end i_loop

        else // polarity == 1
            for(i = 0; i < log_N; i = i + 1) // there are log_N stages
            begin : i_loop
                for(j = 0; j < 2 ** i; j = j + 1) // there are (2 ** i) sub-sequence
                begin : j_loop
                    for(k = 0; k < N / (2 ** (i + 1)); k = k + 1) // do compare-exchange in each sub-sequence
                    begin : k_loop

                        always @(posedge clk)
                        begin
                            if(reset) 
                            begin
                                stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] <= 0;
                                stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] <= 0;
                            end
                            else
                            begin
                                // if x elements is less than or equal to (x + n / 2) elements, switch them
                                if( stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                    < stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] )
                                begin
                                    stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH];
                                    stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH];
                                end
                                else // don't switch
                                begin
                                    stage_reg[i + 1][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k) * INPUT_WIDTH)+:INPUT_WIDTH];
                                    stage_reg[i + 1][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH] 
                                        <= stage_reg[i][((j * N / (2 ** i) + k + N / (2 ** (i + 1))) * INPUT_WIDTH)+:INPUT_WIDTH];
                                end
                            end
                        end

                    end // end k_loop
                end // end j_loop
            end // end 
            
    end
    endgenerate

    assign out =  stage_reg[log_N];

 endmodule