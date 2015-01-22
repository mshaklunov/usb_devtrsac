
task tcase_configured;
  //LOCAL
  localparam    block_name="tenv_test/tcase_configured";
  integer       i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Configured state.");  

  //#1 SET CONFIGURATION
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Set USB device configuration.");
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

  //#2 EP0 SHOULD REPLY AT GET DESCRIPTOR
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep0 is available.");
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

  //#3 CHECKING THAT EP1-15 IS AVAILABLE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep15-1 is available.");
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.ep_enable=15'b000_0000_0000_0001;
  repeat(15)
    begin
    i=1;
    repeat(15)
      fork
    
      begin//DEVICE
      if(`tenv_usbdev.ep_enable[i]==1)
        begin
        `tenv_usbdev.trsac_out.ep=i;
        `tenv_usbdev.trsac_out.data_size=1;
        `tenv_usbdev.trsac_out.buffer_ptr=0;
        `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
        `tenv_usbdev.trsac_out;
        `tenv_usbdev.check_data(0,1);
        end
      else
        `tenv_usbdev.mntr_trsac_off;
      end
      
      begin//HOST
      `tenv_usbhost.gen_data(0,1);
      `tenv_usbhost.trsac_out.ep=i;
      `tenv_usbhost.trsac_out.data_size=1;
      `tenv_usbhost.trsac_out.buffer_ptr=0;
      `tenv_usbhost.trsac_out.handshake= !`tenv_usbdev.ep_enable[i] ? 
                                         `tenv_usbhost.NOREPLY : 
                                         `tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      if(`tenv_usbdev.ep_enable[i]==0)
        disable `tenv_usbdev.mntr_trsac_off;
      i=i+1;
      end
   
      join
    @(posedge `tenv_clock.x4);  
    `tenv_usbdev.ep_enable=`tenv_usbdev.ep_enable<<1;
    end
  `tenv_usbdev.ep_enable=15'b111_1111_1111_1111;
  
  //#4 FROM CONFIGURED TO ADDRESSED WITH SetConfiguration(0)
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Go to ADDRESSED with SetConfiguration(0).");
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
    
  //#5 FROM CONFIGURED TO DEFAULT WITH USB RESET
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Go to DEFAULT with USB reset.");  
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
  `tenv_usbdev.reqstd_setaddr.dev_addr_new=
                                `tenv_usbhost.reqstd_setaddr.dev_addr_new;
  `tenv_usbdev.reqstd_setaddr.status=`tenv_usbdev.ACK;
  fork
    `tenv_usbhost.reqstd_setaddr;
    `tenv_usbdev.reqstd_setaddr;
  join

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
