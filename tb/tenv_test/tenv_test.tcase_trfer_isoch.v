
task tcase_trfer_isoch;
  //LOCAL
  localparam    block_name="tenv_test/tcase_trfer_isoch";
  integer       data_size;
  integer       packet_size;
  reg[3:0]      ep;
  integer       i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Isochronous transfers.");
  
  //RESET TOGGLE BIT
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  `tenv_usbdev.ep_isoch=15'b111_1111_1111_1111;
  
  //#1 ISOCH_IN WITH PACKET_SIZE=MAXIMUM RFIFO CAPACITY
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# IsochronousIn with packet_size=maximum.");  
  ep=15;
  data_size=133;
  packet_size=`tenv_usbdev.speed?64:8;
  `tenv_usbdev.gen_data(0,data_size);
  fork
    begin
    `tenv_usbhost.trfer_isoch_in.ep=ep;
    `tenv_usbhost.trfer_isoch_in.data_size=data_size;
    `tenv_usbhost.trfer_isoch_in.packet_size=packet_size;
    `tenv_usbhost.trfer_isoch_in;
    end
    
    begin
    `tenv_usbdev.trfer_in.ep=ep;
    `tenv_usbdev.trfer_in.data_size=data_size;
    `tenv_usbdev.trfer_in.packet_size=packet_size;
    `tenv_usbdev.trfer_in;
    end
  join
  `tenv_usbhost.check_data(0,data_size);
  
  //#2 ISOCH_IN WITH PACKET_SIZE<MAXIMUM RFIFO CAPACITY
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# IsochronousIn with packet_size<maximum.");
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  `tenv_usbdev.ep_isoch=15'b000_0000_0000_0001;
  repeat(15)
    begin
    packet_size=`tenv_usbdev.speed ? $dist_uniform(seed,1,11) : 
                $dist_uniform(seed,1,7);
    data_size=packet_size*3;
    ep=1;
    repeat(15)
      fork
        begin
        if(`tenv_usbdev.ep_isoch[ep]==1)
          begin
          `tenv_usbhost.trfer_isoch_in.ep=ep;
          `tenv_usbhost.trfer_isoch_in.data_size=data_size;
          `tenv_usbhost.trfer_isoch_in.packet_size=packet_size;
          `tenv_usbhost.trfer_isoch_in;
          `tenv_usbhost.check_data(0,data_size);
          end
        else
          begin
          `tenv_usbhost.trfer_bulk_in.ep=ep;
          `tenv_usbhost.trfer_bulk_in.data_size=data_size;
          `tenv_usbhost.trfer_bulk_in.packet_size=packet_size;
          `tenv_usbhost.trfer_bulk_in;
          `tenv_usbhost.check_data(0,data_size);
          end
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
    @(posedge `tenv_clock.x4);
    `tenv_usbhost.toggle_bit=0;
    `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
    `tenv_usbdev.ep_isoch=`tenv_usbdev.ep_isoch<<1;
    end
  `tenv_usbdev.ep_isoch=15'b111_1111_1111_1111;
  
  //#3 ISOCH_OUT WITH PACKET_SIZE=MAXIMUM TFIFO CAPACITY
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# IsochronousOut with packet_size=maximum.");
  ep=15;
  data_size=134;
  packet_size=`tenv_usbdev.speed?64:8;
  `tenv_usbhost.gen_data(0,data_size);
  fork
    begin
    `tenv_usbhost.trfer_isoch_out.ep=ep;
    `tenv_usbhost.trfer_isoch_out.data_size=data_size;
    `tenv_usbhost.trfer_isoch_out.packet_size=packet_size;
    `tenv_usbhost.trfer_isoch_out;
    end
    
    begin
    `tenv_usbdev.trfer_out.ep=ep;
    `tenv_usbdev.trfer_out.data_size=data_size;
    `tenv_usbdev.trfer_out.packet_size=packet_size;
    `tenv_usbdev.trfer_out;
    end
  join
  `tenv_usbdev.check_data(0,data_size);
  
  //#4 ISOCH_OUT WITH PACKET_SIZE<MAXIMUM TFIFO CAPACITY
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# IsochronousOut with packet_size<maximum.");  
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  `tenv_usbdev.ep_isoch=15'b000_0000_0000_0001;

  repeat(15)
    begin
    packet_size=`tenv_usbdev.speed ? $dist_uniform(seed,1,11) : 
                $dist_uniform(seed,1,7);
    data_size=packet_size*3;
    ep=1;
    repeat(15)
      fork
        begin
        if(`tenv_usbdev.ep_isoch[ep]==1)
          begin
          `tenv_usbhost.gen_data(0,data_size);
          `tenv_usbhost.trfer_isoch_out.ep=ep;
          `tenv_usbhost.trfer_isoch_out.data_size=data_size;
          `tenv_usbhost.trfer_isoch_out.packet_size=packet_size;
          `tenv_usbhost.trfer_isoch_out;
          end
        else
          begin
          `tenv_usbhost.gen_data(0,data_size);
          `tenv_usbhost.trfer_bulk_out.ep=ep;
          `tenv_usbhost.trfer_bulk_out.data_size=data_size;
          `tenv_usbhost.trfer_bulk_out.packet_size=packet_size;
          `tenv_usbhost.trfer_bulk_out;
          end
        ep=ep+1;
        end
        
        begin
        `tenv_usbdev.trfer_out.ep=ep;
        `tenv_usbdev.trfer_out.data_size=data_size;
        `tenv_usbdev.trfer_out.packet_size=packet_size;
        `tenv_usbdev.trfer_out;
        `tenv_usbdev.check_data(0,data_size);
        end
      join
    @(posedge `tenv_clock.x4);
    `tenv_usbhost.toggle_bit=0;
    `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
    `tenv_usbdev.ep_isoch=`tenv_usbdev.ep_isoch<<1;
    end
  @(posedge `tenv_clock.x4);
  `tenv_usbhost.toggle_bit=0;
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0000;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  `tenv_usbdev.ep_isoch=15'b000_0000_0000_0000;
    
  
  //#5 CHECKING SOF
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Start of frame.");  
  fork
    begin
    `tenv_usbhost.trsac_sof(11'b101_0101_0101);
    `tenv_usbhost.trsac_sof(11'b010_1010_1010);
    end
    
    begin
    while(!`tenv_usbdev.sof_tick) @(posedge `tenv_clock.x4);
    if(`tenv_usbdev.sof_value!=11'b101_0101_0101)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid sof_value.");
      $finish;
      end
    @(posedge `tenv_clock.x4);  
    if(`tenv_usbdev.sof_tick!=0)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid sof_tick.");
      $finish;
      end  
    
    while(!`tenv_usbdev.sof_tick) @(posedge `tenv_clock.x4);
    if(`tenv_usbdev.sof_value!=11'b010_1010_1010)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid sof_value.");
      $finish;
      end
    @(posedge `tenv_clock.x4);  
    if(`tenv_usbdev.sof_tick!=0)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid sof_tick.");
      $finish;
      end    
    end
  join
  `tenv_usbdev.ep_isoch=15'h0000;
  end
endtask 
