module mux_4_to_1_x_bit #(
    parameter WIDTH = 64
) (
    input logic [WIDTH-1:0] A, B, C, D,
    input logic [1:0] select,
    output logic [WIDTH-1:0] F
);
    assign F = select[1] ? (select[0] ? D : C) : (select[0] ? B : A);
endmodule : mux_4_to_1_x_bit