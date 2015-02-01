
task tcase_powered;
  //LOCAL
  parameter   block_name = "tenv_test/tcase_powered";
  integer     i;

  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Powered state.");

  //#1 GO TO POWERED STATE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Go to POWERED state.");
  `tenv_usbdev.reset(`tenv_usbdev.speed);
  `tenv_usbhost.dev_addr=0;

  //#2 CHECKING THAT EP0 IS UNAVAILABLE
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("# Ep0 is unavailable.");
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

    `tenv_usbdev.mntr_devstate(`tenv_usbdev.POWERED);
    `tenv_usbdev.mntr_trsac_off;
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

    `tenv_usbdev.mntr_devstate(`tenv_usbdev.POWERED);
    `tenv_usbdev.mntr_trsac_off;
    join
  end
endtask
