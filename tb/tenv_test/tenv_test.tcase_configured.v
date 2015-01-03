
task tcase_configured;
  //LOCAL
  localparam    block_name="tenv_test/tcase_configured";
  integer       i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Configured state.");  

  //SET CONFIGURATION
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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.CONFIGURED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //EP0 SHOULD REPLY AT GET DESCRIPTOR
  fork
    begin//HOST
    `tenv_usbhost.reqstd_getdesc.type=`tenv_usbhost.reqstd_getdesc.DEVICE;
    `tenv_usbhost.reqstd_getdesc.index=0;
    `tenv_usbhost.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.length=$dist_uniform(seed,1,18);
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbhost.reqstd_getdesc.status=`tenv_usbhost.ACK;
    `tenv_usbhost.reqstd_getdesc;
    end
  
    begin//DEVICE
    `tenv_usbdev.reqstd_getdesc.type=`tenv_usbdev.reqstd_getdesc.DEVICE;
    `tenv_usbdev.reqstd_getdesc.index=0;
    `tenv_usbdev.reqstd_getdesc.langid=0;
    `tenv_usbdev.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;    
    `tenv_usbdev.reqstd_getdesc;
    end
  join

  //CHECKING THAT EP1-15 IS AVAILABLE
  i=1;
  repeat(15)
    fork
    begin//HOST
    `tenv_usbhost.trfer_bulk_in.ep=i;
    `tenv_usbhost.trfer_bulk_in.data_size=1;
    `tenv_usbhost.trfer_bulk_in.packet_size=1;
    `tenv_usbhost.trfer_bulk_in;
    `tenv_usbhost.check_data(0,1);
    i=i+1;
    end
    
    begin//DEVICE
    `tenv_usbdev.gen_data(0,1);
    `tenv_usbdev.trfer_in.ep=i;
    `tenv_usbdev.trfer_in.data_size=1;
    `tenv_usbdev.trfer_in.packet_size=1;
    `tenv_usbdev.trfer_in;
    end
    join
      
  //FROM CONFIGURED TO ADDRESSED WITH SetConfiguration(0)
  fork
    begin
    `tenv_usbhost.reqstd_setconf.conf_value=0;
    `tenv_usbhost.reqstd_setconf.status=`tenv_usbhost.ACK;
    `tenv_usbhost.reqstd_setconf;
    `tenv_usbhost.toggle_bit=0;
    end
    
    begin
    `tenv_usbdev.reqstd_setconf.conf_value=0;
    `tenv_usbdev.reqstd_setconf.status=`tenv_usbhost.ACK;
    `tenv_usbdev.reqstd_setconf;
    end
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //BACK
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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.CONFIGURED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
    
  //FROM CONFIGURED TO DEFAULT WITH USB RESET
  `tenv_usb_encoder.mode=`tenv_usb_encoder.USB_RESET;
  `tenv_usb_encoder.start=1;
  wait(`tenv_usb_encoder.start==0);
  repeat(10) @(posedge `tenv_clock.x4);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state. Code5.");
    $finish;
    end
  `tenv_usbhost.dev_addr=0;

  //BACK
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
  `tenv_usbhost.reqstd_setaddr;

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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.CONFIGURED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  
  end
endtask
