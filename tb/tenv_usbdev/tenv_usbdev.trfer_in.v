
task trfer_in;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;
  integer     handshake;
  //LOCAL
  parameter   block_name="tenv_usbdev/trfer_in";
  integer     i;

  begin
  //TRANSMIT
  i=0;
  if(data_size!==0)
    begin
    repeat((data_size/packet_size)+1)
      begin
      trsac_in.ep=ep;
      trsac_in.pack_size=(data_size-i)<=packet_size ? (data_size-i) :
                          packet_size;
      trsac_in.buffer_ptr=i;
      trsac_in.handshake=ACK;
      trsac_in.status=REQ_OK;
      trsac_in;
      i=i+trsac_in.pack_size;
      end
    end
  end
endtask
