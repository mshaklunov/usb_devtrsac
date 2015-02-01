
task trfer_control_in;
  //IFACE
  reg[3:0]      ep;
  integer       data_size;
  integer       packet_size;
  integer       mode;
  //LOCAL
  localparam    block_name="tenv_usbhost/trfer_control_in";
  integer       i,j;

  begin
  //SETUP STAGE
  trsac_setup.ep=ep;
  trsac_setup.pack_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.mode= mode==REQ_SETUPERR ? HSK_ERR : HSK_ACK;
  trsac_setup;
  //DATA STAGE
  if(mode!==REQ_SETUPERR)
    begin
    i=0;
    toggle_bit[ep]=1'b1;
    if(data_size!==0)
      repeat((data_size/packet_size)+1)
        begin
        trsac_in.ep=ep;
        trsac_in.pack_size= (data_size-i)<=packet_size ? data_size-i :
                            packet_size;
        trsac_in.buffer_ptr=i;
        trsac_in.mode=HSK_ACK;
        trsac_in;
        toggle_bit[ep]=~toggle_bit[ep];
        i=i+trsac_in.pack_size;
        end
    data_size=i;
    end
  //STATUS STAGE
  if(mode!==REQ_SETUPERR)
    begin
    toggle_bit[ep]=1'b1;
    trsac_out.ep=ep;
    trsac_out.pack_size=0;
    trsac_out.mode=HSK_ACK;
    trsac_out;
    end
  end
endtask
