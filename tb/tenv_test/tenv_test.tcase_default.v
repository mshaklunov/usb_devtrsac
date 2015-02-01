
task tcase_default;
  //LOCAL
  localparam    block_name="tenv_test/tcase_default";
  integer       i;

  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Default state.");

  //#1 USB RESET
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# USB reset.");
  `tenv_usbhost.usb_reset;
  if(`tenv_usbdev.device_state!=`tenv_usbdev.DEFAULT)
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
    `tenv_usbhost.reqstd_getdesc.mode=`tenv_usbhost.REQ_OK;
    `tenv_usbhost.reqstd_getdesc;
    check_descdev(0,`tenv_usbhost.reqstd_getdesc.length);
    end

    begin//DEVICE
    `tenv_usbdev.reqstd_getdesc.type=`tenv_usbdev.reqstd_getdesc.DEVICE;
    `tenv_usbdev.reqstd_getdesc.index=0;
    `tenv_usbdev.reqstd_getdesc.langid=0;
    `tenv_usbdev.reqstd_getdesc.packet_size=`tenv_usbdev.speed?64:8;
    `tenv_usbdev.reqstd_getdesc;
    end
  join

  //#3 CHECKING THAT EP15-1 ARE UNAVAILABLE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep15-1 is unavailable.");
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

    `tenv_usbdev.mntr_devstate(`tenv_usbdev.DEFAULT);
    `tenv_usbdev.mntr_trsac_off;

    join
  end
endtask
