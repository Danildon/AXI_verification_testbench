//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2021 05:16:39 PM
// Design Name: 
// Module Name parser_pkg:
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


package parser_pkg;
    
    parameter ReportFile = "../../../../../TESTBENCH/Current_Report.txt";
    parameter axi4stream_data_size    = 32;
    parameter axi4full_data_size      = 32;
    parameter axi4full_address_size   = 32;
    parameter axi4_lite_data_size     = 32;
    parameter N_AXI4STREAM_MASTER_VIP  = 2; 
    parameter N_AXI4STREAM_SLAVE_VIP  = 2;
    parameter base_frame_dir  = "../../../../../TESTBENCH/Stimuli/"; 
    parameter base_dir = "../../../../../TESTBENCH/";

    class stimuli_parser;
        
        enum {
            E_CMD_UNKNOWN = 0,

            //WAIT COMMANS
            E_CMD_WAIT_NS,
            E_CMD_WAIT_US,
            E_CMD_WAIT_MS,

            //AXI COMMANDS
            E_CMD_AXI4LITE_WR,
            E_CMD_AXI4LITE_RD,
            E_CMD_AXI4STREAM_WR, 
            E_CMD_AXI4FULL_WR,
            E_CMD_AXI4FULL_RD,
            E_CMD_AXI4STREAM_WR_FRAME,


            E_CMD_SET_TITLE,
            E_CMD_PRINT_TITLE,
            E_CMD_PRINT_LINE,
            E_CMD_DEBUG_STOP,
            E_CMD_MAC_CFG,
            E_CMD_MAC_FWRD,
            E_CMD_CMD_MAX
        } E_CMD;
        typedef struct {
            string label;
            int id; // E_CMD
            int argc;
            int str_argc;
        } parser_cmd_t;
        protected int C_NULL = 0;
        protected int debug;
        protected int fp_rd;
        protected string filename = "";
        protected static parser_cmd_t cmds[] = '{
            '{"unknown", E_CMD_UNKNOWN, 0, 0},
            //WAIT COMMANDS
            '{"wait_ns", E_CMD_WAIT_NS, 1, 0},
            '{"wait_us", E_CMD_WAIT_US, 1, 0},
            '{"wait_ms", E_CMD_WAIT_MS, 1, 0},
            //AXI COMMANDS
            '{"axi4lite_wr", E_CMD_AXI4LITE_WR, 5, 0},
            '{"axi4lite_rd", E_CMD_AXI4LITE_RD, 5, 0},
            '{"axi4stream_wr", E_CMD_AXI4STREAM_WR, 3, 0},
            '{"axi4stream_wr_frame",E_CMD_AXI4STREAM_WR_FRAME, 1, 1},                                          
            '{"axi4full_wr", E_CMD_AXI4FULL_WR,4,0},
            '{"axi4full_rd", E_CMD_AXI4FULL_RD, 4, 0},

            '{"print_title", E_CMD_PRINT_TITLE, 0, 0},
            '{"print_line", E_CMD_PRINT_LINE, 0, 1},
            '{"debug_stop", E_CMD_DEBUG_STOP, 0, 0},
            '{"mac_cfg", E_CMD_MAC_CFG, 0, 0},
            '{"mac_fwrd", E_CMD_MAC_FWRD, 2, 0},
            '{"do_not_use", E_CMD_UNKNOWN, 0, 0} // latest element
        };
        protected int cmd_id;
        protected string line_orig;

        int fp_wr;

        function new (input string filename = "./Stimuli.txt");
            begin
                this.filename = filename;
                debug = 0;

                fp_rd = $fopen(filename, "r");

                if (fp_rd == C_NULL) begin
                    $display ("File not found!");
                end
                else if ($feof(fp_rd)) begin
                    $display( "File empty!");
                    this.close();
                    fp_rd = C_NULL;
                end
                else begin
                    $display( "File name=%0s has been found", filename);
                end
            end
        endfunction : new

        function int getNextCommand(output int cmd, output bit[127:0] params[$], output string str_params[$]);
            int rv;
            string line;
            string line_tolower;
            int cnt;
            int str_cnt;
            bit [128-1:0] p1;
            string s1;
            int scanf_en; // 0=disabled // 1=enabled // 2=disable until end-of-line
            int i;
            int j;
            int end_str_pos;
            int cmd_found;
            int params_count;
            int str_params_count;
            begin
                if (fp_rd != C_NULL) begin
                    if (!$feof(fp_rd)) begin
                        line_orig = "";
                        line = "";
                        rv = $fgets(line_orig, fp_rd);
                        //$display( "line_orig=%0s l_s=%0d l_s=0x%02X", line_orig, rv, rv);
                        line = line_orig.substr(0,line_orig.len()-1);
                        line_tolower=line.tolower(); // this is needed because a limitation of Vivado XSIM tool (do not use the tolower() funtion in chain with other fuintions. i.e. both line.tolower().substr() and line.substr().tolower() sections raise the following error message: ERROR: [XSIM 43-3294] Signal EXCEPTION_ACCESS_VIOLATION received)
                        //$display( "line=%0s l_s=%0d l_s=0x%02X", line, rv, rv);

                        cmd_id = -1;
                        cmd_found = 0;
                        cmd = E_CMD_UNKNOWN;
                        params_count = 0;
                        str_params_count = 0;
                        if (line.substr(0, 1-1) == "#") begin
                            //$display("line starts with #");
                        end
                        else if (line.substr(0, 2-1) == "//") begin
                            //$display("line starts with //");
                        end
                        else if (line.substr(0, 2-1) == "--") begin
                         // $display("line starts with --\n");
                         // $display(line);
                          fp_wr=$fopen(ReportFile,"a+");
                          $fwrite(fp_wr,line);
                          $fclose(fp_wr);
                        end
                        else begin
                            //$display("size->cmds=%0d", $size(cmds));
                            //$display("size->cmds[0]=%0d", $size(cmds[0]));
                            for (i=0; i<$size(cmds); i++) begin
                                if (line_tolower.substr(0, cmds[i].label.len()+1 /*this include round-bracket*/ -1) == { cmds[i].label, "(" }) begin
                                    //$display("Command %0s found", cmds[i].label);
                                    cmd_id = i;
                                    cmd_found = 1;
                                    cmd = cmds[i].id;
                                    params_count = cmds[cmd_id].argc;
                                    str_params_count = cmds[cmd_id].str_argc;
                                end
                                else begin
                                    //$display("Command %0s not found when parsing line %0s", cmds[i].label, line);
                                end
                            end

                            if (cmd_found == 0) begin
                                //$display("line '%0s' not supported", line);
                            end
                        end

                        foreach (line[i]) begin
                            if (line[i] == "\r") begin
                                line_orig[i] = "\0";
                                line[i] = "\0";
                            end
                            else if (line[i] == "\d") begin
                                line_orig[i] = "\0";
                                line[i] = "\0";
                            end
                            else if (line[i] == "\n") begin
                                line_orig[i] = "\0";
                                line[i] = "\0";
                            end
                        end

                        if ((cmd_found == 1) && (cmd_id != -1)) begin
                            //$display("%0s vs %0d [cmd[%0d]=%0s]",line.substr(0, cmds[cmd_id].label.len()-1), cmds[cmd_id].label.len(), cmd_id, cmds[cmd_id]);
                            if (cmd != E_CMD_UNKNOWN) begin
                                //$display("known command");
                            end
                            else begin
                                params_count = 0;
                                str_params_count = 0;
                                cmd = E_CMD_UNKNOWN;
                                $display("line '%0s' not supported", line);
                            end

                            if ((params_count > 0) || (str_params_count > 0)) begin
                                cnt = 0;
                                str_cnt = 0;
                                scanf_en = 0;
                                for (i = 0; i < line.len(); i++) begin
                                    if (line[i] == " ") begin
                                        //$display("space at pos=%0d", i);
                                    end
                                    else if (line[i] == "(") begin
                                        if (scanf_en != 2) begin
                                            scanf_en = 1;
                                        end
                                    end
                                    else if (line[i] == ",") begin
                                        if (scanf_en != 2) begin
                                            scanf_en = 1;
                                        end
                                    end
                                    else if (line[i] == ")") begin
                                        scanf_en = 2;
                                    end
                                    else if (line[i] == "/") begin // comment section active starting from now
                                        scanf_en = 2;
                                    end
                                    else if (line[i] == "-") begin // comment section active starting from now
                                        scanf_en = 2;
                                    end
                                    else if (line[i] == "#") begin // comment section active starting from now
                                        scanf_en = 2;
                                    end
                                    else begin
                                        if (scanf_en == 1) begin
                                            if (line_tolower.substr(i, i+1) == "0x") begin
                                                rv = $sscanf(line.substr(i+2, line.len()-1), "%h", p1);
                                                if (rv == 1) begin
                                                    // a new value has been found
                                                    params = {params, p1};
                                                    //$display("    val=%01d params[%01d]=%01d 0x%01x", rv, cnt, params[cnt], params[cnt]);
                                                    cnt++;
                                                    scanf_en = 0;
                                                end
                                            end
                                            else if (line_tolower.substr(i, i+1) == "'h") begin
                                                rv = $sscanf(line.substr(i+2, line.len()-1), "%h", p1);
                                                if (rv == 1) begin
                                                    // a new value has been found
                                                    params = {params, p1};
                                                    //$display("    val=%01d params[%01d]=%01d 0x%01x", rv, cnt, params[cnt], params[cnt]);
                                                    cnt++;
                                                    scanf_en = 0;
                                                end
                                            end
                                            else if (line_tolower.substr(i, i+1) == "'d") begin
                                                rv = $sscanf(line.substr(i+2, line.len()-1), "%d", p1);
                                                if (rv == 1) begin
                                                    // a new value has been found
                                                    params = {params, p1};
                                                    //$display("    val=%01d params[%01d]=%01d 0x%01x", rv, cnt, params[cnt], params[cnt]);
                                                    cnt++;
                                                    scanf_en = 0;
                                                end
                                            end
                                            else if (line.substr(i, i) == "\"") begin
                                                end_str_pos = 0;
                                                for (int j=i+1; i<line.len(); j++) begin
                                                    if (line.substr(j,j) == "\"") begin
                                                        end_str_pos = j;
                                                        break;
                                                    end
                                                end
                                                //$display("sub_line=%0s (until EOL)", line.substr(i, line.len()-1));
                                                if (end_str_pos != 0) begin
                                                    rv = $sscanf(line.substr(i+1, end_str_pos-1), "%s", s1);
                                                    if (rv == 1) begin
                                                        // a new value has been found
                                                        //$display("sub_line=%0s", line.substr(i, line.len()-1));
                                                        //$display("    val=%0s", s1);
                                                        str_params = {str_params, s1};
                                                        //$display("i=%01d\n", i);
                                                        i = i+s1.len() + 1;
                                                        //$display("i=%01d\n", i);
                                                        str_cnt++;
                                                        scanf_en = 0;
                                                    end
                                                    else begin
                                                        $display("rv=%01d ERROR", rv);
                                                    end
                                                end
                                                else begin
                                                    $display("end_str_pos=%01d ERROR", end_str_pos);
                                                end
                                            end
                                            else begin
                                                rv = $sscanf(line.substr(i, line.len()-1), "%d", p1);
                                                if (rv == 1) begin
                                                    // a new value has been found
                                                    params = {params, p1};
                                                    //$display("    val=%01d params[%01d]=%01d 0x%01x", rv, cnt, params[cnt], params[cnt]);
                                                    cnt++;
                                                    scanf_en = 0;
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                          /*$display("cmd=%0s, cmd_id=%0d, params_count=%0d", cmds[cmd_id], cmd_id, params_count);
                          for (int i=0; i<params_count; i++) begin
                              $display("params[%0d]=%0d 0x%02X (params_count=%0d)", i, params[i], params[i], params_count);
                          end 
                          for (int i=0; i<str_params_count; i++) begin
                              $display("str_params[%0d]='%0s' (str_params_count=%0d)", i, str_params[i], str_params_count);
                          end*/
                           if (cnt != params_count) begin
                               $display("cnt=%01d != params_count=%01d - WARNING: unexpected value\n", cnt, params_count);
                           end
                           if (str_cnt != str_params_count) begin
                               $display("str_cnt=%01d != str_params_count=%01d - WARNING: unexpected value\n", cnt, params_count);
                           end
                            rv = 0;
                        end
                        else begin
                            cmd = E_CMD_UNKNOWN;
                            params_count = 0; // redundant
                            str_params_count = 0; // redundant
                            rv = 0; // line not recognized
                        end
                    end
                    else begin
                        rv = -2; // end of file
                    end
                end
                else begin
                    rv = -1; // file not found
                end
                return rv;
            end
        endfunction : getNextCommand

        function void close();
            begin
                if (fp_rd == C_NULL) begin
                    $display ("File not found!");
                end
                else begin
                    $fclose(fp_rd);
                    $display( "File name=%0s has been closed", filename);
                end
            end
        endfunction : close

        function bit isFileOpen();
            begin
                if (fp_rd != C_NULL) begin
                    return 1'b1; // file previously open
                end
                else begin
                    return 1'b0; // file closed
                end
            end
        endfunction : isFileOpen 

        function string getLastLine();
            begin
                if (fp_rd != C_NULL) begin
                    return line_orig;
                end
                else begin
                    return "";
                end
            end
        endfunction : getLastLine
    endclass : stimuli_parser
endpackage : parser_pkg

