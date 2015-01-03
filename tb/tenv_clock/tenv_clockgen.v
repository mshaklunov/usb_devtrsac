/*------------------------------------------------------------------------

Purpose

  Clocks generation.

------------------------------------------------------------------------*/
module tenv_clockgen  #(parameter clocks_number=2)
                       (
                       input[(clocks_number-1):0]     init,
                       input[(clocks_number-1):0]       en,
                       input[(clocks_number*32)-1:0]   time_high,
                       input[(clocks_number*32)-1:0]   time_low,
                       output reg[(clocks_number-1):0] clocks
                       );

  reg[(clocks_number-1):0]  init_ended;
  integer                   index;

  //CLOCKS GENERATION
  generate
  genvar i;
  for(i=0 ; i<clocks_number ; i=i+1)
    begin
    //BEGIN COPY CODE
    initial
      begin
      init_ended[i]=1'b0;
      wait(init[i]==1'b0 | init[i]==1'b1);
      clocks[i]=init[i];
      init_ended[i]=1'b1;
      
      forever
        begin
        wait(en[i]==1'b1);
        
        fork:loop
          forever
            begin
            if(clocks[i]==1'b0)
              begin
              #(time_high[((i+1)*32)-1:i*32]);
              clocks[i]=~clocks[i];
              #(time_low[((i+1)*32)-1:i*32]);
              end
            else
              begin
              #(time_low[((i+1)*32)-1:i*32]);
              clocks[i]=~clocks[i];
              #(time_high[((i+1)*32)-1:i*32]);
              end
            clocks[i]=~clocks[i];  
            end
            
          begin
          wait(en[i]==1'b0);
          disable loop;
          end
        join
        end
      end
    //END COPY CODE
    end
  endgenerate
  
  //VALIDATION INPUTS STATE
  initial
    begin
    forever @(time_low, time_high, en, init)
      begin
      index=(clocks_number*32)-1;
      while(index!=-1)
        begin
        if(time_high[index]===1'bz | time_high[index]===1'bx)
          begin
          $display("%0t [clocks_generator]: Error - time_high[%0d] = %b",
                  $realtime,index,time_high[index]);
          $finish;
          end
        if(time_low[index]===1'bz | time_low[index]===1'bx)
          begin
          $display("%0t [clocks_generator]: Error - time_low[%0d] = %b",
                  $realtime,index,time_low[index]);
          $finish;
          end
        index= index-1;
        end
      index= (clocks_number)-1;
      while(index!=-1)
        begin
        if(en[index]===1'bz | en[index]===1'bx)
          begin
          $display("%0t [clocks_generator]: Error - en[%0d] = %b",
                  $realtime,index,en[index]);
          $finish;
          end
        if( (init[index]===1'bz | init[index]===1'bx) & 
            init_ended[index]==1'b0 )
          begin
          $display("%0t [clocks_generator]: Error - init[%0d] = %b",
                  $realtime,index,init[index]);
          $finish;
          end
        index= index-1;
        end
      end
    end
endmodule
