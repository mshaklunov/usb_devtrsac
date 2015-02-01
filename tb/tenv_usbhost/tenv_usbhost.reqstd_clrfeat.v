
task reqstd_clrfeat;
  //IFACE
  integer       type;
  localparam    DEVICE=0,
                INTERFACE=1,
                ENDPOINT=2;
  integer       feature;
  localparam    EP_HALT=0,
                REMOTE_WAKEUP=1;
  reg[3:0]      ep;
  reg           ep_dir;
  reg[7:0]      iface;
  integer       mode;
  //LOCAL
  localparam    block_name="tenv_usbhost/reqstd_clrfeat";

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  if(feature==EP_HALT)
    $display("ClearFeature(ENDPOINT_HALT)");
  else
    $display("ClearFeature(REMOTE_WAKEUP)");
  //CREATE REQUEST
  bm_request_type=  type==DEVICE ? 8'b0000_0000 :
                    type==INTERFACE ? 8'b0000_0001 :
                    8'b0000_0010;
  b_request=CLEAR_FEATURE;
  w_value=feature[15:0];
  w_index=  type==DEVICE ? 16'd0 :
            type==INTERFACE ? {8'd0,iface} :
            {8'd0,ep_dir,3'd0,ep};
  w_length=0;
  //WRITE BUFFER
  buffer[0]=bm_request_type;
  buffer[1]=b_request;
  {buffer[3],buffer[2]}=w_value;
  {buffer[5],buffer[4]}=w_index;
  {buffer[7],buffer[6]}=w_length;
  //DO TRANSACTIONS
  trfer_control_out.ep=0;
  trfer_control_out.data_size=0;
  trfer_control_out.packet_size=64;
  trfer_control_out.mode=mode;
  trfer_control_out;
  end
endtask
