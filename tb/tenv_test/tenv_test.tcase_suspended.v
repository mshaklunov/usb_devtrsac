
task tcase_suspended;
  //LOCAL
  localparam    block_name="tenv_test/tcase_suspended";
  integer       i;

  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Suspended state.");

  //#1 POWERED
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# POWERED TO SUSPENDED.");

  //RESET DEVICE
  `tenv_usbdev.reset(~`tenv_usbdev.speed);

  if(`tenv_usbdev.device_state!=`tenv_usbdev.POWERED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  fork:fork_pwr
    begin
    repeat(6100) #1000;//WAIT 6.1 ms
    disable fork_pwr;
    end

    begin//CHECKING THAT NO WAKEUP SIGNALING
   `tenv_usbdev.device_wakeup=1;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.device_wakeup=0;
    @(`tenv_usbhost.dp,`tenv_usbhost.dn);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - bus activity.");
    $finish;
    end
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.SPND_PWR)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  //BACK
  `tenv_usbhost.trsac_sof($random);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.POWERED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //#2 DEFAULT
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# DEFAULT TO SUSPENDED.");
  `tenv_usbhost.usb_reset;
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  fork:fork_dft
    begin
    repeat(6100) #1000;//WAIT 6.1 ms
    disable fork_dft;
    end

    begin//CHECKING THAT NO WAKEUP SIGNALING
   `tenv_usbdev.device_wakeup=1;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.device_wakeup=0;
    @(`tenv_usbhost.dp,`tenv_usbhost.dn);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - bus activity.");
    $finish;
    end
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.SPND_DFT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  //BACK
  `tenv_usbhost.trsac_sof($random);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //#3 ADDRESSED
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# ADDRESSED TO SUSPENDED.");
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
  `tenv_usbhost.reqstd_setaddr.mode=`tenv_usbhost.REQ_OK;
  `tenv_usbdev.reqstd_setaddr.dev_addr_new=
                                `tenv_usbhost.reqstd_setaddr.dev_addr_new;
  fork
    `tenv_usbhost.reqstd_setaddr;
    `tenv_usbdev.reqstd_setaddr;
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  fork:fork_addr
    begin
    repeat(6100) #1000;//WAIT 6.1 ms
    disable fork_addr;
    end

    begin//CHECKING THAT NO WAKEUP SIGNALING
   `tenv_usbdev.device_wakeup=1;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.device_wakeup=0;
    @(`tenv_usbhost.dp,`tenv_usbhost.dn);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - bus activity.");
    $finish;
    end
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.SPND_ADDR)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  //BACK
  `tenv_usbhost.trsac_sof($random);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.ADDRESSED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //#4 CONFIGURATED
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# CONFIGURED TO SUSPENDED.");
  i=$dist_uniform(seed,1,255);
  fork
    begin
    `tenv_usbhost.reqstd_setconf.conf_value=i;
    `tenv_usbhost.reqstd_setconf.mode=`tenv_usbhost.REQ_OK;
    `tenv_usbhost.reqstd_setconf;
    `tenv_usbhost.toggle_bit=0;
    end

    begin
    `tenv_usbdev.reqstd_setconf.conf_value=i;
    `tenv_usbdev.reqstd_setconf.status=`tenv_usbdev.ACK;
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
  fork:fork_conf
    begin
    repeat(6100) #1000;//WAIT 6.1 ms
    disable fork_conf;
    end

    begin//CHECKING THAT NO WAKEUP SIGNALING
   `tenv_usbdev.device_wakeup=1;
    @(posedge `tenv_clock.x4);
    `tenv_usbdev.device_wakeup=0;
    @(`tenv_usbhost.dp,`tenv_usbhost.dn);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - bus activity.");
    $finish;
    end
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.SPND_CONF)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end

  //#5 REMOTE WAKEUP
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# REMOTE WAKEUP.");
  `tenv_usbdev.device_wakeup=1;
  @(posedge `tenv_clock.x4);
  `tenv_usbdev.device_wakeup=0;
  `tenv_usbhost.wakeup_detect;
  if(`tenv_usbdev.device_state!=`tenv_usbdev.SPND_CONF)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state.");
      $finish;
      end

  //BACK TO CONFIGURED
  `tenv_usbhost.trsac_sof($random);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.CONFIGURED)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  end
endtask
