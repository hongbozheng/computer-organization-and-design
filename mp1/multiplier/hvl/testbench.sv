`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error

task check_ready();
    assert (itf.rdy == 1'b1) else begin
        $error("%0d: %0t: %s error detected", `__LINE__, $time, NOT_READY);
        report_error(NOT_READY);
    end
endtask : check_ready

task multiplier_8_bit_test();
    for (int i = 0; i < 9'd256; ++i) begin
        for (int k = 0; k < 9'd256; ++k) begin
            itf.multiplicand <= i;
            itf.multiplier <= k;
            itf.start <= 1;
            ##1;    // wait 1 clk cycle
            itf.start <= 0;

            @(tb_clk iff itf.mult_op == DONE);

            assert (i*k == itf.product) else begin
                $error("%0d: %0t: %s error detected", `__LINE__, $time, BAD_PRODUCT);
                report_error(BAD_PRODUCT);
            end
        end
    end
endtask : multiplier_8_bit_test

task check_start_resetn_ADD();
    itf.multiplicand <= 8'd35;
    itf.multiplier <= 8'd35;
    itf.start <= 1;
    ##1;
    itf.start <= 0;

    @(tb_clk iff itf.mult_op == ADD);
    itf.start <= 1;
    ##1;
    itf.reset_n <= 0;
    ##1;
    itf.reset_n <= 1;
    check_ready();
endtask : check_start_resetn_ADD

task check_start_resetn_SHIFT();
    itf.multiplicand <= 8'd35;
    itf.multiplier <= 8'd35;
    itf.start <= 1;
    ##1;
    itf.start <= 0;

    @(tb_clk iff itf.mult_op == SHIFT);
    itf.start <= 1;
    ##1;
    itf.reset_n <= 0;
    ##1;
    itf.reset_n <= 1;
    check_ready();
endtask : check_start_resetn_SHIFT

initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    check_ready();
    multiplier_8_bit_test();
    check_ready();
    check_start_resetn_ADD();
    check_start_resetn_SHIFT();
    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end

endmodule : testbench
`endif
