/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER.
A module to help your CPU (which likes to deal with 4 bytes
at a time) talk to your cache (which likes to deal with 32
bytes at a time).*/

module bus_adapter (
    input [31:0] address,
    input [255:0] mem_rdata256,
    input [31:0] mem_wdata,
    input [3:0] mem_byte_enable,
    output [31:0] mem_rdata,
    output [255:0] mem_wdata256,
    output logic [31:0] mem_byte_enable256
);

    assign mem_rdata = mem_rdata256[(32*address[4:2]) +: 32];
    assign mem_wdata256 = {8{mem_wdata}};
    assign mem_byte_enable256 = {28'h0, mem_byte_enable} << (address[4:2]*4);

endmodule : bus_adapter