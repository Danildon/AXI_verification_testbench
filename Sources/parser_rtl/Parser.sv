//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2021 05:16:39 PM
// Design Name: 
// Module Name: Parser
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
`timescale 1ns / 1ps

`define AXI_VIP
`ifdef AXI_VIP
// Import package AXI VIP


import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;



`endif

import parser_pkg::*;
import tb_pkg::*;

module Parser
#( 
    parameter StimuliFile = "Stimuli.txt"  // Path of the stimuli file
) ();

    string module_name = $sformatf("%m");
//`ifdef AXI_VIP
    // AXI4
    parameter axi_data_width           = 128;
    parameter axi_address_width        = 64;
    parameter axi_burst_max_data_width = 4096*8;
    parameter axi_burst_data_beat      = axi_burst_max_data_width/axi_data_width; // obviously... the remainder == 0
//`endif
    int cmd;
    bit[127:0] params[$];
    string str_params[$];
    string title_string = "";
    stimuli_parser stp;         // stimuli parser
    int rv;
    integer fw;
    int sel_idx;
    int rp_p;

    initial begin
        Top_TB.report_producer_i.module_register(module_name);
        
    end

    // Start Parser execution
    initial begin
        // Catch Data from Stimuli File
        Stimuli_parser();
        
        #10us
        $finish;  // Stop simulation...
    end

    /*************************************************************************************************
    * Parser commands from Stimuli file
    *************************************************************************************************/
    task Stimuli_parser();

        // File
        parameter MAX_CHARACTERS_PER_LINE = 1024;                                  // Max size of one stimuli file line
        parameter MAX_CHARACTERS_PER_COMMAND = 13;                                 // Max size of one stimuli file's command
        parameter NULL = 0;                                                        // useful for comparison
        reg[8*MAX_CHARACTERS_PER_COMMAND-1:0] command;                             // Command (a string is represented as a sequence of 8-bit characters)
        reg[8*MAX_CHARACTERS_PER_LINE-1-8:0]  directory_inc;
        string tmp;
        reg[7:0] char, r;
        bit rand_flag;
        
        int rd_index ;//index to read from the scoreboard
        int sel; //variabel to select the VIP
        // Miscellaneous
        longint wait_time;                                                         // Time in Wait command
        integer dummy;
        //
        int error_number;
`ifdef AXI_VIP
        //
        static bit [axi_data_width-1:0]           zeros         = 'h0;
        //
        static xil_axi_uint                       id            = 'h0;
        static bit [axi_address_width-1:0]        address       = 'h0;
        static bit [axi_data_width-1:0]           data_rd       = 'h0;
        static bit [axi_burst_max_data_width-1:0] data_rd_array = 'h0;
        static bit [axi_data_width-1:0]           data_wr       = 'h0;
        static bit [axi_burst_max_data_width-1:0] data_wr_array = 'h0;
        static xil_axi_len_t                      len           = 'h0;
        static xil_axi_len_t                      blen           = 'h0;
        static xil_axi_size_t                     size          = XIL_AXI_SIZE_16BYTE;
        static xil_axi_burst_t                    burst         = XIL_AXI_BURST_TYPE_INCR;
        static xil_axi_lock_t                     lock          = XIL_AXI_ALOCK_NOLOCK;
        static xil_axi_cache_t                    cache         = 'h0;
        static xil_axi_prot_t                     prot          = 'h0;
        static xil_axi_region_t                   region        = 'h0;
        static xil_axi_qos_t                      qos           = 'h0;
        static xil_axi_user_beat                  auser         = 'h0;
        static xil_axi_data_beat [255:0]          duser         = 'h0;
        static xil_axi_resp_t                     bresp         = XIL_AXI_RESP_OKAY;
        static xil_axi_resp_t [255:0]             rresp         = XIL_AXI_RESP_OKAY;

        static string                             frame_rd_path;
        static string                             frame_dump_path;      
        
`endif
        // I3C
        static bit [7:0]                          data_scb      = 'h0;
        static bit                                rw_slv        = 'h0;
        static bit [6:0]                          addr_slv      = 'h0;
        static bit                                i3c_cfg       = 'h0;

        // C2C packet
        static int                                num_of_packets= 0;
        static int        			              num_of_words  = 0;
        static int                                pkt_type      = 0;

        // Panel Sync
        static int                                pls_width     = 0;
        static int                                pls_time      = 0;
        static bit                                pnl_sync_ctrl_en;
        static bit                                pnl_sync_ctrl_cfg_en;

    begin

        rp_p= $fopen(ReportFile,"w");
        $fclose(rp_p);

        stimuli_file_merger(StimuliFile, "Stimuli_Extended.txt");

        stp = new("Stimuli_Extended.txt");

        if (stp.isFileOpen() == 1'b0) begin
            $display("Stimuli Extended File not found!");
            return;
        end
        $display("generated Stimuli filename: %s", "Stimuli_Extended.txt");

        // Initialize to 0 the number of errors
        error_number = 0;

        rv = 0;
        while (rv == 0) begin
            rv = stp.getNextCommand(cmd, params, str_params);
            if (rv == 0) begin
                // Top_TB.report_producer_i.generic_print(module_name, $sformatf("%s", stp.getLastLine()));
            end
            else begin
                break; // while
            end

            case(cmd)
                stimuli_parser::E_CMD_WAIT_NS: // wait_ns(value) // --> Waiting for # nano seconds command
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "WAIT_NS");

                    wait_time = params[0]; // timescale: 1ns
                    Top_TB.report_producer_i.generic_print(module_name, $sformatf("wait_time=%4d ns", wait_time));
                    #wait_time; // delay the parser execution

                    Top_TB.report_producer_i.print_end_time(module_name, "WAIT_NS");
                end

                stimuli_parser::E_CMD_WAIT_US: // wait_us(value) // --> Waiting for # micro seconds command
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "WAIT_US");

                    wait_time = params[0] * 1000; // timescale: 1ns
                    Top_TB.report_producer_i.generic_print(module_name, $sformatf("wait_time=%4d ns", wait_time));
                    #wait_time; // delay the parser execution

                    Top_TB.report_producer_i.print_end_time(module_name, "WAIT_US");
                end

                stimuli_parser::E_CMD_WAIT_MS: // wait_ms(value) // --> Waiting for # milli seconds command
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "WAIT_MS");

                    wait_time = params[0] * 1000 * 1000; // timescale: 1ns
                    Top_TB.report_producer_i.generic_print(module_name, $sformatf("wait_time=%4d ns", wait_time));
                    #wait_time; // delay the parser execution

                    Top_TB.report_producer_i.print_end_time(module_name, "WAIT_MS");
                end
`ifdef AXI_VIP

                stimuli_parser::E_CMD_AXI4FULL_RD:
                begin
                address = params[0];
                len     = params[2];
                data_rd = params[1];
                sel_idx = params[3];
                
                Top_TB.axi4full_handler.AXI4FULL_READ( address, len , data_rd , sel_idx);
                Top_TB.report_producer_i.print_end_time( module_name, "AXI4FULL_RD");
                end

                stimuli_parser::E_CMD_AXI4STREAM_WR: // 
                begin
              
                Top_TB.report_producer_i.print_start_time(module_name, "AXISTREAM_WR");    
                   
                Top_TB.axi4stream_handler.blen[params[2]].push_back(params[0]);
                Top_TB.axi4stream_handler.data_wr[params[2]].push_back(params[1]);
                Top_TB.axi4stream_handler.vip_sel = params[2];

                sel = params[2];
                    
                    Top_TB.axi4stream_handler.sem[sel].put(1);
                    //Top_TB.axi4stream_handler.axi4stream_wr_rand(len,data_wr,sel,0);
                
                end
                stimuli_parser::E_CMD_AXI4STREAM_WR_FRAME: 
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "AXISTREAM_WR_FRAME"); 
                   
                  
                    
                    Top_TB.axi4stream_handler.file_rd_path[params[0]].push_back(str_params[0]);

                    Top_TB.axi4stream_handler.sem_frame[params[0]].put(1);
                   
                end

                stimuli_parser::E_CMD_AXI4LITE_WR: // AXI4_WR(ADDR,DATA,LEN,SIZE)
                begin
                    address = params[0];
                    data_wr = params[1];
                    len     = params[2];
                    size = xil_axi_size_t'(params[3]);
                    sel_idx = params[4];


                    

                    Top_TB.report_producer_i.print_start_time(module_name, "AXI4LITE_WR");

                    // Fill write data array with inc data
                    for(int beat = 0; beat < len + 1; beat++)
                    begin
                        data_wr_array = {data_wr_array[axi_burst_max_data_width-axi_data_width-1:0],data_wr+beat};
                    end

                   // Top_TB.report_producer_i.print_axi_wr_op(module_name, address, data_wr_array, longint'(len), longint'(size));
                    // Execute AXI4 Write transaction
                    Top_TB.axi4lite_handler.AXI4LITE_WRITE(id,address,len,size,burst,lock,cache,prot,region,qos,auser,data_wr,duser,bresp,sel_idx);
                    Top_TB.report_producer_i.print_end_time(module_name, "AXI4LITE_WR");
                end

                stimuli_parser::E_CMD_AXI4FULL_WR: // AXI4FULL_WR(ADDR,DATA,LEN,SIZE)
                begin
                    address   = params[0];
                    data_wr   = params[1];
                    len       = params[2];
                    sel_idx  =  params[3];


                    Top_TB.report_producer_i.print_start_time(module_name, "AXI4FULL_WR");

                    // Fill write data array with inc data
                    for(int beat = 0; beat < len + 1; beat++)
                    begin
                        data_wr_array = {data_wr_array[axi_burst_max_data_width-axi_data_width-1:0],data_wr+beat};
                    end


                    
                    Top_TB.axi4full_handler.AXI4FULL_WRITE(address,data_wr,len,sel_idx);
                    
                    Top_TB.report_producer_i.print_end_time(module_name, "AXI4FULL_WR");
                end


                stimuli_parser::E_CMD_AXI4LITE_RD: // AXI4_RD(ADDR,DATA,LEN,SIZE)
                begin
                    address = params[0];
                    data_wr_array = params[1];
                    len = params[2];
                    size = xil_axi_size_t'(params[3]);
                    sel_idx = params[4];

                    Top_TB.report_producer_i.print_start_time(module_name, "AXI4LITE_RD");
 
                   // Top_TB.report_producer_i.print_axi_rd_op(module_name, address, data_wr_array, longint'(len), longint'(size));
                    
                    Top_TB.axi4lite_handler.AXI4LITE_READ(id,address,len,size,burst,lock,cache,prot,region,qos,auser,data_wr_array,duser,bresp,sel_idx);

                    Top_TB.report_producer_i.print_end_time(module_name, "AXI4LITE_RD");
                end
`endif

                stimuli_parser::E_CMD_SET_TITLE: // SET_TITLE(title_string)
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "SET_TITLE");

                    if (str_params.size() > 'h0) begin
                        title_string=str_params[0];
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("title_string=%0s", title_string));
                    end
                    else begin
                        title_string="";
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", "Title string not set"));
                    end

                    Top_TB.report_producer_i.print_end_time(module_name, "SET_TITLE");
                end

                stimuli_parser::E_CMD_PRINT_TITLE: // PRINT_TITLE()
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "PRINT_TITLE");

                    if (title_string.compare("") != 0) begin
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", title_string));
                    end
                    else begin
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", "Title string not set"));
                    end

                    Top_TB.report_producer_i.print_end_time(module_name, "PRINT_TITLE");
                end

                stimuli_parser::E_CMD_PRINT_LINE: // PRINT_LINE(string)
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "PRINT_LINE");

                    if (str_params.size() > 'h0) begin
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", str_params[0]));
                    end
                    else begin
                        Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", "String not supported"));
                    end

                    Top_TB.report_producer_i.print_end_time(module_name, "PRINT_LINE");
                end

                stimuli_parser::E_CMD_DEBUG_STOP: // DEBUG_STOP()
                begin
                    Top_TB.report_producer_i.print_start_time(module_name, "DEBUG_STOP");
                    $stop;
                    Top_TB.report_producer_i.print_end_time(module_name, "DEBUG_STOP");
                end

                default: // --> Invalid Command
                begin
                    //Top_TB.report_producer_i.generic_print(module_name, $sformatf("%s", stp.getLastLine()));
                end
            endcase
        end // while not EOF
        

        if (title_string.compare("") != 0) begin
            Top_TB.report_producer_i.generic_print(module_name, $sformatf("%0s", title_string));
        end
        Top_TB.report_producer_i.generic_print(module_name, $sformatf("command_file closing @ Time=%4d ns (@ %4d us)", $time, $time/1000));
        stp.close();
        Top_TB.report_producer_i.generic_print(module_name, $sformatf("command_file closed @ Time=%04d ns (@ %4d us)", $time, $time/1000));

        // Check error at the end of the Stimuli parsing
        if(error_number == 0)
        begin
            Top_TB.report_producer_i.print_test_done();
        end
        else begin
            Top_TB.report_producer_i.print_test_failed(error_number);
        end

        // Close Report file
        Top_TB.report_producer_i.close_report_file();

    end
    endtask : Stimuli_parser

    function automatic void stimuli_file_append (input int output_fd, input string input_filepath);
        string line;
        string line_tolower;
        string inner_filepath;
        int file_rd;
        int rv;
    begin
        file_rd = $fopen(input_filepath, "r");
        if (file_rd == NULL) begin
            $display ("Include File %s not found!", input_filepath);
            return;
        end
        else if ($feof(file_rd)) begin
            $display("Stimuli File %s empty!", input_filepath);
            return;
        end

        while (!$feof(file_rd)) begin // Read Stimuli file until the End of File is reached
            if ($fgets(line, file_rd) != NULL) begin
                line_tolower=line.tolower();
                if(line_tolower.substr(0,9-1) == "#include ") begin
                    rv = $sscanf(line, "#include %s", inner_filepath); // read the Included Stimuli-file pathname (directory/name)
                    if (rv == 0) begin
                        rv = $sscanf(line, "#INCLUDE %s", inner_filepath); // read the Included Stimuli-file pathname (directory/name)
                    end
                    if (rv != 0) begin
                        $fwrite(output_fd, "// #include %s // <-\n", inner_filepath);
                        stimuli_file_append(output_fd, inner_filepath);
                    end
                    else begin
                        $display($sformatf("Error when parsin line='%s'", line));
                    end
                end
                else begin
                    $fwrite(output_fd, "%s", line);
                    if (line.substr(line.len()-1,line.len()-1) != "\n") begin
                        $fwrite(output_fd, "\n");
                    end
                end
            end
            else begin
                $display("EOF");
                break; // eof
            end
        end

        $fclose(file_rd);
        return ;
    end
    endfunction : stimuli_file_append

    function void stimuli_file_merger (input string input_filepath, input string output_filepath);
        int output_fd;
    begin
        // Generate an extended Stimuli file adding #include file commands
        output_fd= $fopen(output_filepath, "w");
        if (output_fd == NULL) begin
            $display("Unable to create Stimuli Extended file!");
            return;
        end
        $fwrite(output_fd, "// Stimuli file: %s // <-\n", input_filepath);
        stimuli_file_append(output_fd, input_filepath);
        $fwrite(output_fd, "\n"); // adding return character at EOF
        $fclose(output_fd); // Close Stimuli Extended file
        return ;
    end
    endfunction : stimuli_file_merger

endmodule
