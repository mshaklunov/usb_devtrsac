
task reqstd_clrfeat;
  //IFACE
  integer       type;
  localparam    DEVICE=0,
                INTERFACE=1,
                ENDPOINT=2;
  integer       feature;            
  localparam    EP_HALT=0,
                REMOTE_WAKEUP=1;
  reg[3:0]      ep;
  reg           ep_dir;  
  reg[7:0]      iface;
  integer       status;
    
  //LOCAL   
  localparam    block_name="tenv_usbdev/reqstd_clrfeat";
  integer       i;

  begin
  //SETUP STAGE
  trsac_setup.ep=0;
  trsac_setup.data_size=8;
  trsac_setup.buffer_ptr=0;
  trsac_setup.handshake=ACK;
  trsac_setup;

  //DECODE REQUEST
  bm_request_type=buffer[0];
  b_request=buffer[1];
  w_value={buffer[3],buffer[2]};
  w_index={buffer[5],buffer[4]};
  w_length={buffer[7],buffer[6]};
  
  if( !(bm_request_type==type[7:0] &
        b_request==CLEAR_FEATURE & 
        w_length==feature &
        w_index==(type==DEVICE ? 0 : 
                 type==INTERFACE ? {8'd0,iface} : 
                 {8'd0,ep_dir,3'd0,ep})
        )
    )
    begin
    $write("\n");
    $write("%0t [%0s]: \n",$realtime,block_name);
    $display("%0d vs %0d.",bm_request_type,type);
    $display("%0d vs %0d.",b_request,CLEAR_FEATURE);
    $display("%0d vs %0d.",w_length,feature);
    $display("%0d vs %0d.",w_index,
            (type==DEVICE ? 0 : 
            type==INTERFACE ? {8'd0,iface} : 
            {8'd0,ep_dir,3'd0,ep})
            );
    $finish;
    end

  //STATUS STAGE
  if(status==ACK)
    begin
    trsac_in.ep=0;
    trsac_in.data_size=0;
    trsac_in.buffer_ptr=0;
    trsac_in.handshake=ACK;
    trsac_in;
    ep_enable[ep]=1'b0;
    @(posedge `tenv_clock.x4);
    ep_enable[ep]=1'b1;
    end
  else if(status==STALL)
    begin
    trsac_in.ep=0;
    trsac_in.data_size=0;
    trsac_in.buffer_ptr=0;
    trsac_in.handshake=STALL;
    trsac_in;
    end
  end
endtask
    