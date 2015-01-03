
task tcase_powered;
  //LOCAL
  parameter   block_name = "tenv_test/tcase_powered";
  integer     i;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Powered state.");
  
  //RESET DEVICE
  `tenv_usbdev.reset(`tenv_usbdev.speed);
  `tenv_usbhost.dev_addr=0;
  
  //CHECKING THAT EP0 IS UNAVAILABLE
  fork:fork1
    begin//HOST
    `tenv_usbhost.reqstd_getdesc.type=`tenv_usbhost.reqstd_getdesc.DEVICE;
    `tenv_usbhost.reqstd_getdesc.index=0;
    `tenv_usbhost.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.length=$dist_uniform(seed,1,18);
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbhost.reqstd_getdesc.status=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.reqstd_getdesc;
    disable fork1;
    end
    
    begin//CHECK DEVICE STATE
    if(`tenv_usbdev.device_state!=`tenv_usbdev.POWERED)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state.");
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

  //CHECKING THAT EP15-1 ARE UNAVAILABLE
  i=1;
  repeat(15)
    fork:fork2
    
    begin//HOST
    `tenv_usbhost.gen_data(0,1);
    `tenv_usbhost.trsac_out.ep=i;
    `tenv_usbhost.trsac_out.data_size=1;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.NOREPLY;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable fork2;
    end
    
    begin//CHECK DEVICE STATE
    if(`tenv_usbdev.device_state!=`tenv_usbdev.POWERED)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state.");
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
  end
endtask 
