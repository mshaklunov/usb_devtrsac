
task reqstd_setiface;

//DECLARATION
  //IFACE
  reg[7:0]  iface_value;

  //LOCAL
  parameter block_name="tenv_usbhost/reqstd_setiface";
  integer   i;
  
//FUNCTION
  begin
  bm_request_type=8'b0000_0000;
  b_request=8'h09;
  w_value={8'd0,iface_value};
  w_index=0;
  w_length=0;
  
  i=0;
  repeat(8)
    begin
    buffer[i]=bm_request_type[i%8];
    i=i+1;
    end
  repeat(8)
    begin
    buffer[i]=b_request[i%8];
    i=i+1;
    end
  repeat(16)
    begin  
    buffer[i]=w_value[i%16];
    i=i+1;
    end
  repeat(16)
    begin
    buffer[i]=w_index[i%16];
    i=i+1;
    end
  repeat(16)
    begin
    buffer[i]=w_length[i%16];
    i=i+1;
    end
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("SetInterface(%0d)",conf_value);
  trfer_control_out.ep=0;
  trfer_control_out.data_size=0;
  trfer_control_out.packet_size=64;
  trfer_control_out.status=ACK;
  trfer_control_out;
  end
endtask
