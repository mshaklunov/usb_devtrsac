
task  wakeup_detect;
  begin
  `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_WAKEUP;
  `tenv_usb_decoder.start=1'b1;
  wait(`tenv_usb_decoder.start==1'b0);
  `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_PACKET;
  end
endtask
