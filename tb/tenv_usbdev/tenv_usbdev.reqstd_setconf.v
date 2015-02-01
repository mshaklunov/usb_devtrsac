
task reqstd_setconf;
  //IFACE
  reg[7:0]      conf_value;
  integer       status;
  //LOCAL
  localparam    block_name="tenv_usbdev/reqstd_setconf";
  integer       i;
  reg[15:1]     ep_enable_temp;

  begin
  //SETUP STAGE
  trsac_setup.ep=0;
  trsac_setup.pack_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.handshake=ACK;
  trsac_setup;
  //DECODE REQUEST
  bm_request_type=buffer[0];
  b_request=buffer[1];
  w_value={buffer[3],buffer[2]};
  w_index={buffer[5],buffer[4]};
  w_length={buffer[7],buffer[6]};
  if(!(bm_request_type==8'd0 &
    b_request==SET_CONFIGURATION &
    w_value=={8'd0,conf_value} &
    w_index==0 &
    w_length==0))
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid request SetConfiguration().");
    $finish;
    end
  //STATUS STAGE
  if(status==ACK)
    begin
    trsac_in.ep=0;
    trsac_in.pack_size=0;
    trsac_in.buffer_ptr=0;
    trsac_in.handshake=ACK;
    trsac_in;
    device_config_wr=1'b1;
    device_config=conf_value;
    ep_enable_temp=ep_enable;
    ep_enable=15'h0000;
    @(posedge `tenv_clock.x4);
    device_config_wr=1'b0;
    ep_enable=ep_enable_temp;
    end
  else if(status==STALL)
    begin
    trsac_in.ep=0;
    trsac_in.pack_size=0;
    trsac_in.buffer_ptr=0;
    trsac_in.handshake=STALL;
    trsac_in;
    end
  end
endtask
