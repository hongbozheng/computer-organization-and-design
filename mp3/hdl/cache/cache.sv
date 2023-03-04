/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
) (
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

/*************************** Intermediate Signals ****************************/
    logic ld_way_0_tag, ld_way_1_tag;
    logic ld_way_0_valid, ld_way_1_valid;
    logic ld_way_0_dirty, ld_way_1_dirty;
    logic [1:0] way_0_w_en_mux_sel, way_1_w_en_mux_sel;
    logic way_0_data_in_mux_sel, way_1_data_in_mux_sel;
    logic ld_lru;
    logic [s_mask-1:0] mem_byte_enable256;
    logic [s_line-1:0] mem_wdata256;
    logic pmem_addr_mux_sel;
    logic hit, way_0_hit, way_1_hit;
    logic [s_line-1:0] mem_rdata256;
    logic way_0_valid_in_cache, way_1_valid_in_cache;
    logic way_0_dirty_in_cache, way_1_dirty_in_cache;
    logic way_0_valid_out_cache, way_1_valid_out_cache;
    logic way_0_dirty_out_cache, way_1_dirty_out_cache;
    logic lru_in_cache, lru_out_cache;
/*****************************************************************************/

    cache_control control(
        .*,
        .lru_in(lru_out_cache),
        .way_0_dirty_in(way_0_dirty_out_cache),
        .way_1_dirty_in(way_1_dirty_out_cache),
        .way_0_valid_in(way_0_valid_out_cache),
        .way_1_valid_in(way_1_valid_out_cache),
        .lru_out(lru_in_cache),
        .way_0_valid_out(way_0_valid_in_cache),
        .way_1_valid_out(way_1_valid_in_cache),
        .way_0_dirty_out(way_0_dirty_in_cache),
        .way_1_dirty_out(way_1_dirty_in_cache)
    );

    cache_datapath datapath(
        .*,
        .way_0_valid_in(way_0_valid_in_cache),
        .way_1_valid_in(way_1_valid_in_cache),
        .way_0_dirty_in(way_0_dirty_in_cache),
        .way_1_dirty_in(way_1_dirty_in_cache),
        .lru_in(lru_in_cache),
        .lru_out(lru_out_cache),
        .way_0_valid_out(way_0_valid_out_cache),
        .way_1_valid_out(way_1_valid_out_cache),
        .way_0_dirty_out(way_0_dirty_out_cache),
        .way_1_dirty_out(way_1_dirty_out_cache)
    );

    bus_adapter bus_adapter(
        .*,
        .address(mem_address)
    );

endmodule : cache