
task tcase_trfer_control;
  //LOCAL
  parameter   block_name="tenv_test/tcase_trfer_control";
  integer     data_size;
  integer     packet_size;
  reg[3:0]    ep;
  reg[3:0]    ep_intlvd;
  integer     i,j,k;
    
  begin
  $write("\n");
  $write("%0t [%0s]: ",$realtime,block_name);
  $display("Control transfers.");

  //#1 CONTROL_IN WITH INTERLEAVED TRANSACTION_IN
  ep=4'b0101;
  ep_intlvd=ep+1;
  packet_size=3;
  i=0;
  j=0;
  k=0;
  repeat(3)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlIn(ep=%0d) with interleaved TransactionIn(ep=%0d)",
            ep,ep_intlvd);
    
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;

    //INTERLEAVED TRANSACTION    
    if(k==0)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                       ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end
    
    //DATA STAGE
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    //INTERLEAVED TRANSACTION    
    if(k==1)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                     ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end
   
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    //INTERLEAVED TRANSACTION    
    if(k==2)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                     ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end    
    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;
    
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.data_size=8;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+8;

    //INTERLEAVED TRANSACTION
    if(k==0)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
      
    //DATA STAGE
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;

    //INTERLEAVED TRANSACTION
    if(k==1)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
    
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
 
    //INTERLEAVED TRANSACTION
    if(k==2)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
 
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    end
    join

  //#2 CONTROL_IN WITH INTERLEAVED TRANSACTION_OUT
  ep=4'b0101;
  ep_intlvd=ep+1;
  packet_size=3;
  i=0;
  j=0;
  k=0;
  repeat(3)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlIn(ep=%0d) with interleaved TransactionOut(ep=%0d)"
            ,ep,ep_intlvd);
    
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;

    //INTERLEAVED TRANSACTION    
    if(k==0)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                     ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end
    
    //DATA STAGE
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    //INTERLEAVED TRANSACTION    
    if(k==1)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                     ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end
   
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    //INTERLEAVED TRANSACTION    
    if(k==2)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                     ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end    
    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;
    
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.data_size=8;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+8;

    //INTERLEAVED TRANSACTION
    if(k==0)
      begin
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      j=j+`tenv_usbdev.trsac_out.data_size;
      `tenv_usbdev.check_data(j,packet_size);
      end
      
    //DATA STAGE
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;

    //INTERLEAVED TRANSACTION
    if(k==1)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      j=j+`tenv_usbdev.trsac_out.data_size;
      end
    
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
 
    //INTERLEAVED TRANSACTION
    if(k==2)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      j=j+`tenv_usbdev.trsac_out.data_size;
      end
      
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    end
    join
  
  //#3 CONTROL_IN ITERRUPTED BY OTHER CONTROL
  ep=4'b0101;
  packet_size=3;
  i=0;
  j=0;
  k=0;
  repeat(3)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlIn(ep=%0d) iterrupted by other Control",ep);  
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_setup.data_size;
    
    if(k==0)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      end
      
    //DATA STAGE
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    if(k==1)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      end
    
    //DATA STAGE
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;

    if(k==2)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      
      //DATA STAGE
      `tenv_usbhost.trsac_in.ep=ep;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end
    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.data_size=8;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+`tenv_usbdev.trsac_setup.data_size;

    if(k==0)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.data_size=8;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+8;
      end    
    
    //DATA STAGE
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;

    if(k==1)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.data_size=8;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+8;
      end    
     
    //DATA STAGE
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;

    if(k==2)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.data_size=8;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+8;
      
      //DATA STAGE
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
    
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    end
    join

  //#4 CONTROL_IN WITH MULTIPLE STATUS STAGES
  ep=4'b0101;
  ep_intlvd=ep+1;
  packet_size=3;
  i=0;
  j=0;
  k=0;
  repeat(1)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlIn(ep=%0d) with multiple Status Stages",
            ep);
    
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;

    //DATA STAGE
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=packet_size;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    `tenv_usbhost.check_data(i,packet_size);
    i=i+`tenv_usbhost.trsac_in.data_size;
    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;

    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;
 
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=0;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    i=i+`tenv_usbhost.trsac_out.data_size;
    
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.data_size=8;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+8;

    //DATA STAGE
    `tenv_usbdev.gen_data(j,packet_size);
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=packet_size;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    
    //STATUS STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=0;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,0);
    j=j+`tenv_usbdev.trsac_out.data_size;
    end
    join
    
  //#5 CONTROL_OUT WITH INTERLEAVED TRANSACTION_IN
  ep=4'b0101;
  ep_intlvd=ep+1;
  packet_size=2;
  i=0;
  j=0;
  k=0;
  repeat(4)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlOut(ep=%0d) with interleaved TransactionIn(ep=%0d)"
          ,ep,ep_intlvd);
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;
    //INTERLEAVED TRANSACTION
    if(k==0 | k==4)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end
    //DATA STAGE
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==1 | k==4)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==2 | k==4)
      begin
      `tenv_usbhost.trsac_in.ep=ep_intlvd;
      `tenv_usbhost.trsac_in.data_size=packet_size;
      `tenv_usbhost.trsac_in.buffer_ptr=i;
      `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_in;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      `tenv_usbhost.check_data(i,packet_size);
      i=i+`tenv_usbhost.trsac_in.data_size;
      end    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+`tenv_usbdev.trsac_setup.data_size;
    //INTERLEAVED TRANSACTION
    if(k==0 | k==4)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
    //DATA STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);
    j=j+`tenv_usbdev.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==1 | k==4)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);    
    j=j+`tenv_usbdev.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==2 | k==4)
      begin
      `tenv_usbdev.gen_data(j,packet_size);
      `tenv_usbdev.trsac_in.ep=ep_intlvd;
      `tenv_usbdev.trsac_in.data_size=packet_size;
      `tenv_usbdev.trsac_in.buffer_ptr=j;
      `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_in;
      j=j+`tenv_usbdev.trsac_in.data_size;
      end
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    end
    join

  //#6 CONTROL_OUT WITH INTERLEAVED TRANSACTION_OUT
  ep=4'b0101;
  ep_intlvd=ep+1;
  packet_size=2;
  i=0;
  j=0;
  k=0;
  repeat(4)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlOut(ep=%0d) with interleaved \
          TransactionOut(ep=%0d)",
          ep,ep_intlvd);
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;
    //INTERLEAVED TRANSACTION
    if(k==0 | k==4)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end
    //DATA STAGE
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==1 | k==4)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==2 | k==4)
      begin
      `tenv_usbhost.gen_data(i,packet_size);
      `tenv_usbhost.trsac_out.ep=ep_intlvd;
      `tenv_usbhost.trsac_out.data_size=packet_size;
      `tenv_usbhost.trsac_out.buffer_ptr=i;
      `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_out;
      `tenv_usbhost.toggle_bit[ep_intlvd]=
                                    ~`tenv_usbhost.toggle_bit[ep_intlvd];
      i=i+`tenv_usbhost.trsac_out.data_size;
      end    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+`tenv_usbdev.trsac_setup.data_size;
    //INTERLEAVED TRANSACTION
    if(k==0 | k==4)
      begin
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      `tenv_usbdev.check_data(j,packet_size);
      j=j+`tenv_usbdev.trsac_out.data_size;
      end
    //DATA STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);
    j=j+`tenv_usbdev.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==1 | k==4)
      begin
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      `tenv_usbdev.check_data(j,packet_size);
      j=j+`tenv_usbdev.trsac_out.data_size;
      end
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);    
    j=j+`tenv_usbdev.trsac_out.data_size;
    //INTERLEAVED TRANSACTION
    if(k==2 | k==4)
      begin
      `tenv_usbdev.trsac_out.ep=ep_intlvd;
      `tenv_usbdev.trsac_out.data_size=packet_size;
      `tenv_usbdev.trsac_out.buffer_ptr=j;
      `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_out;
      `tenv_usbdev.check_data(j,packet_size);
      j=j+`tenv_usbdev.trsac_out.data_size;
      end
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    end
    join
    
  //#7 CONTROL_OUT INTERRUPTED BY OTHER CONTROL
  ep=4'b0101;
  packet_size=2;
  i=0;
  j=0;
  k=0;
  repeat(3)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlOut(ep=%0d) interrupted by other Control",ep);
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;
    if(k==0)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      end
    //DATA STAGE
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    if(k==1)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      end
    `tenv_usbhost.gen_data(i,packet_size);
    `tenv_usbhost.trsac_out.ep=ep;
    `tenv_usbhost.trsac_out.data_size=packet_size;
    `tenv_usbhost.trsac_out.buffer_ptr=i;
    `tenv_usbhost.trsac_out.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_out;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+`tenv_usbhost.trsac_out.data_size;
    if(k==2)
      begin
      //SETUP STAGE
      `tenv_usbhost.toggle_bit[ep]=0;
      `tenv_usbhost.gen_data(i,8);
      `tenv_usbhost.trsac_setup.ep=ep;
      `tenv_usbhost.trsac_setup.data_size=8;
      `tenv_usbhost.trsac_setup.buffer_ptr=i;
      `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
      `tenv_usbhost.trsac_setup;
      `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
      i=i+8;
      end    
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+8;
    if(k==0)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+`tenv_usbdev.trsac_setup.data_size;
      end
    //DATA STAGE
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);
    j=j+`tenv_usbdev.trsac_out.data_size;
    if(k==1)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+8;
      end    
    `tenv_usbdev.trsac_out.ep=ep;
    `tenv_usbdev.trsac_out.data_size=packet_size;
    `tenv_usbdev.trsac_out.buffer_ptr=j;
    `tenv_usbdev.trsac_out.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_out;
    `tenv_usbdev.check_data(j,packet_size);    
    j=j+`tenv_usbdev.trsac_out.data_size;
    if(k==2)
      begin
      //SETUP STAGE
      `tenv_usbdev.trsac_setup.ep=ep;
      `tenv_usbdev.trsac_setup.buffer_ptr=j;
      `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
      `tenv_usbdev.trsac_setup;
      `tenv_usbdev.check_data(j,8);
      j=j+8;
      end    
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    end
    join

  //#8 CONTROL_OUT WITH NO DATA, STAGE MULTIPLE STATUS STAGES
  ep=4'b0101;
  packet_size=2;
  i=0;
  j=0;
  k=0;
  repeat(1)
    fork
    begin
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("# ControlOut(ep=%0d) with no data, multiple Status Stage",
            ep);
    //SETUP STAGE
    `tenv_usbhost.toggle_bit[ep]=0;
    `tenv_usbhost.gen_data(i,8);
    `tenv_usbhost.trsac_setup.ep=ep;
    `tenv_usbhost.trsac_setup.data_size=8;
    `tenv_usbhost.trsac_setup.buffer_ptr=i;
    `tenv_usbhost.trsac_setup.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_setup;
    `tenv_usbhost.toggle_bit[ep]=~`tenv_usbhost.toggle_bit[ep];
    i=i+8;
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.HSKERR;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.HSKERR;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    //STATUS STAGE
    `tenv_usbhost.toggle_bit[ep]=1;
    `tenv_usbhost.trsac_in.ep=ep;
    `tenv_usbhost.trsac_in.data_size=0;
    `tenv_usbhost.trsac_in.buffer_ptr=i;
    `tenv_usbhost.trsac_in.handshake=`tenv_usbhost.ACK;
    `tenv_usbhost.trsac_in;
    `tenv_usbhost.check_data(i,0);
    i=i+`tenv_usbhost.trsac_in.data_size;
    k=k+1;
    end
    
    begin
    //SETUP STAGE
    `tenv_usbdev.trsac_setup.ep=ep;
    `tenv_usbdev.trsac_setup.buffer_ptr=j;
    `tenv_usbdev.trsac_setup.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_setup;
    `tenv_usbdev.check_data(j,8);
    j=j+8;
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;
    //STATUS STAGE
    `tenv_usbdev.trsac_in.ep=ep;
    `tenv_usbdev.trsac_in.data_size=0;
    `tenv_usbdev.trsac_in.buffer_ptr=j;
    `tenv_usbdev.trsac_in.handshake=`tenv_usbdev.ACK;
    `tenv_usbdev.trsac_in;
    j=j+`tenv_usbdev.trsac_in.data_size;    
    end
    join
  end
endtask 
