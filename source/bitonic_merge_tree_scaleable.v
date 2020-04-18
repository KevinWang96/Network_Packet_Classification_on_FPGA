/*
 * @Author: Yihao Wang
 * @Date: 2020-04-17 19:03:02
 * @LastEditTime: 2020-04-17 23:00:56
 * @LastEditors: Please set LastEditors
 * @Description: a. A scaleable bitonic merge tree used to merge M RIDS
 *               b. Each input RIDS is assumed to be in ascending order and all elements are distinct
 * @FilePath: /EE599_FPGA_package_classification/source/bitonic_merge_tree_scaleable.v
 */
 module bitonic_merge_tree_scaleable #(
     parameter M = 256, // # of RIDS need to be merge, M msut be 2 ** (x), x is postive integer
     parameter log_M = 8, // log2(M)
     parameter RID_WIDTH = 4, // width of RID in each RIDS
     parameter NUM_RID = 8, // the number of RID in each RIDS
     parameter log_NUM_RID = 3 // log2(NUM_RID)
 )
 (
     input clk, reset, // // positve edge triggering and sync high active reset
     input [0:RIDS_WIDTH * M - 1] in,
     output[0:RIDS_WIDTH - 1] out
 );

    localparam RIDS_WIDTH = RID_WIDTH * NUM_RID; // width of rule ID set, RIDS

    // First we need to reverse all odd RIDS
    wire [0:RIDS_WIDTH - 1] RIDS_r [0:M / 2 - 1];

    genvar i, j;
    generate 
    begin
        for(i = 0; i < M / 2; i = i + 1)
        begin : loop_0
            for(j = 0; j < NUM_RID; j = j + 1)
            begin : loop_1
                assign RIDS_r[i][(j * RID_WIDTH)+:RID_WIDTH] = 
                    in[((2 * i + 1) * RIDS_WIDTH + (NUM_RID - 1 - j) * RID_WIDTH)+:RID_WIDTH];
            end
        end
    end
    endgenerate

    wire [0:RIDS_WIDTH * M - 1] wire_array [0:log_M]; // bunch of wire used to connect each two stage

    generate
    begin
        for(i = 0; i < M; i = i + 1)
        begin : loop_2
            if(i % 2 == 0)
                assign wire_array[0][(i * RIDS_WIDTH)+:RIDS_WIDTH] = in[(i * RIDS_WIDTH)+:RIDS_WIDTH];
            else 
                assign wire_array[0][(i * RIDS_WIDTH)+:RIDS_WIDTH] = RIDS_r[(i - 1) / 2];
        end
    end
    endgenerate

    generate
    begin
        for(i = 0; i < log_M; i = i + 1)
        begin : loop_3
            for(j = 0; j < M / (2 ** (i + 1)); j = j + 1)
            begin :loop_4
                if(i == 0)
                begin

                    BMNC_bitonic #(
                        .N(NUM_RID),
                        .log_N(log_NUM_RID),
                        .elements_width(RID_WIDTH)
                    )
                    BMNC_b
                    (
                        .clk(clk),
                        .reset(reset),
                        .in(wire_array[i][(j * 2 * RIDS_WIDTH)+:2 * RIDS_WIDTH]),
                        .out(wire_array[i + 1][(j * RIDS_WIDTH)+:RIDS_WIDTH])
                    );

                end
                else
                begin

                    BMNC_random #(
                        .N(NUM_RID),
                        .log_N(log_NUM_RID),
                        .elements_width(RID_WIDTH)
                    )
                    BMNC_r
                    (
                        .clk(clk),
                        .reset(reset),
                        .in(wire_array[i][(j * 2 * RIDS_WIDTH)+:2 * RIDS_WIDTH]),
                        .out(wire_array[i + 1][(j * RIDS_WIDTH)+:RIDS_WIDTH])
                    );

                end

            end
        end
    end
    endgenerate

    assign out = wire_array[log_M][0:RIDS_WIDTH - 1];

 endmodule