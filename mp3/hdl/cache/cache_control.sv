/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    input logic way_0_valid_in, way_1_valid_in,
    input logic way_0_dirty_in, way_1_dirty_in,
    input logic hit, way_0_hit, way_1_hit,
    input logic lru_in,
    input logic mem_read,       /* read from mem from cpu */
    input logic mem_write,      /* write to mem from cpu */
    input logic pmem_resp,      /* phys mem resp from phys mem */
    output logic ld_way_0_valid, way_0_valid_out,
    output logic ld_way_1_valid, way_1_valid_out,
    output logic ld_way_0_dirty, way_0_dirty_out,
    output logic ld_way_1_dirty, way_1_dirty_out,
    output logic ld_way_0_tag, ld_way_1_tag,
    output logic [1:0] way_0_w_en_mux_sel, way_1_w_en_mux_sel,
    output logic way_0_data_in_mux_sel, way_1_data_in_mux_sel,
    output logic ld_lru, lru_out,
    output logic pmem_addr_mux_sel,
    output logic pmem_read,     /* read from phys mem */
    output logic pmem_write,    /* write to phys mem  */
    output logic mem_resp       /* mem resp to cpu    */
);

    typedef enum logic [1:0] {
        idle,
        check,
        write_back,
        allocate
    } cache_state;
    cache_state state, next_state;

    function void set_defaults();
        ld_way_0_valid = 1'b0;
        way_0_valid_out = way_0_valid_in;
        ld_way_1_valid = 1'b0;
        way_1_valid_out = way_1_valid_in;
        ld_way_0_dirty = 1'b0;
        way_0_dirty_out = way_0_dirty_in;
        ld_way_1_dirty = 1'b0;
        way_1_dirty_out = way_1_dirty_in;
        ld_way_0_tag = 1'b0;
        ld_way_1_tag = 1'b0;
        way_0_w_en_mux_sel = 2'b00;     /* write none */
        way_1_w_en_mux_sel = 2'b00;     /* write none */
        way_0_data_in_mux_sel = 1'b0;   /* cpu */
        way_1_data_in_mux_sel = 1'b0;   /* cpu */
        ld_lru = 1'b0;
        lru_out = lru_in;
        pmem_addr_mux_sel = 1'b0;
        pmem_read = 1'b0;
        pmem_write = 1'b0;
        mem_resp = 1'b0;
    endfunction

    always_comb begin : state_actions
        /* default outputs */
        set_defaults();
        /* state actions */
        unique case (state)
            idle: ;
            check: begin
                if (hit) begin
                    if (way_0_hit && mem_write) begin
                        ld_way_0_dirty = 1'b1;
                        way_0_dirty_out = 1'b1;
                        way_0_w_en_mux_sel = 2'b10;
                    end
                    else if (way_1_hit && mem_write) begin
                        ld_way_1_dirty = 1'b1;
                        way_1_dirty_out = 1'b1;
                        way_1_w_en_mux_sel = 2'b10;
                    end
                    ld_lru = 1'b1;
                    lru_out = ~way_1_hit;
                    mem_resp = 1'b1;
                end
            end
            write_back: begin
                pmem_addr_mux_sel = 1'b1;   /* cache way-? addr */
                pmem_write = 1'b1; 
            end
            allocate: begin
                pmem_read = 1'b1;
                pmem_addr_mux_sel = 1'b0;
                if (lru_out == 1'b0) begin
                    ld_way_0_valid = 1'b1;
                    way_0_valid_out = 1'b1;
                    ld_way_0_dirty = 1'b1;
                    way_0_dirty_out = 1'b0;
                    ld_way_0_tag = 1'b1;
                    way_0_w_en_mux_sel = 2'b01;     /* write all */
                    way_0_data_in_mux_sel = 1'b1;   /* read data from phys mem */
                end
                else begin
                    ld_way_1_valid = 1'b1;
                    way_1_valid_out = 1'b1;
                    ld_way_1_dirty = 1'b1;
                    way_1_dirty_out = 1'b0;
                    ld_way_1_tag = 1'b1;
                    way_1_w_en_mux_sel = 2'b01;     /* write all */
                    way_1_data_in_mux_sel = 1'b1;   /* read data from phys mem */
                end
            end
            default: ;
        endcase
    end


    always_comb begin : next_state_logic
        if (rst) begin
            next_state = idle; 
        end
        else begin
            unique case (state)
                idle: begin
                    if (mem_read || mem_write) begin
                        next_state = check;
                    end
                    else begin
                        next_state = idle;
                    end
                end
                check: begin
                    if (hit) begin
                        next_state = idle;
                    end
                    else if ((lru_in == 1'b0 && way_0_dirty_in == 1'b1) || (lru_in == 1'b1 && way_1_dirty_in == 1'b1)) begin
                        next_state = write_back;
                    end
                    /* miss */
                    else begin
                        next_state = allocate;
                    end
                end
                write_back: begin
                    if (pmem_resp) begin
                        next_state = allocate;
                    end
                    else begin
                        next_state = write_back;
                    end
                end
                allocate: begin
                    if (pmem_resp) begin
                        next_state = idle; /* TODO: go to idle as mentioned in gradescope */
                    end
                    else begin
                        next_state = allocate;
                    end
                end
                default: next_state = idle;
            endcase
        end
    end

    always_ff @(posedge clk) begin: next_state_assignment
        state <= next_state;
    end

endmodule : cache_control