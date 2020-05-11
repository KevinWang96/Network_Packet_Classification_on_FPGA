/*
 * @Author: Yihao Wang
 * @Date: 2020-04-18 20:48:20
 * @LastEditTime: 2020-05-06 07:12:59
 * @LastEditors: Please set LastEditors
 * @Description: a. The top module of packet classification network
 *               b. Combine range match tree and bitonic merge tree
 * @FilePath: /EE599_FPGA_package_classification/source/packet_classification_top.v
 */
 module packet_classification_top #(
     parameter  M           =   4,
     parameter  N           =   32,
     parameter  FIELD_WIDTH =   32
 )
 (
     clk, 
     reset,
     din,
     dout
 );
    localparam  log2_M  =   $clog2(M);
    localparam  log2_N  =   $clog2(N);
    localparam  RIDS_WIDTH  =   N * (log2_N + 1);  

    input                               clk;
    input                               reset;
    input   [0:M * FIELD_WIDTH - 1]     din;
    output  [0:RIDS_WIDTH - 1]          dout;

    wire    [0:M * RIDS_WIDTH - 1]      temp;

    genvar i;
    generate begin
        for(i = 0; i < M; i = i + 1) begin : for_loop_0

            range_match_tree range_match_tree_inst (
                .clk(clk),
                .reset(reset),
                .in(din[i*FIELD_WIDTH+:FIELD_WIDTH]),
                .out(temp[i*RIDS_WIDTH+:RIDS_WIDTH])
            );
        end
    end
    endgenerate
    

    bitonic_merge_tree_scalable #(
        .M(M),
        .log_M(log2_M),
        .RID_WIDTH(log2_N + 1),
        .NUM_RID(N),
        .log_NUM_RID(log2_N)
    )
    (
        .clk(clk),
        .reset(reset),
        .in(temp),
        .out(dout)
    );

 endmodule