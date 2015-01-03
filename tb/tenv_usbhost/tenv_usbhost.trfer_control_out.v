
task trfer_control_out;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     packet_size;
  integer     status;
  //LOCAL   
  parameter   block_name="tenv_usbhost/trfer_control_out";
  integer     i;
  
  begin
  //SETUP STAGE
  trsac_setup.ep=ep;
  trsac_setup.data_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.handshake=ACK;
  trsac_setup;
  
  //DATA SATGE
  i=0;
  if(data_size!==0)
    begin
    repeat((data_size/packet_size)+1)
      begin
      trsac_out.ep=ep;
      trsac_out.data_size=data_size<=packet_size ? data_size : 
                          packet_size;
      trsac_out.buffer_ptr=i;
      trsac_out.handshake=ACK;
      trsac_out;
      toggle_bit[ep]=~toggle_bit[ep];
      i=i+trsac_out.data_size;
      end
    end

  //STATUS STAGE
  if(status==ACK)
    begin
    toggle_bit[ep]=1'b1;
    trsac_in.ep=ep;
    trsac_in.data_size=0;
    trsac_in.handshake=ACK;
    trsac_in;
    end
  else if(status==STALL)
    begin
    toggle_bit[ep]=1'b1;
    trsac_in.ep=ep;
    trsac_in.data_size=0;
    trsac_in.handshake=STALL;
    trsac_in;
    end
  end
endtask
