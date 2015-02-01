
task trsac_out;
  //IFACE
  reg[3:0]    ep;
  integer     pack_size;
  integer     buffer_ptr;
  integer     handshake;
  //LOCAL
  parameter   block_name="tenv_usbdev/trsac_out";
  integer     i;

  begin
  //BEGIN
  while(!(trsac_req==REQ_ACTIVE & trsac_type==TYPE_OUT & trsac_ep==ep))
    @(posedge `tenv_clock.x4);
  repeat(reply_delay)
    begin
    trsac_reply=STALL;
    @(posedge `tenv_clock.x4);
    end
  if(handshake==ACK)
    trsac_reply=ACK;
  else
  if(handshake==NAK)
    trsac_reply=NAK;
  else
    trsac_reply=STALL;

  //READ DATA
  i=0;
  while(trsac_req==REQ_ACTIVE)
    begin
    if(!rfifo_empty & !rfifo_rd)
      begin
      rfifo_rd=1;
      @(posedge `tenv_clock.x4);
      end
    else  if(!rfifo_empty & rfifo_rd)
      begin
      buffer[buffer_ptr+i]=rfifo_rdata;
      i=i+1;
      @(posedge `tenv_clock.x4);
      end
    else
      begin
      rfifo_rd=0;
      @(posedge `tenv_clock.x4);
      end
    end
  if(i!==pack_size)
    begin
    $write("\n");
    $write("%0t [%0s]: ",$realtime,block_name);
    $display("Error - invalid bytes quantity",i);
    $finish;
    end
  pack_size=i;

  //ENDOK
  while(~(trsac_req==REQ_OK & trsac_type==TYPE_OUT & trsac_ep==ep))
    @(posedge `tenv_clock.x4);
  end
endtask
