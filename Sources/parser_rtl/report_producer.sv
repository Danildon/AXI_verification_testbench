//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2021 05:16:39 PM
// Design Name: 
// Module Name: report_producer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import tb_pkg::*;
import parser_pkg::ReportFile;

module report_producer
#(
    parameter ReportFile = "Report.txt"         // path of the Report file
) 
();
    
    string module_name = $sformatf("%m");
    string registered_modules[$];
    bit registered_modules_print_en[$];
    bit registered_modules_save_en[$];
    string registered_modules_blacklist[$];
    integer file_wr = NULL;
    integer file_wr_t = NULL;
    int flush_file_cnt;
    int flush_stdout_cnt;
    
    initial begin
        // Open Report file in write only mode
        file_wr = $fopen(ReportFile, "w");
        flush_file_cnt = 0;
        flush_stdout_cnt = 0;
        
        if (file_wr == NULL) begin
            $display("Unable to create Report file %s", ReportFile);
        end
        else begin
            $display("Report file %s succesfully created", ReportFile);
        end
    end

    initial begin
        Top_TB.report_producer_i.module_register(module_name);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.report_producer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.I3C_Slave_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.I3C_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.DCM_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.c2c_generator_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.tb_generator_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.AXI4S_to_DCM_Checker_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.DCM_out_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.DCM_rx_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.ILKN_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.ILKN_out_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.PNL_SYNC_Checker_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.PHY_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.HSM_to_PHY_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.MAC_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.MAC_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.PHY_TX_Scoreboard_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB.PHY_TX_Sniffer_i", 'b0);
        Top_TB.report_producer_i.module_set_blacklist("Top_TB", 'b0);
    end
    
    function void close_report_file();
    begin
        if (file_wr == NULL) begin
            $display ("Report file %s not found!", ReportFile);
        end
        else begin
            $fflush(file_wr);
            $fclose(file_wr);
            flush_file_cnt = 0;
            $display("Report file %s has been closed", ReportFile);
        end
    end
    endfunction : close_report_file
    
    function void print_string(input string module_name, input string str);
    begin
        foreach (registered_modules[i]) begin
            if (registered_modules[i] == module_name) begin
                foreach (registered_modules_blacklist[l]) begin
                    if (registered_modules_blacklist[l] == module_name) begin
                        return ;
                    end
                end
                if (registered_modules_print_en[i] == 'b1) begin
                    $display($sformatf("%s - %s", module_name, str));
                    flush_stdout_cnt = flush_stdout_cnt + 1;
                    if (flush_stdout_cnt > 1000) begin
                        $fflush(1);
                        flush_stdout_cnt = 0;
                    end
                end
                if (registered_modules_save_en[i] == 'b1) begin
                    if (file_wr == NULL) begin
                        // file not available
                    end
                    else begin
                        $fwrite(file_wr, "%s - %s\n", module_name, str);
                        flush_file_cnt = flush_file_cnt + 1;
                        if (flush_file_cnt > 1000) begin
                            $fflush(file_wr);
                            flush_file_cnt = 0;
                        end
                    end
                end
            end
        end
    end
    endfunction : print_string

    function void print_script(input string module_name, input string str);
    begin
        $display($sformatf("%s", str));
        if (file_wr == NULL) begin
            // file not available
        end
        else begin
            $fwrite(file_wr, "%s\n", str);
            flush_file_cnt = flush_file_cnt + 1;
            if (flush_file_cnt > 1000) begin
                $fflush(file_wr);
                flush_file_cnt = 0;
            end
        end
    end
    endfunction : print_script
    
    /********************************************************************************************
    ***************************** EXTERNALLY CALLED FUNCTIONS ***********************************
    ********************************************************************************************/

    function void module_register(input string module_name);
        automatic  bit skip_op = 'h0;
    begin
        foreach (registered_modules[i]) begin
            if (registered_modules[i] == module_name) begin
                skip_op = 'b1;
            end
        end

        if (skip_op == 'b0) begin
            registered_modules.push_back(module_name);
            registered_modules_print_en.push_back('b1);
            registered_modules_save_en.push_back('b1);
            print_string(module_name, "Module registered");
        end 
    end
    endfunction : module_register

    function void module_deregister(input string module_name);
    begin
        foreach (registered_modules[i]) begin
            if (registered_modules[i] == module_name) begin
                foreach (registered_modules_blacklist[l]) begin
                    if (registered_modules_blacklist[l] == module_name) begin
                        registered_modules_blacklist.delete(l);
                        print_string(module_name, "Module removed from blacklist");
                    end
                end
                print_string(module_name, "Module deregistered");
                registered_modules.delete(i);
                registered_modules_print_en.delete(i);
                registered_modules_save_en.delete(i);
                return ;
            end
        end
    end
    endfunction : module_deregister

    function void module_set_print(input string module_name, input bit val);
    begin
        foreach (registered_modules[i]) begin
            if (registered_modules[i] == module_name) begin
                registered_modules_print_en[i] = val;
                return ;
            end
        end
    end
    endfunction : module_set_print

    function void module_set_save(input string module_name, input bit val);
    begin
        foreach (registered_modules[i]) begin
            if (registered_modules[i] == module_name) begin
                registered_modules_save_en[i] = val;
            end
        end
    end
    endfunction : module_set_save

    function void module_set_blacklist(input string module_name, input bit bl_enable);
        automatic bit skip_op = 'h0;
    begin
        foreach (registered_modules_blacklist[i]) begin
            if (registered_modules_blacklist[i] == module_name) begin
                skip_op = 'b1;
                if (bl_enable == 'b0) begin
                    registered_modules_blacklist.delete(i);
                    print_string(module_name, "Module removed from blacklist");
                end
            end
        end
        if (skip_op == 'b0) begin
            if (bl_enable == 'b1) begin
                print_string(module_name, "Module added to blacklist");
                registered_modules_blacklist.push_back(module_name);
            end
        end
    end
    endfunction : module_set_blacklist
    
    function void generic_print(input string module_name, input string my_string);
    begin
        print_string(module_name, my_string);
    end
    endfunction : generic_print
    
    function void print_start_time(input string module_name, input string title);
    begin
        print_string(module_name, $sformatf("----------------------------------------------"));
        print_string(module_name, $sformatf("%s", title));
        print_string(module_name, $sformatf("Start Time      : @ %4d us (@ %4d ns)",$time/1000, $time));
    end
    endfunction : print_start_time
    
    function void print_end_time(input string module_name, input string title);
    begin
        print_string(module_name, $sformatf("%s", title));
        print_string(module_name, $sformatf("END Time        : @ %4d us (@ %4d ns)",$time/1000, $time));
        print_string(module_name, $sformatf("----------------------------------------------"));
    end
    endfunction : print_end_time
`ifdef AXI_VIP
    function void print_axi_wr_op(input string module_name, input longint address,
        input bit [(4096*8)-1:0] data_wr_array,
        input longint len,
        input longint size);
    begin
        // Print the line on transcript & the result/report file
        print_string(module_name, $sformatf("----------------------------------------------"));
        print_string(module_name, $sformatf("AXI4 WRITE:"));
        print_string(module_name, $sformatf("START Time      : %4d us (@ %4d ns)",$time/1000, $time));
        print_string(module_name, $sformatf("Address         : 0x%16h", address));
        print_string(module_name, $sformatf("first data block: 0x%32h", data_wr_array[128-1:0]));
        print_string(module_name, $sformatf("Len             : 0x%3h", len));
        print_string(module_name, $sformatf("Burst_Type      : 0x%3h", XIL_AXI_BURST_TYPE_INCR));
        print_string(module_name, $sformatf("Size (in bytes) : 0x%3h", size));
        print_string(module_name, $sformatf("----------------------------------------------"));
        for (int i = 0 ; i <= len; i++) begin
            if (size == 2) begin
                print_script(module_name, $sformatf("AXI4_WR(0x%016h,0x%08h,0,%01d) # SCRIPT", address + i*4, data_wr_array[(i+1)*8*4-1-:32], size));
            end
            else if (size == 3) begin
                print_script(module_name, $sformatf("AXI4_WR(0x%016h,0x%016h,0,%01d) # SCRIPT", address + i*8, data_wr_array[(i+1)*8*8-1-:64], size));
            end
            else if (size == 4) begin
                print_script(module_name, $sformatf("AXI4_WR(0x%016h,0x%032h,0,%01d) # SCRIPT", address + i*16, data_wr_array[(i+1)*8*16-1-:128], size));
            end
            else if (size == 5) begin
                print_script(module_name, $sformatf("AXI4_WR(0x%016h,0x%064h,0,%01d) # SCRIPT", address + i*32, data_wr_array[(i+1)*8*32-1-:256], size));
            end
            else begin
                print_string(module_name, $sformatf("data block size not supported"));
            end
        end
    end
    endfunction : print_axi_wr_op
    
    function void print_axi_rd_op(input string module_name, input longint address,
        input bit [(4096*8)-1:0] data_rd_array,
        input longint len,
        input longint size);
    begin
        // Print the line on transcript & the result/report file
        print_string(module_name, $sformatf("----------------------------------------------"));
        print_string(module_name, $sformatf("AXI4 READ:"));
        print_string(module_name, $sformatf("START Time      : %4d us (@ %4d ns)",$time/1000, $time));
        print_string(module_name, $sformatf("Address         : 0x%16h", address));
        print_string(module_name, $sformatf("First_data block: 0x%32h", data_rd_array[128-1:0]));
        print_string(module_name, $sformatf("Len             : 0x%3h", len));
        print_string(module_name, $sformatf("Burst_Type      : 0x%3h", XIL_AXI_BURST_TYPE_INCR));
        print_string(module_name, $sformatf("Size (in bytes) : 0x%3h", size));
        print_string(module_name, $sformatf("----------------------------------------------"));
        for (int i = 0 ; i <= len; i++) begin
            if (size == 2) begin
                print_script(module_name, $sformatf("AXI4_RD(0x%016h,0x%08h,0,%01d) # SCRIPT", address + i*4, data_rd_array[(i+1)*8*4-1-:32], size));
            end
            else if (size == 3) begin
                print_script(module_name, $sformatf("AXI4_RD(0x%016h,0x%016h,0,%01d) # SCRIPT", address + i*8, data_rd_array[(i+1)*8*8-1-:64], size));
            end
            else if (size == 4) begin
                print_script(module_name, $sformatf("AXI4_RD(0x%016h,0x%032h,0,%01d) # SCRIPT", address + i*16, data_rd_array[(i+1)*8*16-1-:128], size));
            end
            else if (size == 5) begin
                print_script(module_name, $sformatf("AXI4_RD(0x%016h,0x%064h,0,%01d) # SCRIPT", address + i*32, data_rd_array[(i+1)*8*32-1-:256], size));
            end
            else begin
                print_string(module_name, $sformatf("data block size not supported"));
            end
        end
    end
    endfunction : print_axi_rd_op
`endif
    
    function void print_test_done();
    begin
        print_string(module_name, "\n\nTEST DONE : Completed SUCCESSFUL");
        print_end_time(module_name, "");
        file_wr_t = $fopen(parser_pkg::ReportFile,"a+");
        $fwrite(file_wr_t,"\n\nTEST DONE : Completed SUCCESSFUL\n\n");
        $fclose(file_wr_t);  
    end
    endfunction : print_test_done
    
    function void print_test_failed(input integer error_number);
    begin
        print_string(module_name, "\n\nTEST DONE : Completed UNSUCCESSFUL");
        print_string(module_name, $sformatf("# Errors = %4d", error_number));
        print_end_time(module_name, "");
        file_wr_t = $fopen(parser_pkg::ReportFile,"a+");
        $fwrite(file_wr_t,"\n\nTEST DONE : Completed UNSUCCESSFUL\n\n");
        $fwrite(file_wr_t,"# Errors = %4d\n\n", error_number);
        $fclose(file_wr_t);  
    end
    endfunction : print_test_failed

endmodule
