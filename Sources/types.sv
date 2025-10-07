  //========================================================================
  //========================================================================
  // Struct for c2c packet
  //========================================================================
  //========================================================================

package types;
  typedef struct packed {
           int                size;
           bit [4095:0][63:0] payload;
           bit         [ 5:0] ecc;
           bit         [ 3:0] c2c_packet_type;
           bit                seq;
           bit                sos;
           bit                eos;
           bit         [ 7:0] src_id;
           bit         [ 7:0] dst_id;
  } c2c_pkt;

  //========================================================================
  //========================================================================
  // Struct for CB packet
  //========================================================================
  //========================================================================

  typedef struct packed {
           bit         [15:0] output_code_length_bits;
           bit         [15:0] input_code_length_bits;
           bit         [ 6:0] reserved2;
           bit         [ 8:0] sequence_number;
           bit         [ 7:0] tb_index;
           bit         [ 1:0] reserved1;
           bit         [ 1:0] tti;
           bit                last_cb;
           bit         	      reserved0;
           bit         [ 1:0] header_type;
  } cb_pkt;
  
  //========================================================================
  //========================================================================
  // Struct for TB packet
  //========================================================================
  //========================================================================

  typedef struct packed {
           int                size;
           bit [4095:0][63:0] payload;
           bit         [11:0] reserved1;
           bit         [19:0] tb_length_bytes;
           bit                sender_id;
           bit                reserved0;
           bit         [ 5:0] spot_id;
           bit         [ 7:0] mcs;
           bit         [ 7:0] tb_index;
           bit         [ 1:0] preamble_type;
           bit         [ 1:0] tti;
           bit                last_tb;
           bit    	          key_type;
           bit         [ 1:0] header_type;
  } tb_pkt;

  //========================================================================
  //========================================================================
  // Struct for STATISTIC packet
  //========================================================================
  //========================================================================

  typedef struct packed {
           //STATS HEADER
           bit         reserved3;
           bit  [ 5:0] spot_id;
           bit  [ 4:0] sb_id;
           bit  [ 8:0] seq_num;
           bit  [10:0] len;
           bit  [ 4:0] reserved_3;
           bit  [10:0] nominal_cb_len;
           bit  [ 1:0] reserved2;
           bit  [ 5:0] reassembly_id;
           bit         reserved1;
           bit  [ 1:0] tti;
           bit         last;
           bit         traffic_type;
           bit  [ 2:0] header_type;
           //STATS
           bit  [29:0] resvd;
           bit  [ 3:0] first4_cb_pass;
           bit         all_cb_pass;
           bit         all_cb_fail;
           bit  [ 7:0] cb_size_enc;
           bit  [10:0] cb_len;
           bit  [ 8:0] unique_tb_id;
  } stat_pkt;
endpackage : types
