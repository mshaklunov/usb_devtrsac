//MODULE REFERENCE
`define   dut                       dut
`define   tenv_clock                tenv_clock
`define   tenv_usbdev               tenv_usbdev
`define   tenv_usbhost              tenv_usbhost

//MODULE INCLUDING
`include "tenv_link/tenv_usbtrver.v"

module tenv_link;

  //CONNECTION WITH DEVICE SPECIFIC LOGIC INTERFACE
  assign    `dut.clk_4xrate=          `tenv_clock.x4;
  assign #1 `dut.rst0_async=          `tenv_usbdev.rst0_async;
  assign #1 `dut.rst0_sync=           `tenv_usbdev.rst0_sync;

  assign #1 `tenv_usbdev.trsac_req=   `dut.trsac_req;
  assign #1 `tenv_usbdev.trsac_ep=    `dut.trsac_ep;
  assign #1 `tenv_usbdev.trsac_type=  `dut.trsac_type;
  assign #1 `dut.trsac_reply=         `tenv_usbdev.trsac_reply;

  assign #1 `dut.rfifo_rd=            `tenv_usbdev.rfifo_rd;
  assign #1 `tenv_usbdev.rfifo_empty= `dut.rfifo_empty;
  assign #1 `tenv_usbdev.rfifo_rdata= `dut.rfifo_rdata;

  assign #1 `dut.tfifo_wr=            `tenv_usbdev.tfifo_wr;
  assign #1 `tenv_usbdev.tfifo_full=  `dut.tfifo_full;
  assign #1 `dut.tfifo_wdata=         `tenv_usbdev.tfifo_wdata;

  assign #1 `dut.ep_enable=           `tenv_usbdev.ep_enable;
  assign #1 `dut.ep_isoch=            `tenv_usbdev.ep_isoch;
  assign #1 `dut.ep_intnoretry=       `tenv_usbdev.ep_intnoretry;

  assign #1 `dut.device_wakeup=       `tenv_usbdev.device_wakeup;
  assign #1 `dut.device_speed=        `tenv_usbdev.speed;
  assign #1 `dut.device_addr_wr=      `tenv_usbdev.device_addr_wr;
  assign #1 `dut.device_addr=         `tenv_usbdev.device_addr;
  assign #1 `dut.device_config_wr=    `tenv_usbdev.device_config_wr;
  assign #1 `dut.device_config=       `tenv_usbdev.device_config;
  assign #1 `tenv_usbdev.device_state=`dut.device_state;

  assign #1 `tenv_usbdev.sof_tick=    `dut.sof_tick;
  assign #1 `tenv_usbdev.sof_value=   `dut.sof_value;

  //CONNECTION WITH USB LINE THROUGH USB TRANSCEIVER
  tenv_usbtrver i_duttrver  (
                            .sync_clk(1'b0),
                            .sync_mode(1'b0),
                            .speed(`tenv_usbdev.speed),

                            .dinp(`dut.dtx_plus),
                            .dinn(`dut.dtx_minus),
                            .doe(`dut.dtx_oe),
                            .doutp(`dut.drx_plus),
                            .doutn(`dut.drx_minus),
                            .doutdif(`dut.drx),

                            .usb_dp(`tenv_usbhost.dp),
                            .usb_dn(`tenv_usbhost.dn)
                            );

endmodule
