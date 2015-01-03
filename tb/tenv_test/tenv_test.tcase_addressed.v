
task tcase_addressed;
  //LOCAL
  localparam    block_name="tenv_test/tcase_addressed";
  integer       i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Addressed state.");
  //SET ADDRESS
  fork:fork0
    begin
    `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
    `tenv_usbhost.reqstd_setaddr;
    disable fork0;
    end

    begin//CHECK TRANSACTION INTERFACE
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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state. Code0.");
    $finish;
    end  
  
  //NEW ADDR, EP0 SHOULD REPLY AT GET DESCRIPTOR
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
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;    
    `tenv_usbdev.reqstd_getdesc;
    end
  join

  //NEW ADDR, CHECKING THAT EP15-1 ARE UNAVAILABLE
  i=1;
  repeat(15)
    fork:fork1
    
    begin//HOST
    `tenv_usbhost.gen_data(0,1);
    `tenv_usbhost.trsac_out.ep=i;
    `tenv_usbhost.trsac_out.data_size=1;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable fork1;
    end
    
    begin//CHECK DEVICE STATE
    if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state. Code1.");
      $finish;
      end
    @(`tenv_usbdev.device_state);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - device_state is active.");
    $finish;
    end
    
    begin//CHECK TRANSACTION INTERFACE
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
  
  //CHECKING THAT EP0 IS UNAVAILABLE AT OLD ADDRESS
  `tenv_usbhost.dev_addr=0;
  fork:fork2
    begin//HOST
    `tenv_usbhost.reqstd_getdesc.type=`tenv_usbhost.reqstd_getdesc.DEVICE;
    `tenv_usbhost.reqstd_getdesc.index=0;
    `tenv_usbhost.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.length=$dist_uniform(seed,1,18);
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbhost.reqstd_getdesc.status=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.reqstd_getdesc;
    disable fork2;
    end
    
    begin//CHECK DEVICE STATE
    if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state. Code2.");
      $finish;
      end
    @(`tenv_usbdev.device_state);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - device_state is active.");
    $finish;
    end
    
    begin//CHECK TRANSACTION INTERFACE
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
  `tenv_usbhost.dev_addr=`tenv_usbhost.reqstd_setaddr.dev_addr_new;
    
  //FROM ADDRESSED TO DEFAULT WITH SetAddress(0)
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=0;
  `tenv_usbhost.reqstd_setaddr;
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state. Code3.");
    $finish;
    end
  
  //BACK TO ADDRESSED
  fork:fork3
    begin
    `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
    `tenv_usbhost.reqstd_setaddr;
    disable fork3;
    end
    
    begin//CHECK TRANSACTION INTERFACE
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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state. Code4.");
    $finish;
    end
    
  //FROM ADDRESSED TO DEFAULT WITH USB RESET
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

  //BACK TO ADDRESSED
  fork:fork4
    begin
    `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
    `tenv_usbhost.reqstd_setaddr;
    disable fork4;
    end
    
    begin//CHECK TRANSACTION INTERFACE
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
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  end
endtask 
