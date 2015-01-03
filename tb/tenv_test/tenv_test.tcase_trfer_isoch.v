
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

  `tenv_usbdev.ep_isoch=15'h7FFF;
  //#1 ISOCH_IN WITH PACKET_SIZE=MAXIMUM RFIFO CAPACITY
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
  ep=15;
  data_size=39;
  packet_size=9;
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

  //#3 ISOCH_OUT WITH PACKET_SIZE=MAXIMUM TFIFO CAPACITY
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
  ep=15;
  data_size=47;
  packet_size=11;
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
  
  //#5 CHECKING SOF
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
