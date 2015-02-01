//MODULE REFERENCE
`define   tenv_usb_encoder  tenv_usbhost.tenv_usb_encoder
`define   tenv_usb_decoder  tenv_usbhost.tenv_usb_decoder

//MODULE INCLUDING
`include  "tenv_usbhost/tenv_usb_decoder.v"
`include  "tenv_usbhost/tenv_usb_encoder.v"

module tenv_usbhost   #(parameter PACKET_MAXSIZE=64,
                        parameter DATA_MAXSIZE=64);
  //IFACE
  wire                dp, dn;
  real                bit_time=10;
  reg                 speed=1;
  reg signed[31:0]    jitter=0;
  reg signed[31:0]    jitter_sync1=0;
  reg signed[31:0]    jitter_sync2=0;
  reg signed[31:0]    jitter_lastbit=0;
  reg                 sync_corrupt=0;
  reg[7:0]            err_pid=0;
  reg[15:0]           err_crc=0;
  reg                 err_bitstuff;
  reg[7:0]            buffer[DATA_MAXSIZE-1:0];
  reg[6:0]            dev_addr=0;
  reg[15:0]           toggle_bit=0;
  //TRANSACTION MODES
  localparam          HSK_ACK=0,//IN_TRANSACTION: HOST WAITS DATA THEN 
                                //SENDS ACK HANDSHAKE
                                //OUT/SETUP_TRANSACTION: HOST SENDS DATA
                                //THEN WAITS ACK HANDSHAKE
                      
                      HSK_NAK=1,//IN_TRANSACTION: HOST WAITS NAK HANDSHAKE 
                                //INSTEAD DATA
                                //OUT/SETUP_TRANSACTION: HOST SENDS DATA
                                //THEN WAITS NAK HANDSHAKE
                      
                      HSK_STALL=2,//IN_TRANSACTION: HOST WAITS STALL 
                                  //HANDSHAKE INSTEAD DATA
                                  //OUT/SETUP_TRANSACTION: HOST SENDS DATA
                                  //THEN WAITS STALL HANDSHAKE
                                  
                      HSK_NO=3,//IN_TRANSACTION: HOST WAITS DATA THEN 
                               //DOESN'T SEND HANDSHAKE IT IS USED
                               //BY ISOCHRONOUS TRANSFERS
                               //OUT/SETUP_TRANSACTION: HOST SENDS DATA
                               //THEN DOESN'T WAIT HANDSHAKE IT IS USED
                               //BY ISOCHRONOUS TRANSFERS
                                
                      HSK_ERR=4,//IN_TRANSACTION: HOST WAITS DATA THEN 
                                //DOESN'T SEND HANDSHAKE AND MAKES SILENT 
                                //FOR 16 BIT TIMES
                                //OUT/SETUP_TRANSACTION: HOST SENDS DATA 
                                //THEN CHECKS THAT DEVICE DOESN'T SENDS 
                                //HANDSHAKE FOR 18 BIT TIMES
                                
                      DATA_ERR=5;//IN_TRANSACTION: HOST SENDS TOKEN THEN 
                                 //CHECKS THAT DEVICE DOESN'T SEND 
                                 //ANYTHING FOR 18 BIT TIMES
  //STANDARD REQUESTS MODES
  localparam          REQ_OK=0,
  
                      REQ_SETUPERR=1,//ON SETUP STAGE HOST DOESN'T WAIT 
                                //HANDSHAKE AND SKIPS DATA, STATUS STAGES
                      
                      REQ_STATSTALL=2;//ON STATUS STAGE HOST RECEIVES 
                                      //STALL HANDSHAKE

  //LOCALS
  localparam          block_name="tenv_usbhost";
  reg[7:0]            bm_request_type=0;
  reg[7:0]            b_request=0;
  reg[15:0]           w_value=0;
  reg[15:0]           w_index=0;
  reg[15:0]           w_length=0;
  localparam          GET_STATUS=8'd0,
                      CLEAR_FEATURE=8'd1,
                      SET_FEATURE=8'd3,
                      SET_ADDRESS=8'd5,
                      GET_DESCRIPTOR=8'd6,
                      SET_DESCRIPTOR=8'd7,
                      GET_CONFIGURATION=8'd8,
                      SET_CONFIGURATION=8'd9,
                      GET_INTERFACE=8'd10,
                      SET_INTERFACE=8'd11,
                      SYNCH_FRAME=8'd12;

  //TASKS
  `include "tenv_usbhost/tenv_usbhost.usb_reset.v"
  `include "tenv_usbhost/tenv_usbhost.wakeup_detect.v"
  `include "tenv_usbhost/tenv_usbhost.gen_data.v"
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

  //ENCODER
  always @* `tenv_usb_encoder.jitter=jitter;
  always @* `tenv_usb_encoder.jitter_sync1=jitter_sync1;
  always @* `tenv_usb_encoder.jitter_sync2=jitter_sync2;
  always @* `tenv_usb_encoder.jitter_lastbit=jitter_lastbit;
  always @* `tenv_usb_encoder.sync_corrupt=sync_corrupt;
  always @* `tenv_usb_encoder.err_pid=err_pid;
  always @* `tenv_usb_encoder.err_crc=err_crc;
  always @* `tenv_usb_encoder.err_bitstuff=err_bitstuff;
  always @* `tenv_usb_encoder.bit_time=bit_time;
  always @* `tenv_usb_encoder.speed=speed;
  tenv_usb_encoder #(.PACKET_MAXSIZE(PACKET_MAXSIZE)) tenv_usb_encoder();

  //DECODER
  always @* `tenv_usb_decoder.bit_time=bit_time;
  always @* `tenv_usb_decoder.speed=speed;
  tenv_usb_decoder #(.PACKET_MAXSIZE(PACKET_MAXSIZE)) tenv_usb_decoder();

  //TRANSCEIVER
  assign dp= `tenv_usb_encoder.doe ? `tenv_usb_encoder.dplus : 1'bz;
  assign dn= `tenv_usb_encoder.doe ? `tenv_usb_encoder.dminus : 1'bz;
  assign `tenv_usb_decoder.dplus=dp;
  assign `tenv_usb_decoder.dminus=dn;

endmodule
