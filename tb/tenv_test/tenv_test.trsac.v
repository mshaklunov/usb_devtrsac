
task trsac_in(input[3:0] ep);
  //LOCAL
  integer packet_size,i,j;

  fork
    begin
    packet_size=1;
    i=0;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i*packet_size;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i*packet_size,packet_size);
    end
    
    begin
    packet_size=1;
    j=0;
    `tenv_usbdev.gen_data(j*packet_size,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j*packet_size;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;    
    end
  join
endtask
  
task trsac_out(input[3:0] ep);
  //LOCAL
  integer packet_size,i,j;
  
  fork
  begin
  packet_size=1;
  i=0;
  `tenv_usbhost.gen_data(i*packet_size,packet_size);
  `tenv_usbhost.trsac_out.ep=ep;
  `tenv_usbhost.trsac_out.data_size=packet_size;
  `tenv_usbhost.trsac_out.buffer_ptr=i*packet_size;
  `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
  `tenv_usbhost.trsac_out;
  `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
  end
  
  begin
  packet_size=1;
  j=0;
  `tenv_usbdev.trsac_out.ep=ep;
  `tenv_usbdev.trsac_out.data_size=packet_size;
  `tenv_usbdev.trsac_out.buffer_ptr=j*packet_size;
  `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
  `tenv_usbdev.trsac_out;
  `tenv_usbdev.check_data(j*packet_size,packet_size);
  end
  join
endtask
