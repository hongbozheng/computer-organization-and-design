module reg_x_bit #(
    parameter WIDTH = 64\
) (
    input logic clk, reset, load,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

    always_ff @(posedge clk) begin
        if (reset) begin
            data_out <= 'h0;
        end
        else if (load) begin
            data_out <= data_in;
        end
    end
endmodule : reg_x_bit