
`include "tenv_link/tenv_usbtrver.v"
module tenv_link;
  
  /*
  MODULE REFERENCE
    `tenv_clock
    `dut
    `tenv_usbdev
    `tenv_usbdecoder
    `tenv_usbencoder
  */

  wire dp, dn;

  assign `dut.clk_4xrate=`tenv_clock.x4;
  assign #1 `dut.rst0_async=`tenv_usbdev.rst0_async;
  assign #1 `dut.rst0_sync=`tenv_usbdev.rst0_sync;
  
  assign #1 `tenv_usbdev.trsac_req= `dut.trsac_req;
  assign #1 `tenv_usbdev.trsac_ep=`dut.trsac_ep;
  assign #1 `tenv_usbdev.trsac_type=`dut.trsac_type;
  assign #1 `dut.trsac_reply=`tenv_usbdev.trsac_reply;

  assign #1 `dut.rfifo_rd=`tenv_usbdev.rfifo_rd;
  assign #1 `tenv_usbdev.rfifo_empty=`dut.rfifo_empty;
  assign #1 `tenv_usbdev.rfifo_rdata=`dut.rfifo_rdata;
  
  assign #1 `dut.tfifo_wr=`tenv_usbdev.tfifo_wr;
  assign #1 `tenv_usbdev.tfifo_full=`dut.tfifo_full;
  assign #1 `dut.tfifo_wdata=`tenv_usbdev.tfifo_wdata;
  
  assign #1 `dut.ep_enable=`tenv_usbdev.ep_enable;
  assign #1 `dut.ep_isoch=`tenv_usbdev.ep_isoch;
  assign #1 `dut.ep_intnoretry=`tenv_usbdev.ep_intnoretry;
  
  assign #1 `dut.device_wakeup=`tenv_usbdev.device_wakeup;
  assign #1 `dut.device_speed=`tenv_usbdev.speed;
  assign #1 `tenv_usbdev.device_state=`dut.device_state;
  
  assign #1 `tenv_usbdev.sof_tick=`dut.sof_tick;
  assign #1 `tenv_usbdev.sof_value=`dut.sof_value;
  
  //USB
  tenv_usbtrver i_duttrver  (  
                            .sync_clk(`tenv_clock.x4),
                            .sync_mode(1'b0),
                           
                            .dinp(`dut.dtx_plus),
                            .dinn(`dut.dtx_minus),
                            .doe(`dut.dtx_oe),
                            .doutp(`dut.drx_plus),
                            .doutn(`dut.drx_minus),
                            .doutdif(`dut.drx),
                          
                            .usb_dp(dp),
                            .usb_dn(dn)
                            );

  tenv_usbtrver i_tenvtrver ( 
                            .sync_clk(1'b0),
                            .sync_mode(1'b0),

                            .dinp(`tenv_usb_encoder.dplus),
                            .dinn(`tenv_usb_encoder.dminus),
                            .doe(`tenv_usb_encoder.doe),
                            .doutp(`tenv_usb_decoder.dplus),
                            .doutn(`tenv_usb_decoder.dminus),
                            .doutdif(),
                          
                            .usb_dp(dp),
                            .usb_dn(dn)
                            );
                              
  assign (pull1,pull0) dp= `tenv_usbdev.speed ? 1'b1 : 1'b0;
  assign (pull1,pull0) dn= `tenv_usbdev.speed ? 1'b0 : 1'b1;    

endmodule 
