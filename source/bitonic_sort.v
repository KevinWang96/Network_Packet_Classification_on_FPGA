/*
 * @Author: Yihao Wang
 * @Date: 2020-04-11 22:15:04
 * @LastEditTime: 2020-04-12 02:03:15
 * @LastEditors: Please set LastEditors
 * @Description: a. Bitonic sort tree used to sort a sequence with random order
 *               b. This tree output a monotinic sequence (ascending or descending) based on polarity
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_sort.v
 */
 module bitonic_sort #(
     parameter N = 16, // log2(N) must be a positive integer
     parameter log_N = 4, // log2(N) 
     parameter INPUT_WIDTH = 4, // width of each input element
     parameter polarity = 0 // 0 means: positive sorting; 1 means negative sorting
 )
 (
     input clk, reset, // positve edge triggering and sync high active reset
     input [0:N * INPUT_WIDTH - 1] in,
     output [0:N * INPUT_WIDTH - 1] out
 );

    // Array of wire used to connect two stages
    wire [0:N * INPUT_WIDTH - 1] stage_wire [0:log_N]; 

    assign stage_wire[0] = in;

    genvar i, j;
    generate 
    begin
        for(i = 0; i < log_N; i = i + 1)
        begin : loop_0
            for(j = 0; j < N / (2 ** (i + 1)); j = j + 1)
            begin : loop_1

                bitonic_merge #(
                    .N(2 ** (i + 1)),
                    .log_N(i + 1),
                    .INPUT_WIDTH(INPUT_WIDTH),
                    .polarity(j % 2)
                )
                BM_cell
                (
                    .clk(clk),
                    .reset(reset),
                    .in(stage_wire[i][(2 ** (i + 1) * j * INPUT_WIDTH)+:2 ** (i + 1) * INPUT_WIDTH]),
                    .out(stage_wire[i + 1][(2 ** (i + 1) * j * INPUT_WIDTH)+:2 ** (i + 1) * INPUT_WIDTH])
                );
            
            end
        end
    end
    endgenerate
    
    assign out = stage_wire[log_N];

 endmodule
