
task trfer_out;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;
  integer     handshake;
  //LOCAL
  parameter   block_name="tenv_usbdev/trfer_out";
  integer     i;

  begin
  //RCV
  i=0;
  if(data_size!==0)
    repeat((data_size/packet_size)+1)
      begin
      trsac_out.ep=ep;
      trsac_out.pack_size=(data_size-i)<=packet_size ? (data_size-i) :
                          packet_size;
      trsac_out.buffer_ptr=i;
      trsac_out.handshake=ACK;
      trsac_out;
      i=i+trsac_out.pack_size;
      end
  end
endtask
