
task trsac_in;

  //IFACE
  reg[3:0]    ep;
  integer     pack_size;
  integer     buffer_ptr;
  integer     mode;
  //LOCAL
  localparam  block_name="tenv_usbhost/trsac_in";
  integer     i;

  begin

  $write("%0t [%0s]: ",$realtime,block_name);
  $display("transaction_in(ep=%0d).",ep);

  //TOKEN
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDIN;
  `tenv_usb_encoder.pack_size=11;
  `tenv_usb_encoder.data[10:0]={ep,dev_addr};
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);

  if(mode==HSK_ACK)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID1.");
      $finish;
      end
    if(`tenv_usb_decoder.pack_size!==pack_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity");
      $finish;
      end
    i=0;
    repeat(`tenv_usb_decoder.pack_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    pack_size=i/8;
    //HSK
    `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
    `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDACK;
    `tenv_usb_encoder.pack_size=0;
    `tenv_usb_encoder.start=1;
    wait(`tenv_usb_encoder.start==0);
    end
  else if(mode==HSK_NAK)
    begin
    //HSK
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(`tenv_usb_decoder.pid!==`tenv_usb_decoder.PIDNAK)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID2.");
      $finish;
      end
    end
  else if(mode==HSK_STALL)
    begin
    //HSK
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(`tenv_usb_decoder.pid!==`tenv_usb_decoder.PIDSTALL)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID3.");
      $finish;
      end
    end
  else if(mode==HSK_NO)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID4.");
      $finish;
      end
    if(`tenv_usb_decoder.pack_size!==pack_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity");
      $finish;
      end
    i=0;
    repeat(`tenv_usb_decoder.pack_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    pack_size=i/8;
    end
  else if(mode==DATA_ERR)
    begin
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_NOREPLY;
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_PACKET;
    end
  else if(mode==HSK_ERR)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 &
          `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID5.");
      $finish;
      end
    if(`tenv_usb_decoder.pack_size!==pack_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity");
      $finish;
      end
    i=0;
    repeat(`tenv_usb_decoder.pack_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    pack_size=i/8;
    //HSK: ERROR
    #(bit_time*16);
    end
  end
endtask
