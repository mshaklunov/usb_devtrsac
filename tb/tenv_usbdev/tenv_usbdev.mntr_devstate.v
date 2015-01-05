
task mntr_devstate (input[2:0] etalon);
  //LOCAL
  localparam  block_name="tenv_usbdev/mntr_devstate";

  begin
    if(`tenv_usbdev.device_state!=etalon)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid device_state.");
      $finish;
      end
    @(`tenv_usbdev.device_state);
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - device_state is changed.");
    $finish;
  end
endtask
