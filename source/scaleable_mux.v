/*
 * @Author: Yihao Wang
 * @Date: 2020-04-10 18:50:45
 * @LastEditTime: 2020-04-10 19:03:14
 * @LastEditors: Please set LastEditors
 * @Description: A scaleable (data_width) bits N-to-1 MUX 
 * @FilePath: /EE599_FPGA_package_classification/source/scaleable_mux.v
 */
 module scaleable_mux #(
     parameter N = 8,
     parameter sel_width = 3, // sel_width should be integer that greater than or equal to log2(N)
     parameter data_width 8
 )
 (
     input [0:N * data_width - 1] in,
     input [0:sel_width - 1] sel,
     output [0:data_width - 1] out
 );

    // Generates the outputs
    assign out = in[(sel * data_width)+:data_width];

 endmodule
