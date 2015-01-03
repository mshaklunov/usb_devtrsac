
task trsac_setup;

  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     buffer_ptr;
  integer     handshake;
  //LOCAL   
  parameter   block_name="tenv_usbhost/trsac_setup";
  integer     i;
  
  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("transaction_setup(ep=%0d).",ep);

  //TOKEN 
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDSETUP;
  `tenv_usb_encoder.data_size=11;
  `tenv_usb_encoder.data[10:0]={ep,dev_addr};
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);
  
  //DATA
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=  `tenv_usb_encoder.PIDDATA0;
  `tenv_usb_encoder.data_size= data_size*8;
  i=0;
  repeat(`tenv_usb_encoder.data_size*8)
    begin
    `tenv_usb_encoder.data[i]=buffer[buffer_ptr+(i/8)][i%8];
    i=i+1;
    end
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);

  //HSK
  if(handshake==ACK)
    begin
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(`tenv_usb_decoder.pid!==`tenv_usb_decoder.PIDACK)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    end
  else
  if(handshake==NAK)
    begin
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(`tenv_usb_decoder.pid!==`tenv_usb_decoder.PIDNAK)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    end
  else
  if(handshake==STALL)
    begin
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(`tenv_usb_decoder.pid!==`tenv_usb_decoder.PIDSTALL)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    end
  else
  if(handshake==NOREPLY)
    begin
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_NOREPLY;
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_PACKET;
    end
  end
endtask
