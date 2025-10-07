
import axi4stream_vip_pkg::*;

import TEST_AXI_VIP_ENV_axi4stream_vip_3_0_pkg::*;
import TEST_AXI_VIP_ENV_axi4stream_vip_2_0_pkg::*;
import TEST_AXI_VIP_ENV_axi4stream_vip_1_0_pkg::*;
import TEST_AXI_VIP_ENV_axi4stream_vip_0_0_pkg::*;

import parser_pkg::ReportFile;
import parser_pkg::axi4stream_data_size;
import parser_pkg::N_AXI4STREAM_MASTER_VIP;
import parser_pkg::N_AXI4STREAM_SLAVE_VIP;
import parser_pkg::base_frame_dir;
import parser_pkg::base_dir;

//If others axi4stream_vip are required import here the related packege ex: 
//<design_name>_axi4stream_vip_<number of_vip>_0::*;


class Axi4stream_handler;

   TEST_AXI_VIP_ENV_axi4stream_vip_0_0_mst_t master_agent_stream_0;
   TEST_AXI_VIP_ENV_axi4stream_vip_1_0_mst_t master_agent_stream_1;
   TEST_AXI_VIP_ENV_axi4stream_vip_3_0_slv_t slave_agent_stream_1;
   TEST_AXI_VIP_ENV_axi4stream_vip_2_0_slv_t slave_agent_stream_0;
    //If others axi4stream_vip are required decleare the here ex: 
    //<design_name>_axi4stream_vip_<number of_vip>_0_<mst/slv>_t

    
    semaphore sem[N_AXI4STREAM_MASTER_VIP]; 
    semaphore sem_frame[N_AXI4STREAM_MASTER_VIP];
    semaphore sem_main;
    semaphore sem_slv[N_AXI4STREAM_SLAVE_VIP];
    semaphore sem_frame_slv[N_AXI4STREAM_SLAVE_VIP];
    int slv_reportfile_array[N_AXI4STREAM_SLAVE_VIP];
    integer file_wr;

    string file_rd_path[N_AXI4STREAM_MASTER_VIP][$];
    string file_dump_path;
    string slv_dump_path;
    string slv_dump_paths[N_AXI4STREAM_SLAVE_VIP];

    bit [axi4stream_data_size - 1: 0] data_wr[N_AXI4STREAM_MASTER_VIP][$];
    int vip_sel;
    int blen[N_AXI4STREAM_MASTER_VIP][$];
    int fp_dump_r;
    int slv_active;

    task automatic main();
        fork
             begin 
                while(1)begin
                    this.sem[0].get(1);
                    this.axi4stream_wr_rand(this.blen[0].pop_front(),this.data_wr[0].pop_front(),0,1);
                end
             end
             begin
                while(1)begin
               
                    this.sem[1].get(1);
                    this.axi4stream_wr_rand(this.blen[1].pop_front(),this.data_wr[1].pop_front(),1,1); 


                end     
            end
        // If other mst Vips are rquired :

            /*
              begin
                while(1)begin
               
                    this.sem[N].get(1);
                    this.axi4stream_wr_rand(this.blen[N].pop_front(),this.data_wr[N].pop_front(),N,1); 

                end     
            end
            
            */

            begin
                while(1) begin
                    this.sem_frame[0].get(1);
                    this.axi4stream_wr_frame(0,this.file_rd_path[0].pop_front());

                end
            end
            begin
                while(1) begin
                    this.sem_frame[1].get(1);
                    this.axi4stream_wr_frame(1,this.file_rd_path[1].pop_front());
                end

            end    
           // If other mst Vips are rquired :
            /*
            begin
                while(1) begin
                    this.sem_frame[N].get(1);
                    this.axi4stream_wr_frame(N,this.file_rd_path[N].pop_front());
                end

            end    
            
            
            */

            begin
                while(1) begin
                    this.slave_listen();
                end
            end  
        join;
        
    endtask
    

    task automatic axi4stream_wr_rand(int burst_len, bit[ axi4stream_data_size - 1:0] data_wr_array, int sel,int rand_flag);
         
        xil_axi4stream_uint                           total_transfer;
        bit[1*8-1:0]                                  data_beat;
        bit[31:0]                                     payload;
        axi4stream_ready_gen                          ready_gen,ready_gen_2;
        axi4stream_transaction                        wr_transaction;
        axi4stream_transaction                        wr_transactionc;    
        bit [32-1:0] data=0;
        time                                           slv_t;
        time                                           mst_t;

         axi4stream_monitor_transaction                 mst_monitor_transaction;
         axi4stream_monitor_transaction                 slv_monitor_transaction;
                fork
                    begin 
                        case (sel)
                            0: wr_transaction = this.master_agent_stream_0.driver.create_transaction("wr transaction");
                            1: wr_transaction = this.master_agent_stream_1.driver.create_transaction("wr transaction");
                        endcase
                            wr_transaction.set_user_beat(1);
                        for ( int i = 0 ; i < burst_len ; i++ ) begin
                            wr_transaction.set_data_beat(data_wr_array+i);
                            if( i == burst_len - 1 )
                                wr_transaction.set_last(1); 
                            else
                                wr_transaction.set_last(0); 
                            if ( i == 0 )begin
                                mst_t = $time;
                            end
                            else 
                                wr_transaction.set_user_beat(0);

                            case (sel)
                                0:begin
                                    this.master_agent_stream_0.driver.send(wr_transaction); 
                                    this.master_agent_stream_0.monitor.item_collected_port.get(mst_monitor_transaction);                                   
                                    mst_t=$time;
                                   end
                                1:begin
                                    this.master_agent_stream_1.driver.send(wr_transaction);
                                    this.master_agent_stream_1.monitor.item_collected_port.get(mst_monitor_transaction); 
                                    mst_t=$time;
                                   end

                            endcase
                            this.print_mon_tr(  mst_monitor_transaction, sel, i, burst_len);
                        end 
                         
                    end 
                    begin
                        ready_gen = new();  
                        ready_gen_2 = new();  
                            begin    
                                fork  
                                   begin 
                                    ready_gen = slave_agent_stream_0.driver.create_ready("ready_gen");
                                    ready_gen.set_low_time(2);
                                    ready_gen.set_high_time(6);
                                    this.slave_agent_stream_0.driver.send_tready(ready_gen);
                                   end
                                   begin
                                    ready_gen_2 =slave_agent_stream_1.driver.create_ready("ready_gen");
                                    ready_gen_2.set_low_time(2);
                                    ready_gen_2.set_high_time(6);
                                    slave_agent_stream_1.driver.send_tready(ready_gen_2);
                                    
                                   end
                            
                                join
                            end
                    end
                join
    endtask //

    task automatic slave_listen();

         axi4stream_monitor_transaction slv_monitor_transaction[N_AXI4STREAM_SLAVE_VIP];
         slave_agent_stream_0.start_monitor();
         slave_agent_stream_1.start_monitor();

        fork
            begin              
                                     
                this.slave_agent_stream_0.monitor.item_collected_port.get(slv_monitor_transaction[0]);
                
                this.print_mon_slv(slv_monitor_transaction[0],0,$time);
                this.slv_frame_routine(slv_monitor_transaction[0],0);
                
            end  
            begin  
                this.slave_agent_stream_1.monitor.item_collected_port.get(slv_monitor_transaction[1]);
                
                this.print_mon_slv(slv_monitor_transaction[1],1,$time);
                this.slv_frame_routine(slv_monitor_transaction[1],1);
                
            end  
        join_any 
        //wait fork; 
                
       
    endtask
    

    task automatic axi4stream_wr_frame(int vip_sel, string file_rd );

        bit tuser_flag;
        int fp_frame;
        int counter;
        bit [axi4stream_data_size-1 :0] data_wr;
        int                                           rd_c;
        bit[4-1:0]                                    tmp_halfbyte;
        axi4stream_ready_gen                          ready_gen,ready_gen_2;
        bit [axi4stream_data_size-1:0]                ext_data       ;
        axi4stream_transaction                        wr_transaction,wr_transaction_r;
        axi4stream_monitor_transaction                slv_monitor_transaction;
        string frame_conc;

        begin

            #0
            file_wr = $fopen(ReportFile,"a+");
            $fwrite(file_wr,"-------------------------------------------------\n AXI4STREAM VIP NUM: %d STARTED A FRAME TRANSACTION FROM FILE %s\n\n--at time %t\n---------------------------------------\n",vip_sel,file_rd,$time);
            $fclose(file_wr);
            #0

            frame_conc = {base_frame_dir,file_rd};
            $display("%s",frame_conc);
            
            fp_frame=$fopen(frame_conc,"r");
            if(fp_frame==0) begin
                $display("FILE NOT FOUND");

            end
            else begin
                $display("FILE FOUND...");
            end
            counter = (axi4stream_data_size/4)-1;
            tuser_flag=1;

            case(vip_sel)

                0: wr_transaction = this.master_agent_stream_0.driver.create_transaction("wr transaction");
                1: wr_transaction = this.master_agent_stream_1.driver.create_transaction("wr transaction");
            //N:   wr_transaction = this.master_agent_stream_N.driver.create_transaction("wr transaction");
            endcase
            
            while(!$feof(fp_frame)) begin
                
                rd_c = $fgetc(fp_frame);
                $display(" read char is %c",rd_c);
                tmp_halfbyte = bitfy(rd_c);
                
                for(int i=0 ; i<4; i++)
                    data_wr[4*counter+i] = tmp_halfbyte[i]; 
                   
                if(counter > 0)
                   counter = counter - 1;
                else begin
                    counter=(axi4stream_data_size/4)-1;
                
                    if(tuser_flag) begin
                        wr_transaction.set_user_beat(1);
                        tuser_flag=0;
                    end 
                    else
                        wr_transaction.set_user_beat(0);
                    
                    wr_transaction.set_data_beat(data_wr);
                    
                    if(!$feof(fp_frame)) begin
                        rd_c = $fgetc(fp_frame);
                        $display(" read char is %c",rd_c);
                    end
                    if(rd_c == "\n" || $feof(fp_frame))
                        wr_transaction.set_last(1);
                    else begin
                        wr_transaction.set_last(0);
                        $ungetc(rd_c,fp_frame);
                    end
                        
                    case (vip_sel)
                        0: this.master_agent_stream_0.driver.send(wr_transaction);
                        1: this.master_agent_stream_1.driver.send(wr_transaction);
                      //N: this.master_agent_stream_N.driver.send(wr_transaction); 
                    endcase
                end
            end
            $fclose(fp_frame);
        end
    endtask


   task automatic slv_frame_routine(axi4stream_monitor_transaction slv_monitor_transaction,int slv_active);

    bit [axi4stream_data_size-1:0]                  ext_data;
    
    bit [8-1:0]                                     tmp_byte;

                    
    begin                        
        slv_reportfile_array[slv_active]= $fopen(slv_dump_paths[slv_active],"a");

        ext_data = slv_monitor_transaction.get_data_beat();

        $display("DATA_BEAT: 0x%8h",ext_data);
      /*  for( xil_axi_uint beat=0; beat < axi4stream_data_size; beat+=8) begin
            for(int i = 0; i < 8; i++)
                tmp_byte[i] = ext_data[beat+i];
                if(!slv_monitor_transaction.get_last())
                $fwrite(slv_reportfile_array[slv_active] ,"%2h",tmp_byte);
              //  $display("dumping  0x%2h", tmp_byte);
            end                  
        */
        $fwrite(slv_reportfile_array[slv_active] ,"%8h",ext_data);
        
        if(slv_monitor_transaction.get_last())
            $fwrite(slv_reportfile_array[slv_active],"\n");
        
        $fclose(slv_reportfile_array[slv_active]);     
     end                   

   endtask



    task print_mon_tr( axi4stream_monitor_transaction tr_m, int sel,int i,int blen);

        xil_axi4stream_data_beat data;
        begin
            
            data = tr_m.get_data_beat();

            file_wr = $fopen(ReportFile,"a+");
       
            if(i==0) begin
             $fwrite(file_wr,"\n-------------------------------------------\n\n AXI4-STREAM Packet GENERATED!!!\n\n\n # AXI VIP Selected : %d\n # Length           : %d\n # Init Data        : 0x0%8h  \n\n # TIME             : %t\n ",sel,blen,data,$time);
             $display("\n-------------------------------------------\n\n AXI4-STREAM Packet GENERATED!!!\n\n\n # AXI VIP Selected : %d\n # Length           : %d\n # Init Data        : 0x0%8h  \n\n # TIME             : %t\n ",sel,blen,data,$time);
            end
            else
            if(i < blen) begin
             $fwrite(file_wr,"\n VIP %d # Succesive Data   : 0x%8h \n - from Init Data %d \n - time: %t \n",sel,data,i, $time);
             $display("\n # Succesive Data   : 0x%8h \n - from Init Data %d \n - time: %t",data,i, $time);
            end

            $fclose(file_wr);
        end
        
        
    endtask //

    task automatic print_mon_slv(axi4stream_monitor_transaction tr_s, int slv_active, time slv_time);
        xil_axi4stream_data_beat data;

        begin
            data = tr_s.get_data_beat;
            file_wr = $fopen(ReportFile,"a+");
            
            if(tr_s.get_last())
                $fwrite(file_wr, "\n-SLAVE AXI4 VIP number:%d \n received a TRANSACTION of TDATA-TLAST: 0x%8h \n at time %t \n",slv_active , data, slv_time);
            else if(tr_s.get_user_beat())
                $fwrite(file_wr, "\n-SLAVE AXI4 VIP number:%d \n received a TRANSACTION of TDATA-TUSER: 0x%8h \n at time %t \n",slv_active , data, slv_time);
            else
                $fwrite(file_wr, "\n-SLAVE AXI4 VIP number:%d \n received a TRANSACTION of TDATA: 0x%8h \n at time %t \n",slv_active , data, slv_time);
            
            $fwrite(file_wr, "\n--------------------\n");



            $display( "\n-SLAVE AXI4 VIP number:%d \n received a tr of TDATA: 0x%8h \n at time %t \n",slv_active , data, slv_time);
            $fwrite(file_wr, "\n--------------------\n");

            $fclose(file_wr);
            

        end
    endtask
    
    
    task start;

        this.master_agent_stream_0 = new("master vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4stream_vip_0.inst.IF);
        this.master_agent_stream_0.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        this.master_agent_stream_0.start_master();  

        this.master_agent_stream_1 = new("master vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4stream_vip_1.inst.IF);
        this.master_agent_stream_1.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        this.master_agent_stream_1.start_master();  
        
        this.slave_agent_stream_0=new("slave vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4stream_vip_2.inst.IF);
        this.slave_agent_stream_0.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        this.slave_agent_stream_0.start_slave();

        this.slave_agent_stream_1=new("slave vip agent",Top_TB.UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.axi4stream_vip_3.inst.IF);
        this.slave_agent_stream_1.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        this.slave_agent_stream_1.start_slave();

        // If other Vips are required contruct the agent and start it  here ex:
       
        /* ********************************************
        
        this.<agent_name> =new("<slave/master> vip agent",Top_TB.UUT.<design name>_i.axi4stream_vip_<number of the Vip>.inst.IF);
        this.<agent_name>.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
        this.<agent_name>.start_<master/slave>();
        
        
        ************************************************* */  
       
        for(int i=0;i<N_AXI4STREAM_MASTER_VIP;i++) begin
            this.sem[i].get(1);
            this.sem_frame[i].get(1);
        end    

    endtask

    function automatic bit[3:0] bitfy(int rd_c);
       if(rd_c < 58 && rd_c > 47) begin
        return(rd_c - 48);
       end else
       begin
        return(rd_c - 87);
       end
        
    endfunction

   
    //  Constructor: new
    function new();

        file_wr=$fopen(ReportFile,"w");
        $fclose(file_wr);

        slv_dump_path = "Current_slv";

      
        for(int i = 0; i< N_AXI4STREAM_MASTER_VIP ; i++) begin

            sem[i]=new(1);
            sem_frame[i]=new(1);
            
        end    

        for(int i = 0; i < N_AXI4STREAM_SLAVE_VIP ; i++) begin
            slv_reportfile_array[i] =$fopen( {base_frame_dir,slv_dump_path,$sformatf("_%1d.txt",i)},"w");
            $fclose(slv_reportfile_array[i]);
            slv_dump_paths[i] = {base_dir,slv_dump_path,$sformatf("_%1d.txt",i)};
        end
    endfunction
    
    
    

endclass //axi4strem
