module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic br_en,
    input logic mem_resp,
    input logic [1:0] mem_address_ls2,
    output logic load_pc, load_ir, load_mar, load_mdr, load_regfile, load_data_out,
    output alu_ops aluop,
    output branch_funct3_t cmpop,
    output pcmux::pcmux_sel_t pcmux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
    logic trap;
    logic [4:0] rs1_addr, rs2_addr;
    logic [3:0] rmask, wmask;

    branch_funct3_t branch_funct3;
    store_funct3_t store_funct3;
    load_funct3_t load_funct3;
    arith_funct3_t arith_funct3;

    assign arith_funct3 = arith_funct3_t'(funct3);
    assign branch_funct3 = branch_funct3_t'(funct3);
    assign load_funct3 = load_funct3_t'(funct3);
    assign store_funct3 = store_funct3_t'(funct3);
    assign rs1_addr = rs1;
    assign rs2_addr = rs2;

    always_comb begin : trap_check
        trap = '0;
        rmask = '0;
        wmask = '0;

        case (opcode)
            op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

            op_br: begin
                case (branch_funct3)
                    beq, bne, blt, bge, bltu, bgeu:;
                    default: trap = '1;
                endcase
            end

            op_load: begin
                case (load_funct3)
                    lw: rmask = 4'b1111;
                    lh, lhu: rmask = 4'b0011 << mem_address_ls2; /* Modify for MP1 Final */
                    lb, lbu: rmask = 4'b0001 << mem_address_ls2; /* Modify for MP1 Final */
                    default: trap = '1;
                endcase
            end

            op_store: begin
                case (store_funct3)
                    sw: wmask = 4'b1111;
                    sh: wmask = 4'b0011 << mem_address_ls2; /* Modify for MP1 Final */
                    sb: wmask = 4'b0001 << mem_address_ls2; /* Modify for MP1 Final */
                    default: trap = '1;
                endcase
            end

            default: trap = '1;
        endcase
    end
/*****************************************************************************/

    typedef enum logic [3:0] {
        /* List of states */
        fetch1,
        fetch2,
        fetch3,
        decode,
        lui,
        auipc,
        jal,
        jalr,
        br,
        calc_addr,
        ld1,
        ld2,
        st1,
        st2,
        imm,
        reg_reg
    } rv32i_state;
    rv32i_state state, next_state;

/************************* Function Definitions *******************************/
/**
 * You do not need to use these functions, but it can be nice to encapsulate
 * behavior in such a way.  For example, if you use the `loadRegfile`
 * function, then you only need to ensure that you set the load_regfile bit
 * to 1'b1 in one place, rather than in many.
 *
 * SystemVerilog functions must take zero "simulation time" (as opposed to 
 * tasks).  Thus, they are generally synthesizable, and appropraite
 * for design code.  Arguments to functions are, by default, input.  But
 * may be passed as outputs, inouts, or by reference using the `ref` keyword.
 */

/**
 * Rather than filling up an always_block with a whole bunch of default values,
 * set the default values for controller output signals in this function,
 * and then call it at the beginning of your always_comb block.
 */
    function void set_defaults();
        load_pc = 1'b0;
        load_ir = 1'b0;
        load_mar = 1'b0;
        load_mdr = 1'b0;
        load_regfile = 1'b0;
        load_data_out = 1'b0;
        aluop = alu_add;
        cmpop = beq;
        pcmux_sel = pcmux::pc_plus4;
        marmux_sel = marmux::pc_out;
        alumux1_sel = alumux::rs1_out;
        alumux2_sel = alumux::i_imm;
        regfilemux_sel = regfilemux::alu_out;
        cmpmux_sel = cmpmux::rs2_out;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_byte_enable = 4'b0000;
    endfunction

    /**
     * Use the next several functions to set the signals needed to
     * load various registers
     */
    function void loadPC(pcmux::pcmux_sel_t sel);
        pcmux_sel = sel;
        load_pc = 1'b1;
    endfunction

    function void loadMAR(marmux::marmux_sel_t sel);
        marmux_sel = sel;
        load_mar = 1'b1;
    endfunction

    function void loadMDR();
        mem_read = 1'b1;
        load_mdr = 1'b1;
    endfunction

    function void loadIR();
        load_ir = 1'b1;
    endfunction

    function void loadRegfile(regfilemux::regfilemux_sel_t sel);
        regfilemux_sel = sel;
        load_regfile = 1'b1;
    endfunction

    function void loadDataOut();
        load_data_out = 1'b1;
    endfunction

    function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
        /* Student code here */
        if (setop) begin
            alumux1_sel = sel1;
            alumux2_sel = sel2;
            aluop = op; // else default value
        end
    endfunction

    function automatic void setCMP(cmpmux::cmpmux_sel_t sel, logic setop, branch_funct3_t op);
        if (setop) begin
            cmpmux_sel = sel;
            cmpop = op;
        end
    endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

    always_comb begin : state_actions
        /* Default output assignments */
        set_defaults();
        /* Actions for each state */
        unique case (state)
            fetch1: loadMAR(marmux::pc_out);
            fetch2: loadMDR();
            fetch3: loadIR();
            decode: ;
            lui: begin
                loadRegfile(regfilemux::u_imm);
                loadPC(pcmux::pc_plus4);
            end
            auipc: begin
                setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
                loadRegfile(regfilemux::alu_out);
                loadPC(pcmux::pc_plus4);
            end
            jal: begin
                loadRegfile(regfilemux::pc_plus4);
                setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
                loadPC(pcmux::alu_mod2);
            end
            jalr: begin
                loadRegfile(regfilemux::pc_plus4);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                loadPC(pcmux::alu_mod2);
            end
            br: begin
                setCMP(cmpmux::rs2_out, 1'b1, branch_funct3);
                setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
                loadPC(pcmux::pcmux_sel_t'({1'b0, br_en}));
            end
            calc_addr: begin
                unique case (opcode)
                    op_load: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                        loadMAR(marmux::alu_out);
                    end
                    op_store: begin
                        setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
                        loadMAR(marmux::alu_out);
                        loadDataOut();
                    end
                    default: ;
                endcase
            end
            ld1: loadMDR();
            ld2: begin
                unique case (load_funct3)
                    lb: loadRegfile(regfilemux::lb);
                    lh: loadRegfile(regfilemux::lh);
                    lw: loadRegfile(regfilemux::lw);
                    lbu: loadRegfile(regfilemux::lbu);
                    lhu: loadRegfile(regfilemux::lhu);
                    default: ;
                endcase
                loadPC(pcmux::pc_plus4);
            end
            st1: begin
                mem_write = 1'b1;
                mem_byte_enable = wmask;
            end
            st2: begin
                loadPC(pcmux::pc_plus4);
            end
            imm: begin
                unique case (arith_funct3)
                    add: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                        loadRegfile(regfilemux::alu_out);
                    end
                    slt: begin
                        setCMP(cmpmux::i_imm, 1'b1, blt);
                        loadRegfile(regfilemux::br_en);
                    end
                    sltu: begin
                        setCMP(cmpmux::i_imm, 1'b1, bltu);
                        loadRegfile(regfilemux::br_en);
                    end
                    axor: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor);
                        loadRegfile(regfilemux::alu_out);
                    end
                    aor: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);
                        loadRegfile(regfilemux::alu_out);
                    end
                    aand: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sll: begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sr: begin
                        /* check IR[30] -> funct7[5] (SR Arithmetic or Logic) */
                        if (~funct7[5]) begin
                            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                        end
                        else begin
                            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                        end
                        loadRegfile(regfilemux::alu_out);
                    end
                    default: ;
                endcase
                loadPC(pcmux::pc_plus4);
            end
            reg_reg: begin
                unique case (arith_funct3)
                    add: begin
                        /* check IR[30] -> funct7[5] (Add or Sub) */
                        if (~funct7[5]) begin
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
                        end else begin
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                        end
                        loadRegfile(regfilemux::alu_out);
                    end
                    sll: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll);
                        loadRegfile(regfilemux::alu_out);
                    end
                    slt: begin
                        setCMP(cmpmux::rs2_out, 1'b1, blt);
                        loadRegfile(regfilemux::br_en);
                    end
                    sltu: begin
                        setCMP(cmpmux::rs2_out, 1'b1, bltu);
                        loadRegfile(regfilemux::br_en);
                    end
                    axor: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor);
                        loadRegfile(regfilemux::alu_out);
                    end
                    sr: begin
                        /* check IR[30] -> funct7[5] (SR Logic or Arithmetic) */
                        if (~funct7[5]) begin
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                        end
                        else begin
                            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                        end
                        loadRegfile(regfilemux::alu_out);
                    end
                    aor: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or);
                        loadRegfile(regfilemux::alu_out);
                    end
                    aand: begin
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and);
                        loadRegfile(regfilemux::alu_out);
                    end
                    default: ;
                endcase
                loadPC(pcmux::pc_plus4);
            end
            default: ;
        endcase
    end

    always_comb begin : next_state_logic
        /**
         * Next state information and conditions (if any)
         * for transitioning between states
         */
        if (rst) begin
            next_state = fetch1; 
        end
        else begin
            unique case (state)
                fetch1: next_state = fetch2;
                fetch2: next_state = mem_resp ? fetch3 : fetch2;
                fetch3: next_state = decode;
                decode: begin
                    unique case (opcode)
                        /* load upper immediate (U type) */
                        op_lui: next_state = lui;
                        /* add upper immediate PC (U type) */
                        op_auipc: next_state = auipc;
                        /* jump and link  */
                        op_jal: next_state = jal;
                        /* jump and link register */
                        op_jalr: next_state = jalr;
                        /* branch (B type) */
                        op_br: next_state = br;
                        /* load (I type) */
                        op_load: next_state = calc_addr;
                        /* store (S type) */
                        op_store: next_state = calc_addr;
                        /* arithmetic ops register & immediate (I type) */
                        op_imm: next_state = imm;
                        /* arithmetic ops register & register (R type) */
                        op_reg: next_state = reg_reg;
                        /* atomic r/w CSR control & status register (I type) */
                        op_csr: next_state = fetch1;
                        default: next_state = fetch1;
                    endcase
                end
                lui: next_state = fetch1;
                auipc: next_state = fetch1;
                jal: next_state = fetch1;
                jalr: next_state = fetch1;
                br: next_state = fetch1;
                calc_addr: begin
                    if (opcode == op_load) begin
                        next_state = ld1;
                    end
                    else begin
                        next_state = st1;
                    end
                end
                ld1: next_state = mem_resp ? ld2 : ld1;
                ld2: next_state = fetch1;
                st1: next_state = mem_resp ? st2 : st1;
                st2: next_state = fetch1;
                imm: next_state = fetch1;
                reg_reg: next_state = fetch1;
                default: next_state = fetch1;
            endcase
        end
    end

    always_ff @(posedge clk)
    begin: next_state_assignment
        /* Assignment of next state on clock edge */
        state <= next_state;
    end

endmodule : control