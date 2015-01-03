
task reqstd_setaddr;
  //IFACE
  reg[7:0]    dev_addr_new;
  //LOCAL   
  parameter   block_name="tenv_usbhost/reqstd_setaddr";
  integer     i;

  begin
  bm_request_type=8'b0000_0000;
  b_request=8'h05;
  w_value={8'd0,dev_addr_new};
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
  $display("SetAddress(%0d)",dev_addr_new);
  trfer_control_out.ep=0;
  trfer_control_out.data_size=0;
  trfer_control_out.packet_size=64;
  trfer_control_out.status=ACK;
  trfer_control_out;
  
  dev_addr= dev_addr_new;
  end
endtask
