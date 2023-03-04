
module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE
task write(input key_t key, input val_t val);
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    itf.key <= key;
    itf.val_i <= val;
endtask : write

task read(input key_t key);
    itf.rw_n <= 1'b1;
    itf.valid_i <= 1'b1;
    itf.key <= key;
endtask : read

task reset_cam();
    @(tb_clk);
    itf.reset_n <= 1'b0;
    ##1;
    itf.reset_n <= 1'b1;
endtask : reset_cam

task evict();
    reset_cam();
    for (int i = 0; i < camsize_p*2; ++i) begin
        write(i, 16'hA411);
        ##1;
    end
    itf.valid_i <= 1'b0;
endtask : evict

task read_hit();
    reset_cam();
    @(tb_clk);
    for (int i = 0; i < camsize_p; ++i) begin
        write(i, 16'hA411);
        ##1;
    end

    @(tb_clk);
    for (int i = 0; i < camsize_p; ++i) begin
        read(i);
        ##1;
    end
    itf.valid_i <= 1'b0;
endtask : read_hit

task w_same_key();
    reset_cam();
    @(tb_clk);
    for (int i = 0; i < camsize_p; ++i) begin
        write(i, 16'hA411);
        ##1;
        write(i, 16'h411A);
    end
    itf.val_i <= 1'b0;
endtask : w_same_key

/*
task w_same_key();
    reset_cam();
    @(tb_clk);
    for (int i = 0; i < camsize_p; ++i) begin
        for (int k = 0; k < 2**val_width_p; ++k) begin
            write(i, k);
            ##1;
        end
    end
    itf.val_i <= 1'b0;
endtask : w_same_key
*/

task wr_same_key();
    reset_cam();
    @(tb_clk);
    for (int i = 0; i < camsize_p; ++i) begin
        for (int k = 0; k < 2**val_width_p; ++k) begin
            write(i, k);
            ##1;
            read(i);
            ##1;
            assert (itf.val_o == k) else begin
                itf.tb_report_dut_error(READ_ERROR);
                $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, k);
            end
            ##1;
        end
    end
    itf.val_i <= 1'b0;
endtask : wr_same_key

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    evict();
    read_hit();
    w_same_key();
    wr_same_key();
    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
