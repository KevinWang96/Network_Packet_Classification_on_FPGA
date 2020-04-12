/*
 * @Author: Yihao Wang
 * @Date: 2020-04-10 18:22:11
 * @LastEditTime: 2020-04-10 21:08:53
 * @LastEditors: Please set LastEditors
 * @Description: a. processing unit of range match tree : min-max finder
 *               b. combinational logic
 *               c. compare input with benchmark and give the comparing results
 * @FilePath: /EE599_FPGA_package_classification/source/range_match_tree_pe.v
 */
 module range_match_tree_pe #(
     parameter data_width = 8
 )
 (
     input [0:data_width - 1] in, 
     input [0:data_width - 1] target, // comparing target with in
     output LT, GTET // comparing results:
                     //     LT: in is less than target
                     //     GTET: in is greater than or equal to target
 );
 
    assign {LT, GTET} = (in < target) ? 2'b10 : 2'b01;

 endmodule 
