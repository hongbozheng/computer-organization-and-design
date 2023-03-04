// `define ILLEGAL_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    input logic load_pc, load_ir, load_mar, load_mdr, load_regfile, load_data_out,
    input alu_ops aluop,
    input branch_funct3_t cmpop,
    input pcmux::pcmux_sel_t pcmux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input rv32i_word mem_rdata,
    output rv32i_opcode opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [4:0] rs1, rs2,
    output logic br_en,
    output rv32i_word mem_address,
    output logic [1:0] mem_address_ls2,
    output rv32i_word mem_wdata // signal used by RVFI Monitor
    /* You will need to connect more signals to your datapath module*/
);

/******************* Signals Needed for RVFI Monitor *************************/
    rv32i_word pcmux_out;
    rv32i_word mdrreg_out;
/*****************************************************************************/

/*************************** Intermediate Signals ****************************/
    /* PC register output logic */
    rv32i_word pc_out;

    /* MAR output logic */
    rv32i_word mar_out;

    /* IR ouput logic */
    rv32i_reg rd;
    rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm;

    /* REGFILE output logic */
    rv32i_word rs1_out, rs2_out;

    /* MUX output logic */
    rv32i_word marmux_out;
    rv32i_word alumux1_out, alumux2_out;
    rv32i_word regfilemux_out;
    rv32i_word cmpmux_out;

    /* ALU output logic */
    rv32i_word alu_out;

    /* MEM_DATA_OUT register input logic */
    logic [31:0] mem_data;
/*****************************************************************************/

    assign mem_address = {mar_out[31:2], 2'b0};
    assign mem_address_ls2 = mar_out[1:0];

/***************************** Registers *************************************/
    pc_register PC(
        .clk(clk),
        .rst(rst),
        .load(load_pc),
        .in(pcmux_out),
        .out(pc_out)
    );

    register MAR(
        .clk(clk),
        .rst(rst),
        .load(load_mar),
        .in(marmux_out),
        .out(mar_out)
    );

    register MDR(
        .clk(clk),
        .rst(rst),
        .load(load_mdr),
        .in(mem_rdata),
        .out(mdrreg_out)
    );

    // Keep Instruction register named `IR` for RVFI Monitor
    ir IR(
        .clk(clk),
        .rst(rst),
        .load(load_ir),
        .in(mdrreg_out),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .i_imm(i_imm),
        .s_imm(s_imm),
        .b_imm(b_imm),
        .u_imm(u_imm),
        .j_imm(j_imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd)
    );

    regfile regfile(
        .clk(clk),
        .rst(rst),
        .load(load_regfile),
        .in(regfilemux_out),
        .src_a(rs1),
        .src_b(rs2),
        .dest(rd),
        .reg_a(rs1_out),
        .reg_b(rs2_out)
    );

    register mem_data_out(
        .clk(clk),
        .rst(rst),
        .load(load_data_out),
        .in(mem_data),
        .out(mem_wdata)
    );
/*****************************************************************************/

/******************************* ALU and CMP *********************************/
    alu ALU(
        .aluop(aluop),
        .a(alumux1_out),
        .b(alumux2_out),
        .f(alu_out)
    );

    cmp CMP(
        .cmpop(cmpop),
        .rs1_out(rs1_out),
        .cmpmux_out(cmpmux_out),
        .br_en(br_en)
    );
/*****************************************************************************/

/******************************** Muxes **************************************/
    always_comb begin : MUXES
        // We provide one (incomplete) example of a mux instantiated using
        // a case statement.  Using enumerated types rather than bit vectors
        // provides compile time type safety.  Defensive programming is extremely
        // useful in SystemVerilog. 

        /* PC MUX */
        unique case (pcmux_sel)
            pcmux::pc_plus4: pcmux_out = pc_out + 4;
            pcmux::alu_out: pcmux_out = alu_out;
            /* mask 1-bit from manual or mask 2-bit from campuswire ??? */
		    pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
            // default: `ILLEGAL_MUX_SEL;
            // etc.
        endcase

        /* MAR MUX */
        unique case (marmux_sel)
            marmux::pc_out: marmux_out = pc_out;
            marmux::alu_out: marmux_out = alu_out;
            // default: `ILLEGAL_MUX_SEL;
        endcase

        /* ALU MUX 1 */
        unique case (alumux1_sel)
            alumux::rs1_out: alumux1_out = rs1_out;
            alumux::pc_out: alumux1_out = pc_out;
            // default: `ILLEGAL_MUX_SEL;
        endcase

        /* ALU MUX 2 */
        unique case (alumux2_sel)
            alumux::i_imm: alumux2_out = i_imm;
            alumux::s_imm: alumux2_out = s_imm;
            alumux::b_imm: alumux2_out = b_imm;
            alumux::u_imm: alumux2_out = u_imm;
            alumux::j_imm: alumux2_out = j_imm;
		    alumux::rs2_out: alumux2_out = rs2_out;
            // default: `ILLEGAL_MUX_SEL;
        endcase

        /* REGFILE MUX */
        unique case (regfilemux_sel)
            regfilemux::alu_out: regfilemux_out = alu_out;
		    regfilemux::br_en: regfilemux_out = {31'h0, br_en};
		    regfilemux::u_imm: regfilemux_out = u_imm;
		    regfilemux::lw: regfilemux_out = mdrreg_out;
            regfilemux::pc_plus4: regfilemux_out = pc_out + 32'h4;
            /* load 8-bit (byte) sign-extend */
            regfilemux::lb: begin
                unique case (alu_out[1:0])
                    2'b00: regfilemux_out = {{24{mdrreg_out[7]}}, mdrreg_out[7:0]};
                    2'b01: regfilemux_out = {{24{mdrreg_out[15]}}, mdrreg_out[15:8]};
                    2'b10: regfilemux_out = {{24{mdrreg_out[23]}}, mdrreg_out[23:16]};
                    2'b11: regfilemux_out = {{24{mdrreg_out[31]}}, mdrreg_out[31:24]};
                    // default: `ILLEGAL_MUX_SEL;
                endcase
            end
            /* load 8-bit (byte) zero-extend */
            regfilemux::lbu: begin
                unique case (alu_out[1:0])
                    2'b00: regfilemux_out = {{24'h0}, mdrreg_out[7:0]};
                    2'b01: regfilemux_out = {{24'h0}, mdrreg_out[15:8]};
                    2'b10: regfilemux_out = {{24'h0}, mdrreg_out[23:16]};
                    2'b11: regfilemux_out = {{24'h0}, mdrreg_out[31:24]};
                    // default: `ILLEGAL_MUX_SEL;
                endcase
            end
            /* load 16-bit (byte) sign-extend */
            regfilemux::lh: begin
                unique case (alu_out[1:0])
                    2'b00: regfilemux_out = {{16{mdrreg_out[15]}}, mdrreg_out[15:0]};
                    2'b01: regfilemux_out = {{16{mdrreg_out[23]}}, mdrreg_out[23:8]};
                    2'b10: regfilemux_out = {{16{mdrreg_out[31]}}, mdrreg_out[31:16]};
                    2'b11: regfilemux_out = 32'b0;
                    // default: `ILLEGAL_MUX_SEL;
                endcase
            end
            /* load 16-bit (byte) zero-extend */
            regfilemux::lhu: begin
                unique case (alu_out[1:0])
                    2'b00: regfilemux_out = {{16'h0}, mdrreg_out[15:0]};
                    2'b01: regfilemux_out = {{16'h0}, mdrreg_out[23:8]};
                    2'b10: regfilemux_out = {{16'h0}, mdrreg_out[31:16]};
                    2'b11: regfilemux_out = 32'h0;
                    // default: `ILLEGAL_MUX_SEL;
                endcase
            end
            // default: `ILLEGAL_MUX_SEL;
        endcase

        /* CMP MUX */
        unique case (cmpmux_sel)
            cmpmux::rs2_out: cmpmux_out = rs2_out;
		    cmpmux::i_imm: cmpmux_out = i_imm;
            // default: `ILLEGAL_MUX_SEL;
        endcase
    end
/*****************************************************************************/

/*************************** mem_data_out register ***************************/
    always_comb begin
        unique case (funct3)
            /**
             * alu_out[1:0]
             * 2'b00 => no left shift
             * 2'b01 => left shift 8-bit
             * 2'b10 => left shift 16-bit
             * 2'b11 => left shift 24-bit
             */
            sb: mem_data = (rs2_out << {alu_out[1:0], 3'b0});
            sh: mem_data = (rs2_out << {alu_out[1:0], 3'b0});
            sw: mem_data = rs2_out;
            default: mem_data = rs2_out;
        endcase
    end
/*****************************************************************************/
endmodule : datapath