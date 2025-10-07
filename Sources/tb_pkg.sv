//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2021 05:16:39 PM
// Design Name: 
// Module Name tb_pkg:
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
import types::*;

package tb_pkg;
    parameter TB_DDR_BASE_ADDRESS = 64'h0000000000000000;
    //parameter TB_MOD8_BASE_ADDRESS = 64'h0000020200000000;
    parameter TB_RAM_BASE_ADDRESS = 64'h0000020200000000; // range=0x00200000, name=BRAM
    parameter TB_DCM_BASE_ADDRESS = 64'h0000020201000000; // range=0x00010000, name=APB_M_DCM
    parameter TB_PNS_BASE_ADDRESS = 64'h0000020201010000; // range=0x00010000, name=APB_M_PNS
    parameter TB_HSM_BASE_ADDRESS = 64'h0000020201020000; // range=0x00010000, name=M_AXI_HSM
    parameter TB_REG_BASE_ADDRESS = 64'h0000020201030000; // range=0x00010000, name=M_AXI_REG
    parameter TB_I3C0_BASE_ADDRESS = 64'h0000020201040000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C1_BASE_ADDRESS = 64'h0000020201050000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C2_BASE_ADDRESS = 64'h0000020201060000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C3_BASE_ADDRESS = 64'h0000020201070000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C4_BASE_ADDRESS = 64'h0000020201080000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C5_BASE_ADDRESS = 64'h0000020201090000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C6_BASE_ADDRESS = 64'h00000202010A0000; // range=0x00010000, name=APB_M_I3C0
    parameter TB_I3C7_BASE_ADDRESS = 64'h00000202010B0000; // range=0x00010000, name=APB_M_I3C0
    //parameter TB_EXT8_BASE_ADDRESS = 64'h0000020300000000;
    parameter TB_FIFO_DCM_BASE_ADDRESS = 64'h0000020300000000; // range=0x00010000, name=FIFO_DCM
    parameter TB_FIFO_MAC_BASE_ADDRESS = 64'h0000020300010000; // range=0x00010000, name=FIFO_MAC
    //parameter TB_MOD9_BASE_ADDRESS = 64'h0000020400000000;
    parameter TB_ILKN_BASE_ADDRESS = 64'h0000020400000000; // range=0x00010000, name=Interlaken_8K_xci_0
    //parameter TB_EXT9_BASE_ADDRESS = 64'h0000020500000000;
    parameter TB_NOC_MAC_BASE_ADDRESS = 64'h0000020600000000; // range=0x00010000, name=FIFO_MAC
    parameter TB_PHY_BASE_ADDRESS = 64'h0000020700000000; // range=0x00010000, name=FIFO_MAC
    parameter TB_DMA_DCM_C2C_BASE_ADDRESS = 64'h0000020800000000;
    parameter TB_DMA_HSM_PHY_BASE_ADDRESS = 64'h0000020800010000;
    parameter TB_DMA_MAC_PHY_BASE_ADDRESS = 64'h0000020800020000;

    parameter NULL = 0;               // useful for comparison

endpackage : tb_pkg
