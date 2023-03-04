module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

/*************************** Intermediate Signals ****************************/
    logic mem_read;                 /* cpu -> cache */
    logic mem_write;                /* cpu -> cache */
    logic [31:0] mem_address;       /* cpu -> cache */
    logic [3:0] mem_byte_enable;    /* cpu -> cache */
    logic [31:0] mem_wdata;         /* cpu -> cache */
    logic [255:0] pmem_rdata_cache; /* cacheline adaptor -> cache */
    logic pmem_resp_cache;          /* cacheline adaptor -> cache */
    logic [31:0] mem_rdata;         /* cache -> cpu */
    logic mem_resp;                 /* cache -> cpu */
    logic pmem_read_cache;          /* cache -> cacheline adaptor */
    logic pmem_write_cache;         /* cache -> cacheline adaptor */
    logic [31:0] pmem_address_cache;/* cache -> cacheline adaptor */
    logic [255:0] pmem_wdata_cache; /* cache -> cacheline adaptor*/

/*****************************************************************************/

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(.*);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk(clk),
    .rst(rst),
    .mem_read(mem_read),                /* cpu -> cache */
    .mem_write(mem_write),              /* cpu -> cache */
    .mem_address(mem_address),          /* cpu -> cache */
    .mem_byte_enable(mem_byte_enable),  /* cpu -> cache */
    .mem_wdata(mem_wdata),              /* cpu -> cache */
    .pmem_rdata(pmem_rdata_cache),      /* cacheline adaptor -> cache */
    .pmem_resp(pmem_resp_cache),        /* cacheline adaptor -> cache */
    .mem_rdata(mem_rdata),              /* cache -> cpu */
    .mem_resp(mem_resp),                /* cache -> cpu */
    .pmem_read(pmem_read_cache),        /* cache -> cacheline adaptor */
    .pmem_write(pmem_write_cache),      /* cache -> cacheline adaptor */
    .pmem_address(pmem_address_cache),  /* cache -> cacheline adaptor */
    .pmem_wdata(pmem_wdata_cache)       /* cache -> cacheline adaptor */
);

// Hint: What do you need to interface between cache and main memory?
cacheline_adaptor cacheline_adaptor (
    .clk(clk),
    .reset_n(~rst),
    .read_i(pmem_read_cache),       /* cache -> cacheline adaptor */
    .write_i(pmem_write_cache),     /* cache -> cacheline adaptor */
    .address_i(pmem_address_cache), /* cache -> cacheline adaptor */
    .line_i(pmem_wdata_cache),      /* cache -> cacheline adaptor */
    .burst_i(pmem_rdata),           /* phys mem -> cacheline adaptor */
    .resp_i(pmem_resp),             /* phys mem -> cacheline adaptor */
    .line_o(pmem_rdata_cache),      /* cacheline adaptor -> cache */
    .resp_o(pmem_resp_cache),       /* cacheline adaptor -> cache */
    .read_o(pmem_read),             /* cacheline adaptor -> phys mem */
    .write_o(pmem_write),           /* cacheline adaptor -> phys mem */
    .address_o(pmem_address),       /* cacheline adaptor -> phys mem */
    .burst_o(pmem_wdata)            /* cacheline adaptor -> phys mem */
);

endmodule : mp3