
task tcase_addressed;
  //LOCAL
  localparam    block_name="tenv_test/tcase_addressed";
  integer       i;

  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Addressed state.");
  //#1 SET ADDRESS
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Set USB device address.");
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
  `tenv_usbhost.reqstd_setaddr.mode=`tenv_usbhost.REQ_OK;
  `tenv_usbdev.reqstd_setaddr.dev_addr_new=
                                `tenv_usbhost.reqstd_setaddr.dev_addr_new;
  `tenv_usbdev.reqstd_setaddr.status=`tenv_usbdev.ACK;
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

  //#2 NEW ADDR, EP0 SHOULD REPLY AT GET DESCRIPTOR
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep0 is available at the new address.");
  fork
    begin//HOST
    `tenv_usbhost.reqstd_getdesc.type=`tenv_usbhost.reqstd_getdesc.DEVICE;
    `tenv_usbhost.reqstd_getdesc.index=0;
    `tenv_usbhost.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.length=$dist_uniform(seed,1,18);
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbhost.reqstd_getdesc.mode=`tenv_usbhost.REQ_OK;
    `tenv_usbhost.reqstd_getdesc;
    check_descdev(0,`tenv_usbhost.reqstd_getdesc.length);
    end

    begin//DEVICE
    `tenv_usbdev.reqstd_getdesc.type=`tenv_usbdev.reqstd_getdesc.DEVICE;
    `tenv_usbdev.reqstd_getdesc.index=0;
    `tenv_usbdev.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbdev.reqstd_getdesc;
    end
  join

  //#3 NEW ADDR, CHECKING THAT EP15-1 ARE UNAVAILABLE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep15-1 is unavailable at the new address.");
  i=1;
  repeat(15)
    fork

    begin//HOST
    `tenv_usbhost.gen_data(0,1);
    `tenv_usbhost.trsac_out.ep=i;
    `tenv_usbhost.trsac_out.pack_size=1;
    `tenv_usbhost.trsac_out.buffer_ptr=0;
    `tenv_usbhost.trsac_out.mode=`tenv_usbhost.HSK_ERR;
    `tenv_usbhost.trsac_out;
    i=i+1;
    disable `tenv_usbdev.mntr_devstate;
    disable `tenv_usbdev.mntr_trsac_off;
    end

    `tenv_usbdev.mntr_devstate(`tenv_usbdev.ADDRESSED);
    `tenv_usbdev.mntr_trsac_off;
    join

  //#4 CHECKING THAT EP0 IS UNAVAILABLE AT OLD ADDRESS
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep0 is unavailable at the old address.");
  `tenv_usbhost.dev_addr=0;
  fork
    begin//HOST
    `tenv_usbhost.reqstd_getdesc.type=`tenv_usbhost.reqstd_getdesc.DEVICE;
    `tenv_usbhost.reqstd_getdesc.index=0;
    `tenv_usbhost.reqstd_getdesc.langid=0;
    `tenv_usbhost.reqstd_getdesc.length=$dist_uniform(seed,1,18);
    `tenv_usbhost.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbhost.reqstd_getdesc.mode=`tenv_usbhost.REQ_SETUPERR;
    `tenv_usbhost.reqstd_getdesc;
    disable `tenv_usbdev.mntr_devstate;
    disable `tenv_usbdev.mntr_trsac_off;
    end

    `tenv_usbdev.mntr_devstate(`tenv_usbdev.ADDRESSED);
    `tenv_usbdev.mntr_trsac_off;
  join
  `tenv_usbhost.dev_addr=`tenv_usbhost.reqstd_setaddr.dev_addr_new;

  //#5 FROM ADDRESSED TO DEFAULT WITH SetAddress(0)
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Go to DEFAULT with SetAddress(0).");
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=0;
  `tenv_usbhost.reqstd_setaddr.mode=`tenv_usbhost.REQ_OK;
  `tenv_usbdev.reqstd_setaddr.dev_addr_new=
                                `tenv_usbhost.reqstd_setaddr.dev_addr_new;
  fork
    `tenv_usbhost.reqstd_setaddr;
    `tenv_usbdev.reqstd_setaddr;
  join
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state");
    $finish;
    end

  //BACK TO ADDRESSED
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
    $display("Error - invalid device_state. Code4.");
    $finish;
    end

  //#6 FROM ADDRESSED TO DEFAULT WITH USB RESET
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Go to DEFAULT with USB reset.");
  `tenv_usbhost.usb_reset;
  repeat(10) @(posedge `tenv_clock.x4);
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid device_state.");
    $finish;
    end
  `tenv_usbhost.dev_addr=0;

  //BACK TO ADDRESSED
  `tenv_usbhost.reqstd_setaddr.dev_addr_new=$dist_uniform(seed,1,127);
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
  end
endtask
