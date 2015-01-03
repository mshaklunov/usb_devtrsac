
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
  reg[7:0]      length;
  integer       status;
  integer       packet_size;
  //LOCAL   
  localparam    block_name="tenv_usbhost/reqstd_getdesc";
  integer       i;
  
  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("GetDescriptor(%0s)",
          type==DEVICE ? "device" :
          type==CONFIG ? "config" :
          "string");
  //CREATE REQUEST
  bm_request_type=8'b0000_0001;
  b_request=8'h06;
  w_value={type,index};//TYPE, INDEX
  w_index=langid;//LANG ID
  w_length=length;//BYTES TO RETURN
  //WRITE BUFFER
  buffer[0]=bm_request_type;
  buffer[1]=b_request;
  {buffer[3],buffer[2]}=w_value;
  {buffer[5],buffer[4]}=w_index;
  {buffer[7],buffer[6]}=w_length;
  //DO TRANSACTIONS
  trfer_control_in.ep=0;
  trfer_control_in.data_size=length;
  trfer_control_in.packet_size=packet_size;
  trfer_control_in.status=status;
  trfer_control_in;
  //CHECK RCV DATA
  if(status==ACK)
    begin
    i=0;
    repeat(length)
      begin
      if(buffer[i]!==`tenv_descstd_device.data_bybyte[i])
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - received invalid descriptor:");
        $display("buffer=%0h vs desc=%0h ",
                buffer[i],`tenv_descstd_device.data_bybyte[i]);
        $finish;
        end
      i=i+1;
      end
    end
  end
endtask
