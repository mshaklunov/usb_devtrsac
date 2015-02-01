
task trsac_sof(input reg[10:0] value);
  //LOCAL
  localparam  block_name="tenv_usbhost/trsac_sof";

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("StartOfFrame=%0d.",value);

  //TOKEN
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDSOF;
  `tenv_usb_encoder.pack_size=11;
  `tenv_usb_encoder.data[10:0]=value;
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);
  end
endtask
