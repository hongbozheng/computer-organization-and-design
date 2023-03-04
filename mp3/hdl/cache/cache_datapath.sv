/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
) (
    input logic clk,
    input logic rst,
    input logic ld_way_0_valid, way_0_valid_in,
    input logic ld_way_1_valid, way_1_valid_in,
    input logic ld_way_0_dirty, way_0_dirty_in,
    input logic ld_way_1_dirty, way_1_dirty_in,
    input logic ld_way_0_tag, ld_way_1_tag,
    input logic [1:0] way_0_w_en_mux_sel, way_1_w_en_mux_sel,
    input logic way_0_data_in_mux_sel, way_1_data_in_mux_sel,
    input logic ld_lru, lru_in,
    input logic [31:0] mem_address,         /* memory system address for read/write */
    input logic [s_mask-1:0] mem_byte_enable256,
    input logic [s_line-1:0] mem_wdata256,  /* 256-bit data bus CPU -> Bus Adaptor -> Cache */
    input logic pmem_addr_mux_sel,          /* TODO: ! */
    input logic [255:0] pmem_rdata,         /* 256-bit data bus Phys Mem -> Cache */
    output logic way_0_valid_out, way_1_valid_out,
    output logic way_0_dirty_out, way_1_dirty_out,
    output logic hit, way_0_hit, way_1_hit,
    output logic lru_out,
    output logic [s_line-1:0] mem_rdata256, /* 256-bit data bus Cache -> Bus Adaptor -> CPU */
    output logic [31:0] pmem_address,       /* phys memory address for read/write */
    output logic [255:0] pmem_wdata         /* 256-bit data bus cache -> phys Mem */
);

/*************************** Intermediate Signals ****************************/
    logic [s_tag-1:0] way_0_tag, way_1_tag;
    logic [s_line-1:0] way_0_data_in, way_0_data_out;
    logic [s_line-1:0] way_1_data_in, way_1_data_out;
    logic [s_mask-1:0] way_0_w_en_mux_out, way_1_w_en_mux_out;
    logic [31:0] way_addr_mux_out;
/*****************************************************************************/

    assign way_0_hit = (way_0_valid_out && (way_0_tag == mem_address[31:8]));
    assign way_1_hit = (way_1_valid_out && (way_1_tag == mem_address[31:8]));
    assign hit = way_0_hit | way_1_hit;
    /* cache data_out mux (send to CPU) */
    assign mem_rdata256 = way_0_hit ? way_0_data_out : way_1_data_out;
    /* way-0 cache data_in mux (1'b0 CPU || 1'b1 pmem) */
    assign way_0_data_in = way_0_data_in_mux_sel ? pmem_rdata : mem_wdata256;
    /* way-1 cache data_in mux (1'b0 CPU || 1'b1 pmem) */
    assign way_1_data_in = way_1_data_in_mux_sel ? pmem_rdata : mem_wdata256;
    /* cache way-? address mux (1'b0 way-0 || 1'b1 way-1) */
    assign way_addr_mux_out = lru_out ? {way_1_tag, mem_address[7:5], 5'h0} : {way_0_tag, mem_address[7:5], 5'h0};
    /* pmem addr mux (1'b0 CPU || 1'b1 dirty) */
    assign pmem_address = pmem_addr_mux_sel ? way_addr_mux_out : {mem_address[31:5], 5'h0};
    /* cacheline adaptor line_i mux */
    assign pmem_wdata = lru_out ? way_1_data_out : way_0_data_out;

/***************************** Cache & LRU ***********************************/
    cache_1_way way_0 (
        .clk(clk),
        .rst(rst),
        .ld_valid(ld_way_0_valid),
        .valid_in(way_0_valid_in),
        .ld_dirty(ld_way_0_dirty),
        .dirty_in(way_0_dirty_in),
        .ld_tag(ld_way_0_tag),
        .tag_in(mem_address[31:8]),
        .idx(mem_address[7:5]),
        .write_en(way_0_w_en_mux_out),
        .data_in(way_0_data_in),
        .valid_out(way_0_valid_out),
        .dirty_out(way_0_dirty_out),
        .tag_out(way_0_tag),
        .data_out(way_0_data_out)
    );

    cache_1_way way_1 (
        .clk(clk),
        .rst(rst),
        .ld_valid(ld_way_1_valid),
        .valid_in(way_1_valid_in),
        .ld_dirty(ld_way_1_dirty),
        .dirty_in(way_1_dirty_in),
        .ld_tag(ld_way_1_tag),
        .tag_in(mem_address[31:8]),
        .idx(mem_address[7:5]),
        .write_en(way_1_w_en_mux_out),
        .data_in(way_1_data_in),
        .valid_out(way_1_valid_out),
        .dirty_out(way_1_dirty_out),
        .tag_out(way_1_tag),
        .data_out(way_1_data_out)
    );

    array lru (
        .clk(clk),
        .rst(rst),
        .read(1'b1),
        .load(ld_lru),
        .rindex(mem_address[7:5]),
        .windex(mem_address[7:5]),
        .datain(lru_in),
        .dataout(lru_out)
    );
/*****************************************************************************/

/******************************** Muxes **************************************/
    always_comb begin : MUXES
        /* way-0 write enable mux */
        unique case (way_0_w_en_mux_sel)
            2'b00: way_0_w_en_mux_out = {32{1'b0}};         /* write none */
            2'b01: way_0_w_en_mux_out = {32{1'b1}};         /* write all  */
            2'b10: way_0_w_en_mux_out = mem_byte_enable256; /* cpu  */
            default: way_0_w_en_mux_out = {32{1'b0}};
        endcase
        /* way-1 write enable mux */
        unique case (way_1_w_en_mux_sel)
            2'b00: way_1_w_en_mux_out = {32{1'b0}};         /* write none */
            2'b01: way_1_w_en_mux_out = {32{1'b1}};         /* write all  */
            2'b10: way_1_w_en_mux_out = mem_byte_enable256; /* cpu  */
            default: way_1_w_en_mux_out = {32{1'b0}};
        endcase
    end
/*****************************************************************************/

endmodule : cache_datapath