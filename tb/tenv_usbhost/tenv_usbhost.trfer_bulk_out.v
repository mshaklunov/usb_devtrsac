
task trfer_bulk_out;

  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;
  integer     handshake;
  //LOCAL   
  parameter   block_name="tenv_usbhost/trfer_bulk_out";
  integer     i;
  
//FUNCTION
  begin

  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkOut(ep=%0d)",ep);
  
  //TRANSMIT
  i=0;
  if(data_size!==0)
    begin
    repeat((data_size/packet_size)+1)
      begin
      trsac_out.ep=ep;
      trsac_out.data_size=(data_size-i)<=packet_size ? data_size-i : 
                          packet_size;
      trsac_out.buffer_ptr=i;
      trsac_out.handshake=ACK;
      trsac_out;
      toggle_bit[ep]=~toggle_bit[ep];
      i=i+trsac_out.data_size;
      end
    end
  end
endtask
