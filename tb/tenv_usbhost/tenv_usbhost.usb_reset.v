
task  usb_reset;
  begin
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_RESET;
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);
  dev_addr=0;
  end
endtask
