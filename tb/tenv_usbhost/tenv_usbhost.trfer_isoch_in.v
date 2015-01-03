
task trfer_isoch_in;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;  
  //LOCAL   
  parameter   block_name="tenv_usbhost/trfer_isoch_in";
  integer     i;

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("IsochronousIn(ep=%0d)",ep);

  //RCV
  i=0;
  toggle_bit[ep]=0;
  if(data_size!==0)
    repeat((data_size/packet_size)+1)
      begin
      trsac_in.ep=ep;
      trsac_in.data_size=(data_size-i)<=packet_size ? data_size-i : 
                         packet_size;
      trsac_in.buffer_ptr=i;
      trsac_in.handshake=NOREPLY;
      trsac_in;
      i=i+trsac_in.data_size;
      end
  end
endtask
