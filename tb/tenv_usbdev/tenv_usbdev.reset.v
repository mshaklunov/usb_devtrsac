
task reset(input mode);
  //LOCAL
  localparam    block_name="tenv_usbdev/reset";

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  if(mode)
    begin
    $display  ("Generate asynchronous reset.");
    rst0_async=0;
    #500;
    rst0_async=1;
    #500;
    end
  else
    begin
    $display("Generate synchronous reset.");
    @(posedge `tenv_clock.x4);
    rst0_sync=0;
    @(posedge `tenv_clock.x4);
    rst0_sync=1;
    @(posedge `tenv_clock.x4);
    end
  end
endtask

