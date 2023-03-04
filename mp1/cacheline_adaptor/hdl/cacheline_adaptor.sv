module cacheline_adaptor (
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

    assign address_o = address_i;
    logic [3:0] load_mem_buf;
    logic [1:0] llc_mux_select;
    logic prev_read_i, reading, writing;

    reg_x_bit #(64) mem_buf_0 (
        .clk(clk),
        .reset(~reset_n),
        .load(load_mem_buf[0]),
        .data_in(burst_i),
        .data_out(line_o[63:0])
    );

    reg_x_bit #(64) mem_buf_1 (
        .clk(clk),
        .reset(~reset_n),
        .load(load_mem_buf[1]),
        .data_in(burst_i),
        .data_out(line_o[127:64])
    );

    reg_x_bit #(64) mem_buf_2 (
        .clk(clk),
        .reset(~reset_n),
        .load(load_mem_buf[2]),
        .data_in(burst_i),
        .data_out(line_o[191:128])
    );

    reg_x_bit #(64) mem_buf_3 (
        .clk(clk),
        .reset(~reset_n),
        .load(load_mem_buf[3]),
        .data_in(burst_i),
        .data_out(line_o[255:192])
    );

    mux_4_to_1_x_bit #(64) llc_mux (
        .A(line_i[63:0]),
        .B(line_i[127:64]),
        .C(line_i[191:128]),
        .D(line_i[255:192]),
        .select(llc_mux_select),
        .F(burst_o)
    );

    typedef enum logic [2:0] {
        state_0,
        state_1,
        state_2,
        state_3,
        finish
    } rw_state;
    rw_state state, next_state;

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            read_o <= 1'b0;
            prev_read_i <= 1'b0;
            state <= state_0;
            reading <= 1'b0;
            writing <= 1'b0;
        end
        else begin
            prev_read_i <= read_i;
            state <= next_state;
        end

        unique case (state)
            state_0: begin
                if (read_i) begin
                    read_o <= 1'b1;
                    reading <= 1'b1;
                end
                else if (write_i) begin
                    write_o <= 1'b1;
                    writing <= 1'b1;
                end
            end
            state_1: begin
                if (reading) begin
                    read_o <= 1'b1;
                end
                else if (writing) begin
                    write_o <= 1'b1;
                end
            end
            state_2: begin
                if (reading) begin
                   read_o <= 1'b1; 
                end
                else if (writing) begin
                    write_o <= 1'b1;
                end
            end
            state_3: begin
                if (reading) begin
                    read_o <= 1'b1;
                end
                else if (writing) begin
                    write_o <= 1'b1;
                end
            end
            finish: begin
                read_o <= 1'b0;
                reading <= 1'b0;
                write_o <= 1'b0;
                writing <= 1'b0;
            end
            default: begin
                read_o <= 1'b0;
                reading <= 1'b0;
                write_o <= 1'b0;
                writing <= 1'b0;
            end
        endcase
    end

    always_comb begin
        next_state = state;
        load_mem_buf = 4'h0;
        llc_mux_select = 2'b00;
        resp_o = 1'b0;

        unique case(state)
            state_0: begin
                if ((resp_i & (prev_read_i & (~read_i))) || (resp_i & write_i)) begin
                    next_state = state_1;
                end
            end
            state_1: begin
                if(reading || writing) begin
                    next_state = state_2;
                end
            end
            state_2: begin
                if(reading || writing) begin
                    next_state = state_3;
                end
            end
            state_3: begin
                if(reading || writing) begin
                    next_state = finish;
                end
            end
            finish: begin
                next_state = state_0;
            end
            default: begin
                next_state = state;
            end
        endcase

        unique case(state)
            state_0: begin
                if(reading) begin
                    load_mem_buf = 4'b0001;
                end
                else if(writing) begin
                    llc_mux_select = 2'b00;
                end
            end
            state_1: begin
                if(reading) begin
                    load_mem_buf = 4'b0010;
                end
                else if(writing) begin
                    llc_mux_select = 2'b01;
                end
            end
            state_2: begin
                if(reading) begin
                    load_mem_buf = 4'b0100;
                end
                else if(writing) begin
                    llc_mux_select = 2'b10;
                end
            end
            state_3: begin
                if(reading) begin
                    load_mem_buf = 4'b1000;
                end
                else if(writing) begin
                    llc_mux_select = 2'b11;
                end
            end
            finish: begin
                load_mem_buf = 4'h0;
                llc_mux_select = 2'b00;
                resp_o = 1'b1;
            end
            default: begin
                load_mem_buf = 4'h0;
                resp_o = 1'b0;
            end
        endcase
    end

endmodule : cacheline_adaptor