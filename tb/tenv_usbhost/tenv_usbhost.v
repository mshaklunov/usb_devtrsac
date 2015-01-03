
module tenv_usbhost;
  //IFACE
  reg[7:0]      buffer[(64*10)-1:0];
  reg[6:0]      dev_addr=0;
  reg[15:0]     toggle_bit=0;
  localparam    ACK=0,
                NAK=1,
                STALL=2,
                NOREPLY=3,
                HSKERR=4,
                DATAERR=5;
      
  //LOCALS    
  localparam    block_name="tenv_usbhost";
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
  `include "tenv_usbhost/tenv_usbhost.gen_data.v"
  `include "tenv_usbhost/tenv_usbhost.check_data.v"
  `include "tenv_usbhost/tenv_usbhost.trsac_in.v"
  `include "tenv_usbhost/tenv_usbhost.trsac_out.v"
  `include "tenv_usbhost/tenv_usbhost.trsac_setup.v"
  `include "tenv_usbhost/tenv_usbhost.trsac_sof.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_isoch_out.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_isoch_in.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_bulk_in.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_bulk_out.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_control_in.v"
  `include "tenv_usbhost/tenv_usbhost.trfer_control_out.v"
  `include "tenv_usbhost/tenv_usbhost.reqstd_getdesc.v"
  `include "tenv_usbhost/tenv_usbhost.reqstd_setaddr.v"
  `include "tenv_usbhost/tenv_usbhost.reqstd_setconf.v"
  `include "tenv_usbhost/tenv_usbhost.reqstd_clrfeat.v"
    
endmodule
