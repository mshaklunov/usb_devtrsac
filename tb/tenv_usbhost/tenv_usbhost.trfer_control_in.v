
task trfer_control_in;
  //IFACE
  reg[3:0]      ep;
  integer       data_size;
  integer       packet_size;
  integer       status;
  //LOCAL   
  localparam    block_name="tenv_usbhost/trfer_control_in";
  integer       i,j;
  
  begin
  //SETUP STAGE
  trsac_setup.ep=ep;
  trsac_setup.data_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.handshake=status;
  trsac_setup;
  //DATA STAGE
  if(status==ACK)
    begin
    i=0;
    toggle_bit[ep]=1'b1;
    if(data_size!==0)
      repeat((data_size/packet_size)+1)
        begin
        trsac_in.ep=ep;
        trsac_in.data_size= (data_size-i)<=packet_size ? data_size-i : 
                            packet_size;
        trsac_in.buffer_ptr=i;
        trsac_in.handshake=ACK;
        trsac_in;
        toggle_bit[ep]=~toggle_bit[ep];
        i=i+trsac_in.data_size;
        end
    data_size=i;
    end
  //STATUS STAGE
  if(status==ACK)
    begin
    toggle_bit[ep]=1'b1;
    trsac_out.ep=ep;
    trsac_out.data_size=0;
    trsac_out.handshake=ACK;
    trsac_out;
    end
  end
endtask
