
module tenv_usb_encoder        #(parameter PACKET_MAXSIZE=64);
  //IFACE
  reg                          dplus=1;
  reg                          dminus=0;
  reg                          doe=0;
            
  reg                          start=0;
  integer                      mode=0;
  localparam                   USB_PACKET=0,
                               USB_RESET=1;
  reg                          speed=1;
  real                         bit_time=10;
  reg signed[31:0]             jitter=0;
  reg signed[31:0]             jitter_sync1=0;
  reg signed[31:0]             jitter_sync2=0;
  reg signed[31:0]             jitter_lastbit=0;
  reg                          sync_corrupt=0;
  reg[7:0]                     err_pid=0;
  reg[15:0]                    err_crc=0;
  reg                          err_bitstuff;
  reg[(PACKET_MAXSIZE*8)-1:0]  data=0;
  integer                      pack_size=0;
  reg[7:0]                     pid=0;
  localparam                   PIDOUT=8'b1110_0001,
                               PIDIN=8'b0110_1001,
                               PIDSOF=8'b1010_0101,
                               PIDSETUP=8'b0010_1101,
                               PIDDATA0=8'b1100_0011,
                               PIDDATA1=8'b0100_1011,
                               PIDACK=8'b1101_0010,
                               PIDNAK=8'b0101_1010,
                               PIDSTALL=8'b0001_1110,
                               PIDPRE=8'b0011_1100;
  //LOCAL
  localparam                   block_name="tenv_usbhost/tenv_usb_decoder";
  integer                      dplus_prev;
  integer                      count_ones;
  integer                      i,j;
  reg[15:0]                    crc;

  initial forever
    begin
    wait(start);
    dplus=speed;
    dminus=~speed;
    doe=1;
    #bit_time;
    if(mode==USB_PACKET)
      begin

      //SYNC
      dplus= !sync_corrupt ? ~dplus : dplus;
      dminus= !sync_corrupt ? ~dminus : dminus;
      #(bit_time+jitter_sync1);
      dplus= !sync_corrupt ? ~dplus : dplus;
      dminus= !sync_corrupt ? ~dminus : dminus;
      #(bit_time+jitter_sync2);
      dplus=~dplus;
      dminus=~dminus;
      #bit_time;
      dplus=~dplus;
      dminus=~dminus;
      #bit_time;
      dplus=~dplus;
      dminus=~dminus;
      #bit_time;
      dplus=~dplus;
      dminus=~dminus;
      #bit_time;
      dplus=~dplus;
      dminus=~dminus;
      dplus_prev=dplus;
      #bit_time;
      #bit_time;

      //PID
      i=0;
      count_ones=1;
      while(i<8)
        begin
        if(count_ones==6)
          begin
          dplus= ~dplus;
          dminus= ~dplus;
          count_ones=0;
          end
        else
          begin
          dplus= pid[i]==1'b1 ? dplus^err_pid[i] : (~dplus)^err_pid[i];
          dminus= ~dplus;
          if(pid[i]==1)
            count_ones= count_ones+1;
          else
            count_ones=0;
          i= i+1;
          end

        if(dplus!=dplus_prev)
          #(bit_time+jitter);
        else
          #bit_time;
        dplus_prev=dplus;
        end

      //DATA
      i=0;
      while(i<pack_size)
        begin
        if(count_ones==6)
          begin
          dplus= ~dplus;
          dminus= ~dplus;
          count_ones=0;
          end
        else
          begin
          dplus= data[i]==1'b1 ? dplus : ~dplus;
          dminus= ~dplus;
          if(data[i]==1)
            count_ones= count_ones+1;
          else
            count_ones=0;
          i= i+1;
          end
        if(dplus!=dplus_prev)
          #(bit_time+jitter);
        else
          #bit_time;
        dplus_prev=dplus;
        end

      //CRC
      crc=16'hffff;
      if(pid==PIDDATA0 | pid==PIDDATA1)
        begin
        j=0;
        while(j!=i)
          begin
          crc=  (crc[15]^data[j]) ? {crc[14:0],1'b0}^16'h8005 :
                {crc[14:0],1'b0};
          j= j+1;
          end
        j=15;
        crc=~crc;
        end
      else
      if(pid==PIDSETUP | pid==PIDIN | pid==PIDOUT | pid==PIDSOF)
        begin
        j=0;
        while(j!=i)
          begin
          crc[4:0]=   (crc[4]^data[j]) ? {crc[3:0],1'b0}^5'b00101 :
                      {crc[3:0],1'b0};
          j= j+1;
          end
        j=4;
        crc=~crc;
        end

      while(j!=-1)
        begin
        if(count_ones==6)
          begin
          dplus= ~dplus;
          dminus= ~dplus;
          count_ones=0;
          end
        else
          begin
          dplus= crc[j]==1'b1 ? dplus^err_crc[j] :
                 (~dplus)^err_crc[j];
          dminus= ~dplus;
          if(crc[j]==1)
            count_ones= count_ones+1;
          else
            count_ones=0;
          j= j-1;
          end

        if(dplus!=dplus_prev & j==-1 & count_ones!==6)
          #(bit_time+jitter_lastbit);
        else if(dplus!=dplus_prev)
          #(bit_time+jitter);
        else
          #bit_time;
        dplus_prev=dplus;
        end
      if(count_ones==6 & !err_bitstuff)
        begin
        dplus= ~dplus;
        dminus= ~dplus;
        count_ones=0;
        if(dplus!=dplus_prev)
          #(bit_time+jitter);
        else
          #bit_time;
        dplus_prev=dplus;
        end

      //EOP
      repeat(2)
        begin
        dplus= 0;
        dminus= 0;
        #bit_time;
        end

      dplus= speed;
      dminus= ~speed;
      #bit_time;
      doe= 0;
      end
    else if(mode==USB_RESET)
      begin
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Generate USB reset with duration 7us.");
      //USB RESET: required minimum 10ms
      //           generated ~7us
      repeat(7)
        begin
        dplus=0;
        dminus=0;
        #1000;
        end
      dplus= speed;
      dminus= ~speed;
      #bit_time;
      doe= 0;
      #1000;
      end
    start=0;
    end
endmodule
