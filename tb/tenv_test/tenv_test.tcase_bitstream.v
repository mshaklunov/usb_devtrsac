
task tcase_bitstream;
  //LOCAL
  localparam    block_name="tenv_test/tcase_bitstream";
  integer       data_size;
  integer       packet_size;
  reg[3:0]      ep;
  integer       i,j,k;
    
  begin
  //#1 CHECKING WITH MAXIMUM POSITIVE JITTER
  `tenv_usb_encoder.jitter=`tenv_usbdev.speed ? 20 : 141;
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkOut with cosecutive jitter=%0dns.",
          `tenv_usb_encoder.jitter);
  //BULK OUT
  ep=1;
  data_size=64;
  packet_size=`tenv_usbdev.speed?64:8;
  i=0;
  repeat(4)
    fork
    begin
    @(posedge `tenv_clock.x4);
    #i;
    i=i+4;
    `tenv_usbhost.gen_data(0,data_size);
    `tenv_usbhost.trfer_bulk_out.ep=ep;
    `tenv_usbhost.trfer_bulk_out.data_size=data_size;
    `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_out;
    end
    
    begin
    `tenv_usbdev.trfer_out.ep=ep;
    `tenv_usbdev.trfer_out.data_size=data_size;
    `tenv_usbdev.trfer_out.packet_size=packet_size;
    `tenv_usbdev.trfer_out;
    `tenv_usbdev.check_data(0,data_size);
    end
    join

  //#2 CHECKING WITH MAXIMUM NEGATIVE JITTER
  `tenv_usb_encoder.jitter=`tenv_usbdev.speed ? -20 : -141;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkOut with cosecutive jitter=%0dns.",
          `tenv_usb_encoder.jitter);
  //BULK OUT
  ep=1;
  data_size=64;
  packet_size=`tenv_usbdev.speed?64:8;
  i=0;
  repeat(4)
    fork
    begin
    @(posedge `tenv_clock.x4);
    #i;
    i=i+4;
    `tenv_usbhost.gen_data(0,data_size);
    `tenv_usbhost.trfer_bulk_out.ep=ep;
    `tenv_usbhost.trfer_bulk_out.data_size=data_size;
    `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_out;
    end
    
    begin
    `tenv_usbdev.trfer_out.ep=ep;
    `tenv_usbdev.trfer_out.data_size=data_size;
    `tenv_usbdev.trfer_out.packet_size=packet_size;
    `tenv_usbdev.trfer_out;
    `tenv_usbdev.check_data(0,data_size);
    end
    join

  //#3 SYNC BITS(1st 2nd) INVALID VALUE    
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkOut with invalid value 1st, 2nd sync bits.");
  `tenv_usb_encoder.jitter=4;
  `tenv_usb_encoder.sync_corrupt=1;
  //BULK OUT
  ep=1;
  data_size=1;
  packet_size=`tenv_usbdev.speed?64:8;
  fork
    begin
    `tenv_usbhost.gen_data(0,data_size);
    `tenv_usbhost.trfer_bulk_out.ep=ep;
    `tenv_usbhost.trfer_bulk_out.data_size=data_size;
    `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_out;
    end
    
    begin
    `tenv_usbdev.trfer_out.ep=ep;
    `tenv_usbdev.trfer_out.data_size=data_size;
    `tenv_usbdev.trfer_out.packet_size=packet_size;
    `tenv_usbdev.trfer_out;
    `tenv_usbdev.check_data(0,data_size); 
    end
  join
  `tenv_usb_encoder.sync_corrupt=0;

  //#4 SYNC BITS(1st 2nd) INVALID TIMING    
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkOut with invalid sync1 timing.");
  `tenv_usb_encoder.jitter=6;
  //BULK OUT
  ep=1;
  data_size=1;
  packet_size=`tenv_usbdev.speed?64:8;
  k=`tenv_usbdev.speed ? -15 : -120;
  repeat(5)
    begin
    `tenv_usb_encoder.jitter_sync2=k;
    k=`tenv_usbdev.speed ? k-15 : k-120;
    j=`tenv_usbdev.speed ? -15 : 120;
    repeat(5)
      begin
      `tenv_usb_encoder.jitter_sync1=j;
      j=`tenv_usbdev.speed ? j-15 : j-120;
      i=0;
      repeat(4)
        fork
        begin
        @(posedge `tenv_clock.x4);
        #i;
        i=i+4;
        `tenv_usbhost.gen_data(0,data_size);
        `tenv_usbhost.trfer_bulk_out.ep=ep;
        `tenv_usbhost.trfer_bulk_out.data_size=data_size;
        `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
        `tenv_usbhost.trfer_bulk_out;
        end
        
        begin
        `tenv_usbdev.trfer_out.ep=ep;
        `tenv_usbdev.trfer_out.data_size=data_size;
        `tenv_usbdev.trfer_out.packet_size=packet_size;
        `tenv_usbdev.trfer_out;
        `tenv_usbdev.check_data(0,data_size);
        end
        join
      end
    end
  `tenv_usb_encoder.jitter=0;
  `tenv_usb_encoder.jitter_sync1=0;
  `tenv_usb_encoder.jitter_sync2=0;
    
  //#5 ERROR PID
  ep=1;
  packet_size=1;
  i=0;
  repeat(8)
    fork
    begin
    `tenv_usb_encoder.err_pid[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("BulkOut with pid bit[%0d] error.",i);
    `tenv_usbhost.gen_data(0,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable err_pid;
    end
    
    begin:err_pid
    if(`tenv_usbdev.trsac_req==`tenv_usbdev.REQ_ACTIVE)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid trsac_req.");
      $finish;
      end
    @(`tenv_usbdev.trsac_req);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - trsac_req is active.");
    $finish;
    end    
    join
  `tenv_usb_encoder.err_pid=0;
    
  //#6 ERROR CRC16
  ep=1;
  packet_size=1;
  i=0;
  repeat(16)
    fork
    begin
    `tenv_usb_encoder.err_crc[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("BulkOut with pid bit[%0d] error.",i);
    `tenv_usbhost.gen_data(0,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable err_crc16;
    end
    
    begin:err_crc16
    if(`tenv_usbdev.trsac_req==`tenv_usbdev.REQ_ACTIVE)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid trsac_req.");
      $finish;
      end
    @(`tenv_usbdev.trsac_req);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - trsac_req is active.");
    $finish;
    end    
    join
  `tenv_usb_encoder.err_crc=0;
    
  //#7 ERROR CRC5
  ep=1;
  packet_size=1;
  i=0;
  repeat(5)
    fork
    begin
    `tenv_usb_encoder.err_crc[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("BulkIn with pid bit[%0d] error.",i);
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=0;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.DATAERR;
    `tenv_usbhost.trsac_in;
    i=i+1;
    disable err_crc5;
    end
    
    begin:err_crc5
    if(`tenv_usbdev.trsac_req==`tenv_usbdev.REQ_ACTIVE)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid trsac_req.");
      $finish;
      end
    @(`tenv_usbdev.trsac_req);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - trsac_req is active.");
    $finish;
    end    
    join
  `tenv_usb_encoder.err_crc=0;

  //8 LAST BIT STUFF SEND
  ep=1;
  packet_size=2;
  i=0;
  repeat(1)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("BulkIn with with last bit stuff.");
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=0;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(0,2);
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+1;
    end
    
    begin
    `tenv_usbdev.buffer[1]=8'h38;
    `tenv_usbdev.buffer[0]=8'h02;
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=0;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbdev.trsac_in;
    end
    join

  //9 LAST BIT STUFF RECEIVE
  ep=1;
  packet_size=2;
  i=0;
  repeat(1)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("BulkOut with with last bit stuff.");
    `tenv_usbdev.buffer[1]=8'h38;
    `tenv_usbdev.buffer[0]=8'h02;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+1;
    end
    
    begin
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=0;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(0,2);
    end    
    join
  end
endtask 
