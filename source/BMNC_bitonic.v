/*
 * @Author: Yihao Wang
 * @Date: 2020-04-13 01:07:02
 * @LastEditTime: 2020-04-13 01:17:44
 * @LastEditors: Please set LastEditors
 * @Description: a. Bitonic Merge and Neighborhood Checking Network with (log_N + 1) stages
 *               b. Used to merge two monotonic sequence ( one bitonic seqence)
 *                  and find common elements (duplicate twice)
 *               c. The elements in each input sequence must be distinct
 *               d. Step complexity O(log2(N)), N is number of elements in each input sequence
 *               e. The output is N-bit (At most N elelments are duplicate)
 * @FilePath: /EE599_FPGA_package_classification/source/BMNC_bitonic.v
 */
 module BMNC_bitonic #(
     parameter N = 8, // number of elements of each input sequence
     parameter log_N = 3, 
     parameter elements_width = 4 // width of each elements
 )
 (
     input clk, reset,
     input [0:2 * N * elements_width - 1] in,
     output reg [0:N * elements_width - 1] out
 );
    
//// We only need used one BM(2 * N) to sort the input bitonic sequence

    wire [0:2 * N * elements_width - 1] sort_res; // sorting results

    bitonic_merge #(
        .N(2 * N),
        .log_N(log_N + 1),
        .INPUT_WIDTH(elements_width),
        .polarity(0)
    )
    BM
    (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(sort_res)
    );

//// Used neighborhood checker to find common elements

    // Total (2 * N - 1) equality checkers are needed
    wire eq_check [0:2 * N -2]; // 1-bit check results

    genvar i;
    generate 
    begin
        for(i = 0; i < 2 * N - 1; i = i + 1)
        begin : for_loop_0

            // comapre i and (i + 1) elements
            assign eq_check[i] = 
                (sort_res[(i * elements_width)+:elements_width] == sort_res[((i + 1) * elements_width)+:elements_width]);
        end
    end
    endgenerate

    // Finds the common elements based on results of equality checker
    generate 
    begin
        for(i = 0; i < N; i = i + 1)
        begin : for_loop_1
            if(i != N - 1)

                always @(posedge clk)
                begin
                    if(reset) out[(i * elements_width)+:elements_width] <= 0;
                    else 
                    begin
                        out[(i * elements_width)+:elements_width] <= 0;

                        if(eq_check[2 * i] == 1)
                            out[(i * elements_width)+:elements_width] <= sort_res[(2 * i * elements_width)+:elements_width];

                        if(eq_check[2 * i + 1] == 1)
                            out[(i * elements_width)+:elements_width] <= sort_res[((2 * i + 1) * elements_width)+:elements_width];  

                    end
                end

            else // i == N - 1

                always @(posedge clk)
                begin
                    if(reset) out[(i * elements_width)+:elements_width] <= 0;
                    else 
                    begin
                        out[(i * elements_width)+:elements_width] <= 0;

                        if(eq_check[2 * i] == 1)
                            out[(i * elements_width)+:elements_width] <= sort_res[(2 * i * elements_width)+:elements_width];
  
                    end
                end

        end
    end
    endgenerate

 endmodule


