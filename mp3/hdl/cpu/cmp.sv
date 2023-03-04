module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input rv32i_word rs1_out, cmpmux_out,
    output logic br_en
);

    always_comb begin
        unique case (cmpop)
            beq:     br_en = (rs1_out == cmpmux_out);
            bne:     br_en = (rs1_out != cmpmux_out);
            blt:     br_en = ($signed(rs1_out) < $signed(cmpmux_out));
            bge:     br_en = ($signed(rs1_out) >= $signed(cmpmux_out));
            bltu:    br_en = (rs1_out < cmpmux_out);
            bgeu:    br_en = (rs1_out >= cmpmux_out);
            default: br_en = 1'b0;
        endcase
    end

endmodule : cmp