
task mntr_trsac_off;
  //LOCAL
  localparam  block_name="tenv_usbdev/mntr_trsac_off";

  begin
  if(trsac_req==REQ_ACTIVE)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid trsac_req.");
    $finish;
    end
  @(trsac_req);
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Error - trsac_req is active.");
  $finish;
  end
endtask
