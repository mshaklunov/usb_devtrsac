
task tcase_reply_delay;
  //LOCAL
  parameter   block_name="tenv_test/tcase_reply_delay";
  integer     data_size;
  integer     packet_size;
  reg[3:0]    ep;
  integer     i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Maximum reply delay.");
  `tenv_usbdev.reply_delay=35;

  //#1 BULK_IN WITH PACKET_SIZE=MAXIMUM RFIFO CAPACITY
  ep=1;
  data_size=130;
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

  //#2 BULK_OUT WITH PACKET_SIZE=MAXIMUM TFIFO CAPACITY
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
  
  `tenv_usbdev.ep_isoch=15'h7FFF;
  //#3 ISOCH_IN WITH PACKET_SIZE=MAXIMUM RFIFO CAPACITY
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

  //#4 ISOCH_OUT WITH PACKET_SIZE=MAXIMUM TFIFO CAPACITY
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

  `tenv_usbdev.reply_delay=0;  
  `tenv_usbdev.ep_isoch=15'h0000;
  end
endtask 
