
task tcase_bitstream;
  //LOCAL
  localparam    block_name="tenv_test/tcase_bitstream";
  integer       data_size;
  integer       packet_size;
  reg[3:0]      ep;
  integer       i,j,k;

  begin

  //RESET ENDPOINTS
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_isoch=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;

  //#1 CHECKING WITH MAXIMUM POSITIVE JITTER
  `tenv_usbhost.jitter=`tenv_usbdev.speed ? 20 : 141;
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with cosecutive jitter=%0dns.",
          `tenv_usbhost.jitter);
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
    i=i+(`tenv_clock.x4_period/4);
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
    check_data(0,data_size);
    end
    join

  //#2 CHECKING WITH MAXIMUM NEGATIVE JITTER
  `tenv_usbhost.jitter=`tenv_usbdev.speed ? -20 : -141;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with cosecutive jitter=%0dns.",
          `tenv_usbhost.jitter);
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
    i=i+(`tenv_clock.x4_period/4);
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
    check_data(0,data_size);
    end
    join

  //#3 SYNC BITS(1st 2nd) INVALID VALUE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with invalid value 1st, 2nd sync bits.");
  `tenv_usbhost.jitter=4;
  `tenv_usbhost.sync_corrupt=1;
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
    check_data(0,data_size);
    end
  join
  `tenv_usbhost.sync_corrupt=0;

  //#4 SYNC BITS(1st 2nd) INVALID TIMING
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with invalid sync1 timing.");
  `tenv_usbhost.jitter=6;
  //BULK OUT
  ep=1;
  data_size=1;
  packet_size=`tenv_usbdev.speed?64:8;
  k=`tenv_usbdev.speed ? -15 : -120;
  repeat(5)
    begin
    `tenv_usbhost.jitter_sync2=k;
    k=`tenv_usbdev.speed ? k-15 : k-120;
    j=`tenv_usbdev.speed ? -15 : 120;
    repeat(5)
      begin
      `tenv_usbhost.jitter_sync1=j;
      j=`tenv_usbdev.speed ? j-15 : j-120;
      i=0;
      repeat(4)
        fork
        begin
        @(posedge `tenv_clock.x4);
        #i;
        i=i+(`tenv_clock.x4_period/4);
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
        check_data(0,data_size);
        end
        join
      end
    end
  `tenv_usbhost.jitter=0;
  `tenv_usbhost.jitter_sync1=0;
  `tenv_usbhost.jitter_sync2=0;

  //#5 ERROR PID
  ep=1;
  packet_size=1;
  i=0;
  repeat(8)
    fork
    begin
    `tenv_usbhost.err_pid[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# BulkOut with pid bit[%0d] error.",i);
    `tenv_usbhost.gen_data(0,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.pack_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.mode=`tenv_usbhost.HSK_ERR;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable `tenv_usbdev.mntr_trsac_off;
    end

    disable `tenv_usbdev.mntr_trsac_off;
    join
  `tenv_usbhost.err_pid=0;

  //#6 ERROR CRC16
  ep=1;
  packet_size=1;
  i=0;
  repeat(16)
    fork
    begin
    `tenv_usbhost.err_crc[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# BulkOut with crc bit[%0d] error.",i);
    `tenv_usbhost.gen_data(0,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.pack_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.mode=`tenv_usbhost.HSK_ERR;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable `tenv_usbdev.mntr_trsac_off;
    end

    `tenv_usbdev.mntr_trsac_off;
    join
  `tenv_usbhost.err_crc=0;

  //#7 ERROR CRC5
  ep=1;
  packet_size=1;
  i=0;
  repeat(5)
    fork
    begin
    `tenv_usbhost.err_crc[i]=1'b1;
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# BulkIn with crc bit[%0d] error.",i);
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.pack_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=0;
    `tenv_usbhost.trsac_in.mode=`tenv_usbhost.DATA_ERR;
    `tenv_usbhost.trsac_in;
    i=i+1;
    disable `tenv_usbdev.mntr_trsac_off;
    end

    `tenv_usbdev.mntr_trsac_off;
    join
  `tenv_usbhost.err_crc=0;

  //8 LAST BIT STUFF SEND
  ep=1;
  packet_size=2;
  i=0;
  repeat(1)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# BulkIn with with last bit stuff.");
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.pack_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=0;
    `tenv_usbhost.trsac_in.mode=`tenv_usbhost.HSK_ACK;
    `tenv_usbhost.trsac_in;
    check_data(0,2);
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+1;
    end

    begin
    `tenv_usbdev.buffer[1]=8'h38;
    `tenv_usbdev.buffer[0]=8'h02;
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.pack_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=0;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
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
    $display("# BulkOut with with last bit stuff.");
    `tenv_usbdev.buffer[1]=8'h38;
    `tenv_usbdev.buffer[0]=8'h02;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.pack_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.mode=`tenv_usbhost.HSK_ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+1;
    end

    begin
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.pack_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=0;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    check_data(0,2);
    end
    join

  //#10 PACKET WITH LAST DRIBBLE BIT
  `tenv_usbhost.jitter_lastbit=`tenv_usbdev.speed?75:260;
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# BulkOut with last dribble bit=%0dns.",
          `tenv_usbhost.jitter_lastbit);
  //BULK OUT
  ep=1;
  packet_size=`tenv_usbdev.speed?64:8;
  data_size=packet_size*3;
  repeat(15)
    fork
    begin
    @(posedge `tenv_clock.x4);
    `tenv_usbhost.gen_data(0,data_size);
    `tenv_usbhost.trfer_bulk_out.ep=ep;
    `tenv_usbhost.trfer_bulk_out.data_size=data_size;
    `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_out;
    ep=ep+1;
    end

    begin
    `tenv_usbdev.trfer_out.ep=ep;
    `tenv_usbdev.trfer_out.data_size=data_size;
    `tenv_usbdev.trfer_out.packet_size=packet_size;
    `tenv_usbdev.trfer_out;
    check_data(0,data_size);
    end
    join
  ep=1;
  repeat(15)
    fork
    begin
    @(posedge `tenv_clock.x4);
    `tenv_usbhost.trfer_bulk_in.ep=ep;
    `tenv_usbhost.trfer_bulk_in.data_size=data_size;
    `tenv_usbhost.trfer_bulk_in.packet_size=packet_size;
    `tenv_usbhost.trfer_bulk_in;
    check_data(0,data_size);
    ep=ep+1;
    end

    begin
    `tenv_usbdev.gen_data(0,data_size);
    `tenv_usbdev.trfer_in.ep=ep;
    `tenv_usbdev.trfer_in.data_size=data_size;
    `tenv_usbdev.trfer_in.packet_size=packet_size;
    `tenv_usbdev.trfer_in;
    end
    join
  `tenv_usbhost.jitter_lastbit=0;

  end
endtask
