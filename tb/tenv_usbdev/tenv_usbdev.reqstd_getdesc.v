
task reqstd_getdesc;
  //IFACE
  reg[7:0]      type;
  localparam    DEVICE=1,
                CONFIG=2,
                STRING=3,
                INTERFACE=4,//NOT SUPPORTED BY STD REQ
                ENDPOINT=5;//NOT SUPPORTED BY STD REQ
  reg[7:0]      index;
  reg[15:0]     langid;
  integer       packet_size;
  //LOCAL
  localparam    block_name="tenv_usbdev/reqstd_getdesc";
  integer       i;

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
  //DATA STAGE
  if(bm_request_type==8'b1000_0000 &
    b_request==GET_DESCRIPTOR &
    w_value[15:0]=={type,index} &
    w_index[15:0]==langid
    )
    begin
    i=0;
    repeat((w_length<18 ? w_length : 18))
      begin
      buffer[i]=`tenv_descstd_device.data_bybyte[i];
      i=i+1;
      end
    trfer_in.ep=0;
    trfer_in.data_size=(w_length<18 ? w_length : 18);
    trfer_in.packet_size=packet_size;
    trfer_in;
    end
  else
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - Request is not GetDescriptor(Device).");
    $finish;
    end
  //STATUS STAGE
  trsac_out.ep=0;
  trsac_out.pack_size=0;
  trsac_out.buffer_ptr=0;
  trsac_out.handshake=ACK;
  trsac_out;
  end
endtask
