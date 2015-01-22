
task tcase_trfer_bulkint;
  //LOCAL
  localparam    block_name="tenv_test/tcase_trfer_bulkint";
  integer       data_size;
  integer       packet_size;
  reg[3:0]      ep;
  integer       i,j;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Bulk/Iterrupt transfers.");

  //SETUP ENDPOINTS
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_isoch=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  
  //#1 BULK_IN WITH VARIOUS PACKET_SIZE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkIn with various packet_size.");
  ep=1;
  data_size=137;
  packet_size=`tenv_usbdev.speed?64:8;
  `tenv_usbdev.gen_data(0,data_size);
  fork
    begin
    `tenv_usbhost.trfer_bulk_in.ep=ep;
    `tenv_usbhost.trfer_bulk_in.data_size=data_size;
    `tenv_usbhost.trfer_bulk_in.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_in;
    end
    
    begin
    `tenv_usbdev.trfer_in.ep=ep;
    `tenv_usbdev.trfer_in.data_size=data_size;
    `tenv_usbdev.trfer_in.packet_size=packet_size;
    `tenv_usbdev.trfer_in;
    end
  join
  `tenv_usbhost.check_data(0,data_size);
  
  //#2 BULK_IN WITH VARIOUS PACKET_SIZE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkIn with various packet_size.");
  ep=1;
  data_size=31;
  packet_size=`tenv_usbdev.speed?9:7;
  `tenv_usbdev.gen_data(0,data_size);
  fork
    begin
    `tenv_usbhost.trfer_bulk_in.ep=ep;
    `tenv_usbhost.trfer_bulk_in.data_size=data_size;
    `tenv_usbhost.trfer_bulk_in.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_in;
    end
    
    begin
    `tenv_usbdev.trfer_in.ep=ep;
    `tenv_usbdev.trfer_in.data_size=data_size;
    `tenv_usbdev.trfer_in.packet_size=packet_size;
    `tenv_usbdev.trfer_in;
    end
  join
  `tenv_usbhost.check_data(0,data_size);
  
  //#3 BULK_IN WITH NAK, TOGGLE BIT RETRY
  ep=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkIn(ep=%0d) with NAK",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=1;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,1);
    i=i+1;

    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=6;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.NAK;
    `tenv_usbhost.trsac_in;
    i=i+6;

    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=1;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,1);
    end
    
    begin
    j=0;
    `tenv_usbdev.gen_data(j,1);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=1;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    j=j+1;
    
    `tenv_usbdev.gen_data(j,6);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=6;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.NAK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    j=j+6;

    `tenv_usbdev.gen_data(j,1);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=1;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    end
  join

  //#4 BULK_IN WITH STALL, TOGGLE BIT RETRY
  ep=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkIn(ep=%0d) with STALL",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=1;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,1);
    i=i+1;

    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=3;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.STALL;
    `tenv_usbhost.trsac_in;
    i=i+3;

    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=1;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,1);
    end
    
    begin
    j=0;
    `tenv_usbdev.gen_data(j,1);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=1;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    j=j+1;

    `tenv_usbdev.gen_data(j,3);    
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=3;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.STALL;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    j=j+3;

    `tenv_usbdev.gen_data(j,1);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=1;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    end
  join

  //#5 BULK_IN HOST DONT REPLY BY HANDSHAKE
  ep=1;
  packet_size=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkIn(ep=%0d) with host don't reply by handshake)",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.HSKERR;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i*packet_size,packet_size);
    
    i=i+1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];  
    `tenv_usbhost.check_data(i*packet_size,packet_size);
    
    i=i+1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i*packet_size,packet_size);
    end
    
    begin
    j=0;
    `tenv_usbdev.gen_data(j*packet_size,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_FAIL;
    `tenv_usbdev.trsac_in;

    j=j+1;
    `tenv_usbdev.gen_data(j*packet_size,packet_size);    
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    
    j=j+1;
    `tenv_usbdev.gen_data(j*packet_size,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
    `tenv_usbdev.trsac_in;
    end
  join
  
  //#6 BULK_OUT WITH VARIOUS PACKET_SIZE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with various packet_size.");
  ep=1;
  data_size=131;
  packet_size=`tenv_usbdev.speed?64:8;
  `tenv_usbhost.gen_data(0,data_size);
  fork
    begin
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
    end
  join
  `tenv_usbdev.check_data(0,data_size);
  
  //#7 BULK_OUT WITH VARIOUS PACKET_SIZE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with various packet_size");  
  ep=1;
  data_size=47;
  packet_size=11;
  `tenv_usbhost.gen_data(0,data_size);  
  fork
    begin
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
    end
  join
  `tenv_usbdev.check_data(0,data_size);
  
  //#8 BULK_OUT WITH NAK, TOGGLE BIT RETRY
  ep=1;
  packet_size=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut(ep=%0d) with NAK",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];

    //NAK
    i=i+1;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.NAK;
    `tenv_usbhost.trsac_out;
    
    i=i+1;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    end
    
    begin
    j=0;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    
    //NAK
    j=j+1;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.NAK;
    `tenv_usbdev.trsac_out;

    j=j+1;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    end
  join

  //#9 BULK_OUT WITH STALL
  ep=1;
  packet_size=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut(ep=%0d) with STALL",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];

    //STALL
    i=i+1;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.STALL;
    `tenv_usbhost.trsac_out;
    
    i=i+1;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    end
    
    begin
    j=0;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    
    //STALL
    j=j+1;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.STALL;
    `tenv_usbdev.trsac_out;

    j=j+1;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    end
  join

  //#10 BULK_OUT WITH SAME DATA PID
  //DUT MUST REPLY WITH ACK BUT DROP PACKET
  ep=1;
  packet_size=1;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut(ep=%0d) with same DATA PID",ep);  
  fork
    begin
    i=0;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;

    //DATA PID SAME AS PREVIOUS
    i=i+1;
    fork
      begin
      `tenv_usbhost.gen_data(i*packet_size,packet_size);
      `tenv_usbhost.trsac_out.ep=ep;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      disable `tenv_usbdev.mntr_trsac_off;
      end
      `tenv_usbdev.mntr_trsac_off;
    join

    //DATA PID SAME AS PREVIOUS
    i=i+1;
    fork
      begin
      `tenv_usbhost.gen_data(i*packet_size,packet_size);
      `tenv_usbhost.trsac_out.ep=ep;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      disable `tenv_usbdev.mntr_trsac_off;
      end
      `tenv_usbdev.mntr_trsac_off;
    join
    
    i=i+1;
    `tenv_usbhost.gen_data(i*packet_size,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    end
    
    begin
    j=0;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    
    //TRANSACTION PASS BECAUSE OF SAME PID
    j=j+1;
    //TRANSACTION PASS BECAUSE OF SAME PID
    j=j+1;
    
    j=j+1;
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j*packet_size,packet_size);
    end
  join  
  
  //#11 INTERRUPT_IN WITH ALWAYS TOGGLE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# InterruptIn with always toggle");
  
  //RESET TOGGLE BIT
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0001;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  
  repeat(15)
    begin
    ep=4'd1;
    packet_size=1;
    repeat(15)
      fork
        begin
        i=0;
        `tenv_usbhost.trsac_in.ep=ep;
        `tenv_usbhost.trsac_in.data_size=packet_size;
        `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
        `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
        `tenv_usbhost.trsac_in;
        `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];//0
        `tenv_usbhost.check_data(i*packet_size,packet_size);
        
        //HOST DON'T SEND ACK BUT CHANGE TOGGLE BIT
        //DUT DON'T CARE ABOUT RECEIVING ACK 
        i=i+1;
        `tenv_usbhost.trsac_in.ep=ep;
        `tenv_usbhost.trsac_in.data_size=packet_size;
        `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
        `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.HSKERR;
        `tenv_usbhost.trsac_in;
        if(`tenv_usbdev.ep_intnoretry[ep]==1)
          `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];//1
        `tenv_usbhost.check_data(i*packet_size,packet_size);

        //HOST DON'T SEND ACK BUT CHANGE TOGGLE BIT
        //DUT DON'T CARE ABOUT RECEIVING ACK    
        i=i+1;
        `tenv_usbhost.trsac_in.ep=ep;
        `tenv_usbhost.trsac_in.data_size=packet_size;
        `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
        `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.HSKERR;
        `tenv_usbhost.trsac_in;
        if(`tenv_usbdev.ep_intnoretry[ep]==1)
          `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];//0
        `tenv_usbhost.check_data(i*packet_size,packet_size);
        
        i=i+1;
        `tenv_usbhost.trsac_in.ep=ep;
        `tenv_usbhost.trsac_in.data_size=packet_size;
        `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
        `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
        `tenv_usbhost.trsac_in;
        `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];//1
        `tenv_usbhost.check_data(i*packet_size,packet_size);
        ep=ep+1;
        end
        
        begin
        j=0;
        `tenv_usbdev.gen_data(j*packet_size,packet_size);
        `tenv_usbdev.trsac_in.ep=ep;
        `tenv_usbdev.trsac_in.data_size=packet_size;
        `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
        `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
        `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
        `tenv_usbdev.trsac_in;

        j=j+1;
        `tenv_usbdev.gen_data(j*packet_size,packet_size);
        `tenv_usbdev.trsac_in.ep=ep;
        `tenv_usbdev.trsac_in.data_size=packet_size;
        `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
        `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
        `tenv_usbdev.trsac_in.status=
                    `tenv_usbdev.ep_intnoretry[ep] ? `tenv_usbdev.REQ_OK : 
                    `tenv_usbdev.REQ_FAIL;
        `tenv_usbdev.trsac_in;

        j=j+1;
        `tenv_usbdev.gen_data(j*packet_size,packet_size);
        `tenv_usbdev.trsac_in.ep=ep;
        `tenv_usbdev.trsac_in.data_size=packet_size;
        `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
        `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
        `tenv_usbdev.trsac_in.status=
                    `tenv_usbdev.ep_intnoretry[ep] ? `tenv_usbdev.REQ_OK : 
                    `tenv_usbdev.REQ_FAIL;
        `tenv_usbdev.trsac_in;
        
        j=j+1;
        `tenv_usbdev.gen_data(j*packet_size,packet_size);
        `tenv_usbdev.trsac_in.ep=ep;
        `tenv_usbdev.trsac_in.data_size=packet_size;
        `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
        `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
        `tenv_usbdev.trsac_in.status=`tenv_usbdev.REQ_OK;
        `tenv_usbdev.trsac_in;
        end
      join
    @(posedge `tenv_clock.x4);
    `tenv_usbhost.toggle_bit=0;
    `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
    `tenv_usbdev.ep_intnoretry=`tenv_usbdev.ep_intnoretry<<1;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
    end
  `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
  
  //#12 CHECKING RESET TOGGLE BITS WITH SetConfiguration()
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Reseting toggle bits with SetConfiguration()"); 
  //SET PID DATA1
  ep=5;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_in(ep);
  ep=6;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_out(ep);
  //RESET TO PID DATA0 WITH SetConfiguration()
  i=$dist_uniform(seed,1,255);
  fork
    begin
    `tenv_usbhost.reqstd_setconf.conf_value=i;
    `tenv_usbhost.reqstd_setconf.status=`tenv_usbhost.ACK;
    `tenv_usbhost.reqstd_setconf;
    `tenv_usbhost.toggle_bit=0;
    end
    
    begin
    `tenv_usbdev.reqstd_setconf.conf_value=i;
    `tenv_usbdev.reqstd_setconf.status=`tenv_usbhost.ACK;
    `tenv_usbdev.reqstd_setconf;
    end
  join
  //CHECK PID DATA0
  ep=1;
  trsac_in(ep);  
  //CHECK PID DATA0
  ep=2;
  trsac_out(ep);

  //#13 CHECKING THAT NO RESET TOGGLE BIT WHEN 
  //SetConfiguration() IS UNSUCCESSFULL
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Not resetting toggle bits with failed SetConfiguration()");  
  //SET PID DATA1
  ep=1;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_in(ep);
  ep=2;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_out(ep);
  //SetConfiguration() IS UNSUCCESSFULL
  i=$dist_uniform(seed,1,255);
  fork
    begin
    `tenv_usbhost.reqstd_setconf.conf_value=i;
    `tenv_usbhost.reqstd_setconf.status=`tenv_usbhost.STALL;
    `tenv_usbhost.reqstd_setconf;
    end
    
    begin
    `tenv_usbdev.reqstd_setconf.conf_value=i;
    `tenv_usbdev.reqstd_setconf.status=`tenv_usbhost.STALL;
    `tenv_usbdev.reqstd_setconf;
    end
  join
  //CHECK PID DATA1
  ep=1;
  trsac_in(ep);  
  //CHECK PID DATA1
  ep=2;
  trsac_out(ep);
  
  //#14 CHECKING RESET TOGGLE BITS WITH ClearFeature(EP_HALT)
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Reseting toggle bits with ClearFeature()");    
  //SET PID DATA1
  ep=5;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_in(ep);
  ep=6;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_out(ep);
  //RESET TOGGLE BIT WITH ClearFeature(EP_HALT)
  fork
    begin
    `tenv_usbdev.reqstd_clrfeat.type=
                                  `tenv_usbdev.reqstd_clrfeat.ENDPOINT;
    `tenv_usbdev.reqstd_clrfeat.feature=
                                  `tenv_usbdev.reqstd_clrfeat.EP_HALT;
    `tenv_usbdev.reqstd_clrfeat.ep=5;
    `tenv_usbdev.reqstd_clrfeat.ep_dir=0;
    `tenv_usbdev.reqstd_clrfeat.status=`tenv_usbhost.ACK;
    `tenv_usbdev.reqstd_clrfeat;
    `tenv_usbhost.toggle_bit[5]=0;
    end

    begin
    `tenv_usbhost.reqstd_clrfeat.type=
                                  `tenv_usbhost.reqstd_clrfeat.ENDPOINT;
    `tenv_usbhost.reqstd_clrfeat.feature=
                                  `tenv_usbhost.reqstd_clrfeat.EP_HALT;
    `tenv_usbhost.reqstd_clrfeat.ep=5;
    `tenv_usbhost.reqstd_clrfeat.ep_dir=0;
    `tenv_usbhost.reqstd_clrfeat.status=`tenv_usbhost.ACK;
    `tenv_usbhost.reqstd_clrfeat;
    end
  join
  //CHECK PID DATA0
  ep=5;
  trsac_in(ep);
  //CHECK PID DATA1
  ep=6;
  trsac_out(ep);
  
  //#16 CHECKING RESET TOGGLE BITS WHEN 
  //ClearFeature(EP_HALT) IS UNSUCCESSFULL
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Not resetting toggle bits with failed ClearFeature()");   
  //SET PID DATA1
  ep=5;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_in(ep);
  ep=6;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_out(ep);
  //ClearFeature(EP_HALT) IS UNSUCCESSFULL
  fork
    begin
    `tenv_usbdev.reqstd_clrfeat.type=
                                  `tenv_usbdev.reqstd_clrfeat.ENDPOINT;
    `tenv_usbdev.reqstd_clrfeat.feature=
                                  `tenv_usbdev.reqstd_clrfeat.EP_HALT;
    `tenv_usbdev.reqstd_clrfeat.ep=5;
    `tenv_usbdev.reqstd_clrfeat.ep_dir=0;
    `tenv_usbdev.reqstd_clrfeat.status=`tenv_usbhost.STALL;
    `tenv_usbdev.reqstd_clrfeat;
    end

    begin
    `tenv_usbhost.reqstd_clrfeat.type=
                                  `tenv_usbhost.reqstd_clrfeat.ENDPOINT;
    `tenv_usbhost.reqstd_clrfeat.feature=
                                  `tenv_usbhost.reqstd_clrfeat.EP_HALT;
    `tenv_usbhost.reqstd_clrfeat.ep=5;
    `tenv_usbhost.reqstd_clrfeat.ep_dir=0;
    `tenv_usbhost.reqstd_clrfeat.status=`tenv_usbhost.STALL;
    `tenv_usbhost.reqstd_clrfeat;
    end
  join
  //CHECK PID DATA1
  ep=5;
  trsac_in(ep);
  //CHECK PID DATA1
  ep=6;
  trsac_out(ep);

  //#17 CHECKING RESET TOGGLE BITS WITH ep_enable INPUTS 
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Reseting toggle bits with ep_enable inputs");    
  //SET PID DATA1
  ep=5;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_in(ep);
  ep=6;
  if(`tenv_usbhost.toggle_bit[ep]==0)
    trsac_out(ep);
  //RESET TOGGLE BIT
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable[6]=1'b0;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable[6]=1'b1;
  `tenv_usbhost.toggle_bit[6]=0;
  //CHECK PID DATA1
  ep=5;
  trsac_in(ep);
  //CHECK PID DATA0
  ep=6;
  trsac_out(ep);
  end
endtask 
