
task trfer_bulk_in;
  //IFACE
  reg[3:0]      ep;
  integer       data_size;
  integer       packet_size;
  //LOCAL
  localparam    block_name="tenv_usbhost/trfer_bulk_in";
  integer       i;

  begin
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("BulkIn(ep=%0d)",ep);
  //RCV
  i=0;
  if(data_size!==0)
    repeat((data_size/packet_size)+1)
      begin
      trsac_in.ep=ep;
      trsac_in.pack_size=(data_size-i)<=packet_size ? (data_size-i) :
                         packet_size;
      trsac_in.buffer_ptr=i;
      trsac_in.mode=HSK_ACK;
      trsac_in;
      toggle_bit[ep]=~toggle_bit[ep];
      i=i+trsac_in.pack_size;
      end
  end
endtask
