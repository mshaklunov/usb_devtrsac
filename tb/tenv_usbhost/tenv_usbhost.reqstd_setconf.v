
task reqstd_setconf;
  //IFACE
  reg[7:0]    conf_value;
  integer     status;
  //LOCAL   
  parameter   block_name="tenv_usbhost/reqstd_setconf";
  integer     i;

  begin
  bm_request_type=8'b0000_0000;
  b_request=8'h09;
  w_value={8'd0,conf_value};
  w_index=0;
  w_length=0;
  
  i=0;
  repeat(8)
    begin
    buffer[i/8][i%8]=bm_request_type[i%8];
    i=i+1;
    end
  repeat(8)
    begin
    buffer[i/8][i%8]=b_request[i%8];
    i=i+1;
    end
  repeat(16)
    begin  
    buffer[i/8][i%8]=w_value[i%16];
    i=i+1;
    end
  repeat(16)
    begin
    buffer[i/8][i%8]=w_index[i%16];
    i=i+1;
    end
  repeat(16)
    begin
    buffer[i/8][i%8]=w_length[i%16];
    i=i+1;
    end
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("SetConfiguration(%0d)",conf_value);
  trfer_control_out.ep=0;
  trfer_control_out.data_size=0;
  trfer_control_out.packet_size=64;
  trfer_control_out.status=status;
  trfer_control_out;
  end
endtask
