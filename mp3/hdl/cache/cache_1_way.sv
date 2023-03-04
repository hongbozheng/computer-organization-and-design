module cache_1_way #(
    parameter s_offset = 5,
    parameter s_index = 3,
    parameter s_tag = 32 - s_offset - s_index,
    parameter s_mask = 2**s_offset,
    parameter s_line = 8*s_mask
) (
    input logic clk,
    input logic rst,
    input logic ld_valid, valid_in,
    input logic ld_dirty, dirty_in,
    input logic ld_tag,
    input logic [s_tag-1:0] tag_in,
    input logic [s_index-1:0] idx,
    input logic [s_mask-1:0] write_en,
    input logic [s_line-1:0] data_in,
    output logic valid_out,
    output logic dirty_out,
    output logic [s_tag-1:0] tag_out,
    output logic [s_line-1:0] data_out
);

    array valid_arr (
        .clk(clk),
        .rst(rst),
        .read(1'b1),
        .load(ld_valid),
        .rindex(idx),
        .windex(idx),
        .datain(valid_in),
        .dataout(valid_out)
    );

    array dirty_arr (
        .clk(clk),
        .rst(rst),
        .read(1'b1),
        .load(ld_dirty),
        .rindex(idx),
        .windex(idx),
        .datain(dirty_in),
        .dataout(dirty_out)
    );

    array #(.s_index(3), .width(24)) tag_arr (
        .clk(clk),
        .rst(rst),
        .read(1'b1),
        .load(ld_tag),
        .rindex(idx),
        .windex(idx),
        .datain(tag_in),
        .dataout(tag_out)
    );

    data_array data_arr (
        .clk(clk),
        // .rst(rst),
        .read(1'b1),
        .write_en(write_en),
        .rindex(idx),
        .windex(idx),
        .datain(data_in),
        .dataout(data_out)
    );

endmodule : cache_1_way