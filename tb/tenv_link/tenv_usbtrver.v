
module tenv_usbtrver  (
                      input     sync_clk,
                      input     sync_mode,
                      input     speed,
                      input     dinp,
                      input     dinn,
                      input     doe,
                      output    doutp,
                      output    doutn,
                      output    doutdif,
                      inout     usb_dp,
                      inout     usb_dn
                      );

  //SYNCRONIZATION MODE
  reg sync_dp=1'b1;
  reg sync_dn=1'b0;

  always @(sync_clk)
    begin
    sync_dp<=usb_dp;
    sync_dn<=usb_dn;
    end

  //TRANSCEIVER
  assign usb_dp= doe ? dinp : 1'bz;
  assign usb_dn= doe ? dinn : 1'bz;

  assign doutp= !sync_mode ? usb_dp : sync_dp;
  assign doutn= !sync_mode ? usb_dn : sync_dn;
  assign doutdif= usb_dp==1'b0 & usb_dn==1'b1 ? 1'b0 : 1'b1;

  //PULL-UP RESISTOR
  assign (pull1,pull0) usb_dp= speed ? 1'b1 : 1'b0;
  assign (pull1,pull0) usb_dn= speed ? 1'b0 : 1'b1;

endmodule
