
task trfer_control_out;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;
  integer     mode;
  //LOCAL
  parameter   block_name="tenv_usbhost/trfer_control_out";
  integer     i;

  begin
  //SETUP STAGE
  trsac_setup.ep=ep;
  trsac_setup.pack_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.mode= mode==REQ_SETUPERR ? HSK_ERR : HSK_ACK;
  trsac_setup;

  //DATA SATGE
  i=0;
  if(data_size!==0 & mode!==REQ_SETUPERR)
    begin
    repeat((data_size/packet_size)+1)
      begin
      trsac_out.ep=ep;
      trsac_out.pack_size=data_size<=packet_size ? data_size :
                          packet_size;
      trsac_out.buffer_ptr=i;
      trsac_out.mode=HSK_ACK;
      trsac_out;
      toggle_bit[ep]=~toggle_bit[ep];
      i=i+trsac_out.pack_size;
      end
    end

  //STATUS STAGE
  if(mode!==REQ_SETUPERR)
    begin
    toggle_bit[ep]=1'b1;
    trsac_in.ep=ep;
    trsac_in.pack_size=0;
    trsac_in.mode= mode==REQ_STATSTALL ? HSK_STALL : HSK_ACK;
    trsac_in;
    end
  end
endtask
