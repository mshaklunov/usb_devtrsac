
module tenv_usbdev;

  //IFACE
  reg           rst0_async=1;
  reg           rst0_sync=1;
          
  wire[1:0]     trsac_type;
  localparam    TYPE_SETUP=0,
                TYPE_OUT=1,
                TYPE_IN=2;
  wire[3:0]     trsac_ep;
  wire[1:0]     trsac_req;
  localparam    REQ_OK=0,
                REQ_ACTIVE=1,
                REQ_FAIL=2;
  reg[1:0]      trsac_reply=0;
  localparam    ACK=0,
                NAK=1,
                STALL=2;
        
  reg           rfifo_rd=0;
  wire          rfifo_empty;
  wire[7:0]     rfifo_rdata;
          
  reg           tfifo_wr=0;
  wire          tfifo_full;
  reg[7:0]      tfifo_wdata=0;
          
  reg[15:1]     ep_enable=15'h7FFF;
  reg[15:1]     ep_isoch=15'b100_0000_0000_0000;
  reg[15:1]     ep_intnoretry=15'b000_0010_0000_0000;
        
  reg           speed=0;
  reg           device_wakeup=0;
  wire[2:0]     device_state;
  parameter     POWERED=0,
                DEFAULT=1,
                ADDRESSED=2,
                CONFIGURED=3;
  wire          sof_tick;
  wire[10:0]    sof_value;
      
  reg[7:0]      buffer[(64*10)-1:0];
  integer       reply_delay=0;
          
  //LOCAL       
  localparam    block_name="tenv_usbdev";
  reg[7:0]      bm_request_type=0;
  reg[7:0]      b_request=0;
  reg[15:0]     w_value=0;
  reg[15:0]     w_index=0;
  reg[15:0]     w_length=0;
  localparam    GET_STATUS=0,
                CLEAR_FEATURE=1,
                SET_FEATURE=3,
                SET_ADDRESS=5,
                GET_DESCRIPTOR=6,
                SET_DESCRIPTOR=7,
                GET_CONFIGURATION=8,
                SET_CONFIGURATION=9,
                GET_INTERFACE=10,
                SET_INTERFACE=11,
                SYNCH_FRAME=12;
    
  //TASKS
  `include "tenv_usbdev/tenv_usbdev.mntr_trsac_off.v"
  `include "tenv_usbdev/tenv_usbdev.reset.v"
  `include "tenv_usbdev/tenv_usbdev.gen_data.v"
  `include "tenv_usbdev/tenv_usbdev.check_data.v"
  `include "tenv_usbdev/tenv_usbdev.trsac_in.v"
  `include "tenv_usbdev/tenv_usbdev.trsac_out.v"
  `include "tenv_usbdev/tenv_usbdev.trsac_setup.v"
  `include "tenv_usbdev/tenv_usbdev.trfer_in.v"
  `include "tenv_usbdev/tenv_usbdev.trfer_out.v"   
  `include "tenv_usbdev/tenv_usbdev.reqstd_getdesc.v"
  `include "tenv_usbdev/tenv_usbdev.reqstd_setconf.v"
  `include "tenv_usbdev/tenv_usbdev.reqstd_clrfeat.v"
  
endmodule
