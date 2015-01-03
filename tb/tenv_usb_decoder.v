
module tenv_usb_decoder;
  //IFACE
  wire                dplus;
  wire                dminus;
      
  reg                 start=0;
  integer             mode=0;
  localparam          MODE_PACKET=0,
                      MODE_NOREPLY=1,
                      MODE_WAKEUP=2;
  reg                 speed;
  reg[7:0]            pid=0;
  reg[(64*8)+15:0]    data=0;
  integer             data_size=0;  
  integer             bit_time=10;
    
  localparam          PIDOUT=8'b1110_0001;
  localparam          PIDIN=8'b0110_1001;
  localparam          PIDSOF=8'b1010_0101;
  localparam          PIDSETUP=8'b0010_110;
  localparam	        PIDDATA0=8'b1100_0011;
  localparam          PIDDATA1=8'b0100_1011;
  localparam          PIDACK=8'b1101_0010;
  localparam          PIDNAK=8'b0101_1010;
  localparam          PIDSTALL=8'b0001_1110;
  localparam	        PIDPRE=8'b0011_1100;
    
  //LOCAL   
  localparam          block_name="tenv_usb_decoder";
  integer             loop;
  reg[15:0]           crc;
  reg[7:0]            sync=8'b10000000;
  reg                 dplus_prev=1;
  integer             count_ones=0;
  integer             i=0,j=0;

  initial forever
		begin
    wait(start);
    //CHECK IDLE
    if(dplus!==speed | dplus!==~dminus)
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - invalid bus idle state.");
      $finish;
      end
    dplus_prev= dplus;
    
    if(mode==MODE_PACKET)
      fork
      //INTERPACKET DELAY: required < 6.5 BIT TIME
      //                   checked < 4 BIT TIME            
      begin:TIMEOUT
      j=0;
      while(dplus_prev==dplus)
        begin
        #bit_time;
        j=j+1;
        if(j==4)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - timeout.");
          $finish;        
          end
        end
      end
      
      begin:DECODE
      wait(dplus!==dplus_prev);
      disable TIMEOUT;
      
      //SYNC    
      #(bit_time/4);
      i=0;
      repeat(8)
        begin
        if(dplus!==~dminus)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid diff lines state.");
          $finish;
          end
        if((dplus==dplus_prev?1'b1:1'b0)!==sync[i])
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid SYNC.");
          $finish;
          end
        i=i+1;
        dplus_prev= dplus;
        #bit_time;
        end

      //PID
      i=0;
      count_ones=1;
      while((dplus!==0 | dminus!==0) & i!= 8)
        begin
        pid[i]= dplus_prev==dplus ? 1'b1 : 1'b0;
        i= i+1;
        if(dplus_prev==dplus)
          count_ones= count_ones+1;
        else
          count_ones= 0;
        if(dplus!==~dminus)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid diff lines state.");
          $finish;
          end
        dplus_prev=dplus;
        #bit_time;
        end
      if(pid[3:0]!==~pid[7:4])
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - invalid PID.");
        $finish;
        end
       
      //DATA
      i=0;
      while((dplus!==0 | dminus!==0))
        begin
        if(count_ones!==6)
          begin
          data[i]= dplus_prev==dplus ? 1'b1 : 1'b0;
          i= i+1;
          end
        if(dplus_prev==dplus)
          count_ones= count_ones+1;
        else
          count_ones= 0;
        if(count_ones==7 & dplus_prev==dplus)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid bit stuffing.");
          $finish;
          end
        if(dplus!==~dminus)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid diff lines state.");
          $finish;
          end  
        dplus_prev=dplus;
        #bit_time;
        end
      
      //EOP
      #bit_time;
      if(dplus!==0 | dminus!==0)
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - invalid EOP SE0.");
        $finish;
        end

      #bit_time;
      if(dplus!==speed | dminus!==~speed)
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - invalid EOP IDLE.");
        $finish;
        end
      #bit_time;
      
      //CRC
      crc=16'hffff;
      if(pid==PIDDATA0 | pid==PIDDATA1)
        begin
        j=0;
        while(j!=i)
          begin
          crc=    (crc[15]^data[j]) ? {crc[14:0],1'b0}^16'h8005 :
                  {crc[14:0],1'b0};
          j= j+1;
          end
        i= i-16;
        if(crc!==16'h800D)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid CRC16.");
          $finish;
          end
        end
      else
      if(pid==PIDSETUP | pid==PIDIN | pid==PIDOUT | pid==PIDSOF)
        begin
        j=0;
        while(j!=i)
          begin
            crc[4:0]= (crc[4]^data[j]) ? {crc[3:0],1'b0}^5'b00101 :
                      {crc[3:0],1'b0};
          j= j+1;
          end
        i= i-5;  
        if(crc!==5'b01100)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid CRC5.");
          $finish;
          end
        end
      
      //CHECK BYTES QUANTITY
      if(i[2:0]!==0)
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - invalid quantity of bytes.");
        $finish;
        end
      data_size=i;
      end
      
      join
    else if(mode==MODE_WAKEUP)
      begin
      //WAKEUP: required 1-15ms
      //        checked 1-5ms  
      j=0;
      while({dplus,dminus}!=={~speed,speed})
        begin
        #bit_time;
        j=j+1;
        if(j==5)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - timeout.");
          $finish;     
          end
        end
      j=0;
      while({dplus,dminus}=={~speed,speed})
        begin
        #1000;
        j=j+1;
        if(j>=5000)
          begin
          $write("\n");
          $write("%0t [%0s]: ",$realtime,block_name);
          $display("Error - invalid wakeup.");
          $finish;     
          end
        end
      if(j<1000)
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - invalid wakeup.");
        $finish;     
        end
      end
    else if(mode==MODE_NOREPLY)
      begin
      j=0;
      while(dplus_prev==dplus & j!=18)
        begin
        #bit_time;
        j=j+1;
        end
      if(dplus_prev!==dplus)
        begin
        $write("\n");
        $write("%0t [%0s]: ",$realtime,block_name);
        $display("Error - bus is active.");
        $finish;
        end
      end
    
    start=0;
		end
   
endmodule
  