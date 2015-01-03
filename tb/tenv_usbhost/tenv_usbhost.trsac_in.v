
task trsac_in;

  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     buffer_ptr;
  integer     handshake;
  //LOCAL   
  localparam  block_name="tenv_usbhost/trsac_in";
  integer     i;
  
  begin

  $write("%0t [%0s]: ",$realtime,block_name);
  $display("transaction_in(ep=%0d).",ep);

  //TOKEN 
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
  `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDIN;
  `tenv_usb_encoder.data_size=11;
  `tenv_usb_encoder.data[10:0]={ep,dev_addr};
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);
  
  if(handshake==ACK)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    if(`tenv_usb_decoder.data_size!==data_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity",i);
      $finish;    
      end
    i=0;
    repeat(`tenv_usb_decoder.data_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    data_size=i/8;
    //HSK
    `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_PACKET;
    `tenv_usb_encoder.pid=`tenv_usb_encoder.PIDACK;
    `tenv_usb_encoder.data_size=0;
    `tenv_usb_encoder.start=1;
    wait(`tenv_usb_encoder.start==0);
    end
  else if(handshake==NAK)
    begin
    //HSK
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
  else if(handshake==STALL)
    begin
    //HSK
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
  else if(handshake==NOREPLY)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    if(`tenv_usb_decoder.data_size!==data_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity",i);
      $finish;    
      end
    i=0;
    repeat(`tenv_usb_decoder.data_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    data_size=i/8;
    end
  else if(handshake==DATAERR)
    begin
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_NOREPLY;
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    `tenv_usb_decoder.mode=`tenv_usb_decoder.MODE_PACKET;
    end
  else if(handshake==HSKERR)
    begin
    //DATA
    `tenv_usb_decoder.start=1;
    wait(`tenv_usb_decoder.start==0);
    if(~( (toggle_bit[ep]==1 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA1) |
          (toggle_bit[ep]==0 & `tenv_usb_decoder.pid==`tenv_usb_decoder.PIDDATA0)) )
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid PID.");
      $finish;
      end
    if(`tenv_usb_decoder.data_size!==data_size*8)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bytes quantity",i);
      $finish;    
      end
    i=0;
    repeat(`tenv_usb_decoder.data_size)
      begin
      buffer[buffer_ptr+(i/8)][i%8]=`tenv_usb_decoder.data[i];
      i=i+1;
      end
    data_size=i/8;
    //HSK: ERROR
    repeat(16*4) @(posedge `tenv_clock.x4);
    end  
  end
endtask
