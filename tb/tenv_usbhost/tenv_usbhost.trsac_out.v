
task trsac_out;
  //IFACE
  reg[3:0]      ep;
  integer       pack_size;
  integer       buffer_ptr;
  integer       mode;
  //LOCAL
  localparam    block_name="tenv_usbhost/trsac_out";
  integer       i;

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("transaction_out(ep=%0d).",ep);

  //TOKEN
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDOUT;
  `tenv_usb_encoder.pack_size=11;
  `tenv_usb_encoder.data[10:0]={ep,dev_addr};
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);

  //DATA
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid= toggle_bit[ep]==0 ? `tenv_usb_encoder.PIDDATA0 :
                         `tenv_usb_encoder.PIDDATA1;
  `tenv_usb_encoder.pack_size= pack_size*8;
  i=0;
  repeat(`tenv_usb_encoder.pack_size*8)
    begin
    `tenv_usb_encoder.data[i]=buffer[buffer_ptr+(i/8)][i%8];
    i=i+1;
    end
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);

  //HSK
  if(mode==HSK_ACK)
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
  else if(mode==HSK_NAK)
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
  else if(mode==HSK_STALL)
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
  else if(mode==HSK_NO)
    begin
    end
  else if(mode==HSK_ERR)
    begin
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_NOREPLY;
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_PACKET;
    end
  end
endtask
