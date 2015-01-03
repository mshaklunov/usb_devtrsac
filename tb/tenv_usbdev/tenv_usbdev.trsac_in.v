
task trsac_in;
  //IFACE
  reg[3:0]    ep;
  integer     data_size;
  integer     buffer_ptr;
  integer     handshake;
  reg[1:0]    status;
  //LOCAL   
  parameter   block_name="tenv_usbdev/trsac_in";
  integer     i;
  
  begin
  //BEGIN
  while(!(trsac_req==REQ_ACTIVE & trsac_type==TYPE_IN & trsac_ep==ep))
    @(posedge `tenv_clock.x4);
  repeat(reply_delay)
    begin
    trsac_reply=STALL;
    @(posedge `tenv_clock.x4);
    end
  
  if(handshake==ACK)
    begin
    trsac_reply=ACK;
    //WRITE DATA
    i=0;
    @(posedge `tenv_clock.x4);
    while(trsac_req==1 & tfifo_full==0 & i<data_size)
      begin
      tfifo_wr=1;
      tfifo_wdata=buffer[buffer_ptr+i];
      i=i+1;
      @(posedge `tenv_clock.x4);
      end
    tfifo_wr=0;
    @(posedge `tenv_clock.x4);
    end
  else
  if(handshake==NAK)
    begin
    trsac_reply=NAK;
    end
  else
    begin
    trsac_reply=STALL;
    end

  //ENDOK
  while(~(trsac_req==status & trsac_type==TYPE_IN & trsac_ep==ep))
    @(posedge `tenv_clock.x4);  
  end
endtask
