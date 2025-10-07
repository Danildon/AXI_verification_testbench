`timescale 1ns / 1ps
import axi_vip_pkg::*;


import parser_pkg::ReportFile;
import parser_pkg::axi4_lite_data_size;


import TEST_AXI_VIP_ENV_axi_vip_0_0_pkg::*;
//If others axi_vip are required import here the related packege ex: 
//<design_name>_<ip_name>_0::*;



class Axi4lite_handler;

 
   //If others ax_vip are required decleare the here ex: 
  //  <design_name>_axi_vip_<number of_vip>_0_<mst/slv>_t <instance name>;

  TEST_AXI_VIP_ENV_axi_vip_0_0_mst_t master_agent;

    integer file_wr;

     


    task automatic AXI4LITE_WRITE(

              input                  xil_axi_uint                                id            ,
              input                  bit          [256-1:0]                       address       ,
              input                  xil_axi_len_t                               len           ,
              input                  xil_axi_size_t                              size          ,
              input                  xil_axi_burst_t                             burst         ,
              input                  xil_axi_lock_t                              lock          ,
              input                  xil_axi_cache_t                             cache         ,
              input                  xil_axi_prot_t                              prot          ,
              input                  xil_axi_region_t                            region        , 
              input                  xil_axi_qos_t                               qos           ,
              input                  xil_axi_user_beat                           auser         ,
              input                  bit          [axi4_lite_data_size-1:0]                       data_wr_array ,
              input                  xil_axi_data_beat [255:0]                   duser         ,
              input                  xil_axi_resp_t [255:0]                      rresp         ,
              int                                                                vip_sel     );


      time wr_time;

      begin 

  
      case(vip_sel)  
        0:  this.master_agent.AXI4LITE_WRITE_BURST(address,0,data_wr_array,rresp); 

           
     //If others axi_vip are required send the transaction here: 

      /* 2:this.<agent_name>.AXI4LITE_WRITE_BURST(address,0,data_rd_array,rresp);
            
                                  ...

        N: this.<agent_name>.AXI4LITE_WRITE_BURST(address,0,data_rd_array,rresp);
            
                                                                                        */
      endcase
        print_wr(address,data_wr_array,$time,vip_sel);
      end  

    endtask         

    task automatic AXI4LITE_READ(

              input                  xil_axi_uint                                id            ,
              input                  bit          [256-1:0]                      address       ,
              input                  xil_axi_len_t                               len           ,
              input                  xil_axi_size_t                              size          ,
              input                  xil_axi_burst_t                             burst         ,
              input                  xil_axi_lock_t                              lock          ,
              input                  xil_axi_cache_t                             cache         ,
              input                  xil_axi_prot_t                              prot          ,
              input                  xil_axi_region_t                            region        , 
              input                  xil_axi_qos_t                               qos           ,
              input                  xil_axi_user_beat                           auser         ,
              input                  bit          [axi4_lite_data_size-1:0]                       exp_val       ,
              input                  xil_axi_data_beat [255:0]                   duser         ,
              input                  xil_axi_resp_t [255:0]                      rresp         ,             
              int                                                                vip_sel
                  );

      time rd_time;
      bit                 [32-1:0] data_rd_array;  

      begin
        case(vip_sel)

        0: master_agent.AXI4LITE_READ_BURST(address,0,data_rd_array,rresp);
        
         //If others axi_vip are required send and monitor the transaction here: 

        /* 2: this.<agent_name>.AXI4LITE_READ_BURST(address,0,data_rd_array,rresp);
            
                                  ...

        N: this.<agent_name>.AXI4LITE_READ_BURST(address,0,data_rd_array,rresp);
            
           
                                                             */

        endcase  

        print_rd(address,data_rd_array, exp_val, $time ,vip_sel);
      end 

    endtask            

    task automatic print_rd(input bit [32-1:0] address , input bit [32-1:0] data,  input bit [32-1:0] exp_val, input time rd_time,int vip_sel);

       file_wr = $fopen(ReportFile,"a+");

      
     
        $fwrite(file_wr, "\n-------------------------------------------\n\n\AXI4-LITE Read Transaction EXECUTED!!!\n\n  # AXI VIP Selected :%d\n  # Address          : 0x%8h\n  # Expected Data    : 0x%8h\n  # Read Data        : 0x%8h \n\n  # TIME             : %t\n\n------------------------------------------- \n",vip_sel,address,exp_val,data,rd_time);
        $display("\n-------------------------------------------\n\n\AXI4-LITE Read Transaction EXECUTED!!!\n\n  # AXI VIP Selected :%d\n  # Address          : 0x%8h\n  # Expected Data    : 0x%8h\n  # Read Data        : 0x%8h \n\n  # TIME             : %t\n\n------------------------------------------- \n",vip_sel,address,exp_val,data,rd_time);

        if(data== exp_val) begin
          $fwrite(file_wr,"\n !READ DATA IS THE SAME AS EXPECTED!!!\n\n\n");
          $display("\n !READ DATA IS THE SAME AS EXPECTED!!!\n\n\n");

        end  
        else begin
          $fwrite(file_wr,"\n !WARNING READ DATA DOES NOT MATCH THE EXPECTED ONE\n\n\n");  
          $display("\n !WARNING READ DATA DOES NOT MATCH THE EXPECTED ONE\n\n\n");  
        end
       
        $fclose(file_wr);

    endtask //                        

     task automatic print_wr(input bit [32-1:0] address , input bit [32-1:0] data, input time wr_time, int vip_sel);

       file_wr = $fopen(ReportFile,"a+");

       $fwrite(file_wr,"\n-------------------------------------------\n\nAXI4-LITE WRITE Transaction EXECUTED!!!\n # AXI VIP Selected :%d \n # Address          : 0x%8h \n # Write Data       : 0x%8h \n\n # TIME             : %t \n-------------------------------------------\n\n\n ",vip_sel,address,data,wr_time);
       $display("\n-------------------------------------------\n\nAXI4-LITE WRITE Transaction EXECUTED!!!\n # AXI VIP Selected :%d \n # Address          : 0x%8h \n # Write Data       : 0x%8h \n\n # TIME             : %t \n-------------------------------------------\n\n\n ",vip_sel,address,data,wr_time);

       $fclose(file_wr);

    endtask //                                                                        

    task start();
      master_agent = new("master vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4lite_vip_0.inst.IF);   
      // Set tag for AXI4 Master agents for easy debug
      master_agent.set_agent_tag("Master VIP lite");
      // Set print out verbosity level.
      master_agent.set_verbosity(0);  
      master_agent.start_master();
      

        // If other Vips are rquired contruct the agent and start it  here ex:
       
        /*  
        this.<agent_name> =new("<slave/master> vip agent",Top_TB.UUT.<design name>_i.axi_vip_<number of the Vip>.inst.IF);
        this.<agent_name>.set_agent_tag("<agent tag>");
        this.<agent_name>.start_<master/slave>();  
        */  

    endtask //

endclass //axi4_agent 

