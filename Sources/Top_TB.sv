
`include "parameters.sv"
`include "axi4stream.sv"
`include "axi4lite.sv"
`include "axi4full.sv"
import parser_pkg::ReportFile;

module Top_TB;
    
 
   
    TEST_AXI_VIP_ENV_wrapper UUT();


	Parser #(
        .StimuliFile ("../../../../../TESTBENCH/Current_Stimuli.txt")
    ) Parser_i (); 
	report_producer report_producer_i(); 
    
    Axi4lite_handler   axi4lite_handler;
    Axi4stream_handler axi4stream_handler;
    Axi4Full_handler   axi4full_handler;

    initial begin
    

		// Start clocks IPs
        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.clk_vip_axi4.inst.IF.start_clock();
        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.clk_vip_axi4stream.inst.IF.start_clock();
        

       // assert reset

        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.rst_vip_axi4.inst.IF.assert_reset();
        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.rst_vip_axi4stream.inst.IF.assert_reset();
  
        #1000
	
        // deassert reset
        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.rst_vip_axi4.inst.IF.deassert_reset();
        UUT.TEST_AXI_VIP_ENV_i.AXI_VIPs.rst_vip_axi4stream.inst.IF.deassert_reset();

       
        // initialize handler objects
        
        axi4stream_handler = new();
        axi4lite_handler   = new();
        axi4full_handler   = new();
        // start the handlers
        axi4lite_handler.start();
        axi4stream_handler.start();
        axi4full_handler.start();

     
        
         axi4stream_handler.main();

   end

   
   initial begin
      $timeformat (-9, 3, " ns", 13);
   end
   
   initial begin

   end

   endmodule