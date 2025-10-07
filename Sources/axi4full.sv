`timescale 1ns / 1ps
import axi_vip_pkg::*;

import TEST_AXI_VIP_ENV_axi_vip_1_0_pkg::*;
//If others axi_vip are required import here the related packege ex:
// <design_name>_axi_vip_<number of_vip>_0::*;


import parser_pkg::ReportFile;

import parser_pkg::axi4full_data_size;
import parser_pkg::axi4full_address_size;



class Axi4Full_handler;
    
   TEST_AXI_VIP_ENV_axi_vip_1_0_mst_t master_agent_full;
    

    bit rand_flag=0;
    int id;
    integer file_wr;
    
    


    task AXI4FULL_WRITE(input bit [ axi4full_address_size  -  1 :0] address,input bit [axi4full_data_size - 1 :0] data,input int blen ,int vip_sel);
    
        axi_transaction                                          wr_transaction;
        axi_monitor_transaction                                  wr_monitor_transaction;
        xil_axi_data_beat [255:0]                                mtestWUSER;
    
        wr_transaction = master_agent_full.wr_driver.create_transaction("write transaction in outstanding transaction example with full randomization");

  
          begin              
       
           wr_transaction.set_write_cmd(address,XIL_AXI_BURST_TYPE_INCR, blen, blen, xil_axi_size_t'(2));
          
           wr_transaction.set_prot(0);
           wr_transaction.set_lock(XIL_AXI_ALOCK_NOLOCK);
           wr_transaction.set_cache(3);
           wr_transaction.set_region(0);
           wr_transaction.set_qos(0); 
          // wr_transaction.set_wuser(1'b1);
           wr_transaction.set_data_block(data);
           for(int beat=0; beat < blen; beat++)                                                  
            wr_transaction.set_data_beat(beat,data + beat,0,3);  // 0 deley, 3 strb to keep all 
           end 
        
           
          case(vip_sel)

          0:begin
            
            this.master_agent_full.wr_driver.send(wr_transaction);
          //this.master_agent_full.wr_driver.wait_rsp(wr_transaction);
            master_agent_full.monitor.item_collected_port.get(wr_monitor_transaction);

          end 
          //If others axi_vip are required send and monitor the transaction here:                       
        /* 2:begin
            this.<agent_name>.driver.send(wr_transaction);
            this.<agent_name>.monitor.item_collected_port.get(wr_monitor_transaction);
          end
                                  ...

          N:begin
            this.<agent_name>.driver.send(wr_transaction);
            this.<agent_name>.monitor.item_collected_port.get(wr_monitor_transaction);
           end
                                                             */

       
          endcase 
            monitor_wr_data_method_one(wr_monitor_transaction, vip_sel, $time);

    endtask

    task automatic AXI4FULL_READ(input bit [axi4full_address_size - 1:0] address, input int blen, input bit [ axi4full_data_size-1 :0] exp_value, int vip_sel);

          axi_transaction                                          rd_transaction;            // Read transaction
          axi_monitor_transaction                                  rd_monitor_transaction;

         /************************************************************************************************
        * A burst can not cross 4KB address boundry for AXI4
        * Maximum data bits = 4*1024*8 =32768
        * Write Data Value for WRITE_BURST transaction
        * Read Data Value for READ_BURST transaction
        ************************************************************************************************/
         rd_transaction = master_agent_full.rd_driver.create_transaction("read transaction in outstanding transaction example with full randomization");    
        // addr , lung , data , rand

         rd_transaction.set_read_cmd(address,XIL_AXI_BURST_TYPE_INCR,blen,blen,xil_axi_size_t'(2));
         rd_transaction.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
         rd_transaction.set_prot(0);
         rd_transaction.set_lock(XIL_AXI_ALOCK_NOLOCK);
         rd_transaction.set_cache(3);
         rd_transaction.set_region(0);
         rd_transaction.set_qos(0); 
                             
       
        case(vip_sel) 

        0:begin
          this.master_agent_full.rd_driver.send(rd_transaction); 
          master_agent_full.monitor.item_collected_port.get(rd_monitor_transaction);
          end
        
           //If others axi_vip are required send and monitor the transaction here:                       
        /* 2:begin
            this.<agent_name>.driver.send(wr_transaction);
            this.<agent_name>.monitor.item_collected_port.get(wr_monitor_transaction);
          end
                                  ...

          N:begin
            this.<agent_name>.driver.send(wr_transaction);
            this.<agent_name>.monitor.item_collected_port.get(wr_monitor_transaction);
           end
                                                             */
          endcase
          monitor_rd_data_method_one(rd_monitor_transaction, exp_value, vip_sel);
    endtask //

    

    task automatic monitor_rd_data_method_one(input axi_monitor_transaction updated, input bit[ axi4full_data_size - 1:0] exp_val, int vip_sel);
        xil_axi_data_beat                       mtestDataBeat[];
        bit[8*4*6-1:0]                          data_block;

        file_wr = $fopen(ReportFile, "a+");
        mtestDataBeat = new[updated.get_len()];
        data_block = updated.get_data_block();


        $display("\n-------------------------------------------\n\n\n\ AXI4 Read Transaction EXECUTED!!!\n\n # AXI VIP Selected   :%d \n # Address            : 0x%8h \n # Length(Burst Count): %d\n DATA  \n",vip_sel,updated.get_addr(),updated.get_len());
        $fwrite(file_wr,"\n-------------------------------------------\n\n\n\ AXI4 Read Transaction EXECUTED!!!\n\n # AXI VIP Selected   :%d \n # Address            : 0x%8h \n # Length(Burst Count): %d\n DATA  \n",vip_sel,updated.get_addr(),updated.get_len());


        for( xil_axi_uint beat=0; beat < updated.get_len(); beat++) begin
          mtestDataBeat[beat] = updated.get_data_beat(beat);

          $display("\n    %d° beat: READ: 0x%8h  EXP : 0x%8h \n", beat, mtestDataBeat[beat], exp_val+beat);
         
          $fwrite( file_wr, "\n    %d° beat: READ: 0x%8h  EXP : 0x%8h \n", beat, mtestDataBeat[beat], exp_val+beat);
          
            if(mtestDataBeat[beat] != exp_val + beat ) begin
              $fwrite(file_wr,"\n ########################################### \n");
              $fwrite(file_wr,"\n ! WARNING exp_val: 0x%8h !=  read value: 0x%8h at index: %d \n",exp_val + beat, mtestDataBeat[beat],beat );

              $display("\n ########################################### \n");
              $display("\n ! WARNING \n exp_val: 0x%8h !=  read value: 0x%8h at index: %d \n",exp_val + beat , mtestDataBeat[beat],beat );

            end
          
        end  
        $fwrite(file_wr,"\n  # TIME      : %t \n\n---------------------------------\n",$time);
        $display(file_wr,"\n  # TIME      : %t \n\n---------------------------------\n",$time);

        $fclose(file_wr);  
      endtask

      task automatic monitor_wr_data_method_one(input axi_monitor_transaction updated,int vip_sel, time mst_t );
        xil_axi_data_beat                         mtestDataBeat[];
        bit[8*4*6-1:0]                            data_block;

        file_wr = $fopen(ReportFile, "a+");
        mtestDataBeat = new[updated.get_len()];
        data_block = updated.get_data_block();


        $fwrite(file_wr,"\n-------------------------------------------\n\n\n\ AXI4 Write Transaction EXECUTED!!!\n\n # AXI VIP Selected   :%d \n # Address            : 0x%8h \n # Length(Burst Count): %d\n DATA: \n\n",vip_sel,updated.get_addr(),updated.get_len());
        $display("\n-------------------------------------------\n\n\n\AXI4 Write Transaction EXECUTED!!!\n\n # AXI VIP Selected   :%d \n # Address            : 0x%8h \n # Length(Burst Count): %d\n DATA: \n\n",vip_sel,updated.get_addr(),updated.get_len());

        for( xil_axi_uint beat=0; beat < updated.get_len(); beat++) begin
          mtestDataBeat[beat] = updated.get_data_beat(beat);

          $display("AXI4FULL Write data from Monitor of the Vip number %d: beat index %d, Data beat %4h at time :%t\n",vip_sel ,beat, mtestDataBeat[beat],$time);
          $display("#############################################################\n");

          $fwrite(file_wr,"\n       %d° beat: 0x%8h  \n",beat, mtestDataBeat[beat]);
          $display("\n       %d° beat: 0x%8h  \n",beat, mtestDataBeat[beat]);
        
        
         end  
         $fwrite(file_wr,"\n  # TIME      : %t \n\n---------------------------------\n",mst_t);
         $display("\n # TIME      : %t \n\n---------------------------------\n",mst_t);
         

         $fclose(file_wr);
      endtask

    task start();
        master_agent_full= new("master vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4_vip_1.inst.IF);
        master_agent_full.set_agent_tag("Master VIP FULL");//set agent tag for easy debug
        // Set print out verbosity level.
        master_agent_full.set_verbosity(0);
        master_agent_full.start_master();

      /***********************************************************************************************
      *  If other Vips are rquired contruct the agent and start it  here ex:
        
      *  this.<agent_name> =new("<slave/master> vip agent",Top_TB.UUT.<design name>_i.axi4stream_vip_<number of the Vip>.inst.IF);
      *  this.<agent_name>.set_agent_tag("<agent_tag>");
      *  this.<agent_name>.set_verbosity("<verbosity>");
      *  this.<agent_name>.start_<master/slave>();
       
       ***********************************************************************************************/  
        rand_flag=0;
        id=0;
        


     /***********************************************************************************************
    * The hierarchy path of the AXI VIP's interface is passed to the agent when it is newed. 
    * Method to find the hierarchy path of AXI VIP is to run simulation without agents being newed, 
    * message like "Xilinx AXI VIP Found at Path: " will 
    * be printed out.
    ***********************************************************************************************/
    endtask //


endclass //Axi4Full_handler