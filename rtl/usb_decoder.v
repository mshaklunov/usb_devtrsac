/*------------------------------------------------------------------------

1 Purpose

  Bit stream decoding, USB reset detection, USB suspend detection.

2 Bit stream decoding

  - Synchronize bit stream with clk;
  - extract bits with DPLL;
  - unstuff bit stream, decode nrzi;
  - decode fields of packet, write data to rfifo;
  - check errors.
  
------------------------------------------------------------------------*/
module usb_decoder  (
                    input             clk,
                    input             rst0_async,
                    input             rst0_sync,
                    //USB TRANSCEIVER
                    input             drx_plus,
                    input             drx_minus,
                    input             drx,
                    
                    input             dtx_oe,
                    //USB LINES STATE
                    output reg        usb_rst,
                    output reg        usb_spnd,
                    output reg        usb_interpack,
                    //PACKET
                    input[6:0]        dev_addr,
                    input[15:0]       ep_enable,
                    output[3:0]       rdec_epaddr,
                    output            rdec_pidin,
                    output            rdec_pidout,
                    output            rdec_pidsetup,
                    output            rdec_piddata0,
                    output            rdec_piddata1,
                    output            rdec_pidack,
                    //SOF
                    output reg        sof_tick,
                    output reg[10:0]  sof_value,
                    //RFIFO     
                    input             rfifo_full,
                    output            rdec_rfifo_wr,
                    output reg        rextr_data,
                    output reg        rdec_minuscrc,
                    output reg        rdec_rfifo_rst0,
                    
                    input             speed
                    );

  //SYNC USB DATA LINES
  wire        drx_plus_sync;
  wire        drx_minus_sync;
  wire        drx_sync;
  //BIT EXTRACTION
  reg[1:0]    dpll_on;
  reg         drx_prev;
  reg         dpll_sample;
  reg         dpll_denrzi_prev;
  wire        dpll_denrzi;
  reg[2:0]    dpll_state;
  localparam  DPLL_READY=3'd0,
              DPLL_S1=3'd1,
              DPLL_S2=3'd2,
              DPLL_S3=3'd3,
              DPLL_S4=3'd4,
              DPLL_EOP=3'd5;
  reg[2:0]    rextr_unstuff;
  reg         rextr_sample;
  reg         rextr_se0;
  //PACKET DECODING
  wire        rdec_pidsof;
  reg         rdec_rfifo_full;
  reg[15:0]   rdec_crc;
  reg[15:0]   rdec_crc_prev;
  reg[9:0]    rdec_counter; 
  reg[7:0]    rdec_pid;
  reg[15:0]   rdec_addrsof;
  reg[2:0]    rdec_state;
  localparam  RDEC_SYNC=3'd0,
              RDEC_PID=3'd1,
              RDEC_ADDR=3'd2,
              RDEC_DATA=3'd3,
              RDEC_HSK=3'd4,
              RDEC_FAIL=3'd5,
              RDEC_OK=3'd6;
  localparam  PID_IN=4'b1001,
              PID_OUT=4'b0001,
              PID_SOF=4'b0101,
              PID_SETUP=4'b1101,
              PID_DATA0=4'b0011,
              PID_DATA1=4'b1011,
              PID_ACK=4'b0010,
              PID_NAK=4'b1010,
              PID_STALL=4'b1110;
  //USB LINES STATE
  wire        usb_j;
  wire        usb_k;
  wire        se0;
  reg[17:0]   usb_timer;
  reg[2:0]    usb_state;
  localparam  USB_SELECT=3'd0,
              USB_RSTTIME_1=3'd1,
              USB_RSTTIME_2=3'd2,
              USB_SPNDTIME=3'd3,
              USB_SPNDENTER=3'd4;

  //SYNC USB DATA 
  usb_synczer    #(.DATA_WIDTH(3),.DATA_ONRST(3'd0))
  i_sync_usbdata  (
                  .reset0_async   (rst0_async),
                  .reset0_sync    (rst0_sync),
                  .clock          (clk),
                  .datain_async   ({drx_plus,
                                    drx_minus,
                                    drx}),
                  .dataout_sync   ({drx_plus_sync,
                                    drx_minus_sync,
                                    drx_sync})  
                  );
  
  //BIT EXTRACTION
  assign dpll_denrzi= drx_sync==dpll_denrzi_prev ? 1'b1 : 1'b0;
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      drx_prev<=1'b0;
      dpll_on<=2'd0;
      dpll_sample<=1'b0;
      dpll_denrzi_prev<=1'b1;
      dpll_state<=DPLL_READY;
      rextr_unstuff<=3'd0;
      rextr_sample<=1'b0;
      rextr_data<=1'b0;
      rextr_se0<=1'b0;
      end
    else if(!rst0_sync)
      begin
      drx_prev<=1'b0;
      dpll_on<=2'd0;
      dpll_sample<=1'b0;
      dpll_denrzi_prev<=1'b1;
      dpll_state<=DPLL_READY;
      rextr_unstuff<=3'd0;
      rextr_sample<=1'b0;
      rextr_data<=1'b0;
      rextr_se0<=1'b0;
      end
    else
      begin
      drx_prev<= drx_sync;
      dpll_on<=dpll_on==2'b11 ? dpll_on : dpll_on+1'b1;
      case(dpll_state)
      DPLL_READY:
        begin
        dpll_denrzi_prev<= speed ? 1'b1 : 1'b0;
        dpll_sample<= drx_sync!=drx_prev & dpll_on==2'd3 ? 1'b1 : 1'b0;
        dpll_state<= drx_sync!=drx_prev & dpll_on==2'd3 ? DPLL_S2 : 
                     dpll_state;
        end
      DPLL_S1://NORMAL TRAN
        begin
        dpll_sample<= 1'b1;
        dpll_state<= DPLL_S2;
        end
      DPLL_S2://SLOW TRAN
        begin
        dpll_sample<= 1'b0;
        dpll_denrzi_prev<= drx_sync;
        dpll_state<=  se0 ? DPLL_EOP :
                      drx_sync!=drx_prev ? DPLL_S2 : 
                      DPLL_S3;
        end
      DPLL_S3:
        begin
        dpll_state<= DPLL_S4;
        end
      DPLL_S4://FAST TRAN
        begin
        dpll_sample<= drx_sync!=drx_prev ? 1'b1 : 1'b0;
        dpll_state<= drx_sync!=drx_prev ? DPLL_S2 : DPLL_S1;
        end
      DPLL_EOP:
        begin
        dpll_state<=!se0 & drx_sync==speed & drx_prev==speed ? DPLL_READY: 
                    dpll_state;
        end
      endcase
    
      rextr_unstuff<=(dpll_sample & (rextr_unstuff==3'd6 | !dpll_denrzi))|
                     dpll_state==DPLL_READY ? 3'd0 :
                     dpll_sample & dpll_denrzi ? rextr_unstuff+1'b1 : 
                     rextr_unstuff;
      rextr_sample<= dpll_sample & !se0 &
                     rextr_unstuff!=3'd6 ? 1'b1 : 1'b0;
      rextr_data<= dpll_sample ? dpll_denrzi : rextr_data;
      rextr_se0<= dpll_sample ? se0 : rextr_se0;
      end
    end
  
  //PACKET DECODING
  assign rdec_epaddr= rdec_addrsof[10:7];
  assign rdec_pidsof= rdec_state==RDEC_OK & 
                      rdec_pid[3:0]==PID_SOF;  
  assign rdec_pidin=  rdec_state==RDEC_OK & 
                      rdec_pid[3:0]==PID_IN &
                      ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                      rdec_addrsof[6:0]==dev_addr;
  assign rdec_pidout= rdec_state==RDEC_OK & 
                      rdec_pid[3:0]==PID_OUT &
                      ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                      rdec_addrsof[6:0]==dev_addr;
  assign rdec_pidsetup= rdec_state==RDEC_OK & 
                        rdec_pid[3:0]==PID_SETUP &
                        ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                        rdec_addrsof[6:0]==dev_addr;
  assign rdec_piddata0= rdec_state==RDEC_OK & 
                        rdec_pid[3:0]==PID_DATA0 &
                        ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                        rdec_addrsof[6:0]==dev_addr;
  assign rdec_piddata1= rdec_state==RDEC_OK & 
                        rdec_pid[3:0]==PID_DATA1 &
                        ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                        rdec_addrsof[6:0]==dev_addr;
  assign rdec_pidack=   rdec_state==RDEC_OK & 
                        rdec_pid[3:0]==PID_ACK &
                        ep_enable[ rdec_addrsof[10:7] ]==1'b1 &
                        rdec_addrsof[6:0]==dev_addr;
  assign rdec_rfifo_wr= !rdec_rfifo_full &
                        rextr_sample & 
                        rdec_state==RDEC_DATA;
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      rdec_rfifo_full<=1'b0;
      rdec_rfifo_rst0<=1'b1;
      rdec_crc<=16'd0;
      rdec_crc_prev<=16'd0;
      rdec_counter<=10'd0; 
      rdec_pid<=8'd0;
      rdec_addrsof<=11'd0;
      rdec_state<=RDEC_SYNC;
      rdec_minuscrc<=1'b0;
      end
    else if(!rst0_sync)
      begin
      rdec_rfifo_full<= 1'b0;
      rdec_rfifo_rst0<= 1'b1;
      rdec_crc<=16'd0;
      rdec_crc_prev<=16'd0;
      rdec_counter<=0; 
      rdec_pid<=8'd0;
      rdec_addrsof<=11'd0;
      rdec_state<=RDEC_SYNC;
      rdec_minuscrc<=1'b0;
      end  
    else
      begin
      rdec_rfifo_full<=rfifo_full;
      
      case(rdec_state)
      RDEC_SYNC:
        begin
        rdec_crc<= 16'hFFFF;
        rdec_counter<=  rdec_counter>=10'd6 & rdec_counter<=10'd8 &
                        rdec_pid[7:5]==3'b100 ? 10'd0 : 
                        rextr_sample ? rdec_counter+1'b1 : 
                        rdec_counter;
        rdec_pid<= rextr_sample ? {rextr_data,rdec_pid[7:1]} : rdec_pid;
        rdec_state<=  rdec_counter>=10'd6 & rdec_counter<=10'd8 &
                      rdec_pid[7:5]==3'b100 ? RDEC_PID :
                      rdec_counter==10'd8 ? RDEC_FAIL :
                      rdec_state;
        end
      RDEC_PID:
        begin
        rdec_rfifo_rst0<= rdec_counter==10'd8 &
                          (rdec_pid[7:0]=={~PID_DATA0,PID_DATA0} |
                          rdec_pid[7:0]=={~PID_DATA1,PID_DATA1}) ? 1'b0 :
                          1'b1;
          
        rdec_counter<=  rdec_counter==10'd8 ? 10'd0 : 
                        rextr_sample ? rdec_counter+1 : 
                        rdec_counter;
        rdec_pid<= rextr_sample ? {rextr_data,rdec_pid[7:1]} : rdec_pid;
        rdec_state<= rdec_counter==10'd8 & 
          (rdec_pid[7:0]=={~PID_SOF,PID_SOF} |
          rdec_pid[7:0]=={~PID_SETUP,PID_SETUP} | 
          rdec_pid[7:0]=={~PID_IN,PID_IN} |
          rdec_pid[7:0]=={~PID_OUT,PID_OUT} ) ? RDEC_ADDR :
          
          rdec_counter==10'd8 &
          (rdec_pid[7:0]=={~PID_DATA0,PID_DATA0} |
          rdec_pid[7:0]=={~PID_DATA1,PID_DATA1}) ? RDEC_DATA :
          
          rdec_counter==10'd8 &
          rdec_pid[7:0]=={~PID_ACK,PID_ACK} ? RDEC_HSK :
          
          rdec_counter==10'd8 | rextr_se0 ? RDEC_FAIL :
          rdec_state;
        end
      RDEC_ADDR:
        begin
        rdec_counter<=  rextr_sample ? rdec_counter+1'b1 : 
                        rdec_counter;
        rdec_addrsof<=  rextr_sample & rdec_counter[4]!=1'b1 ? 
                        {rextr_data,rdec_addrsof[15:1]} : 
                        rdec_addrsof;
        rdec_crc_prev<= rextr_sample ? rdec_crc : rdec_crc_prev;
        rdec_crc[4:0]<= rextr_sample & 
          (rdec_crc[4]^rextr_data) ? {rdec_crc[3:0],1'b0}^5'b00101 :
          rextr_sample ? {rdec_crc[3:0],1'b0} :
          rdec_crc;
        rdec_state<=  rdec_counter==10'd18 ? RDEC_FAIL :
                      (rextr_se0 & rdec_crc[4:0]==5'b01100 & 
                      rdec_counter[2:0]==3'd0)  |
                      (rextr_se0 & rdec_crc_prev[4:0]==5'b01100 & 
                      rdec_counter[2:0]==3'd1) ? RDEC_OK :
                      rextr_se0 ? RDEC_FAIL :
                      rdec_state;
        end
      RDEC_DATA:
        begin
        rdec_rfifo_rst0<= 1'b1;
        rdec_counter<= rextr_sample ? rdec_counter+1'b1 : rdec_counter;
        rdec_minuscrc<= !rfifo_full &  
                        ((rextr_se0 & rdec_crc==16'h800D & 
                        rdec_counter[2:0]==3'd0) |
                        (rextr_se0 & rdec_crc_prev==16'h800D & 
                        rdec_counter[2:0]==3'd1)) ? 1'b1 : 1'b0;
        rdec_crc_prev<= rextr_sample ? rdec_crc : rdec_crc_prev;
        rdec_crc<= rextr_sample &
          (rdec_crc[15]^rextr_data) ? {rdec_crc[14:0],1'b0}^16'h8005 :
          rextr_sample ? {rdec_crc[14:0],1'b0} :
          rdec_crc;
        rdec_state<=  rdec_counter==(10'd512+5'd16+2'd2) ? RDEC_FAIL :
                      (rextr_se0 & rdec_crc==16'h800D & 
                      rdec_counter[2:0]==3'd0) |  
                      (rextr_se0 & rdec_crc_prev==16'h800D & 
                      rdec_counter[2:0]==3'd1) ? RDEC_OK :
                      rextr_se0 ? RDEC_FAIL :
                      rdec_state;
        end
      RDEC_HSK:
        begin
        rdec_counter<= rextr_sample ? rdec_counter+1'b1 : rdec_counter;
        rdec_state<=  rextr_se0 ? RDEC_OK :
                      rextr_sample & rdec_counter==10'd1 ? RDEC_FAIL: 
                      rdec_state;
        end
      RDEC_FAIL:
        begin
        rdec_minuscrc<=1'b0;
        rdec_counter<=10'd0;
        rdec_state<= RDEC_SYNC;
        end
      RDEC_OK:
        begin
        rdec_minuscrc<=1'b0;
        rdec_counter<=10'd0;
        rdec_state<= RDEC_SYNC;
        end
      endcase
      end
    end
  
  //SOF
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      sof_tick<=1'b0;
      sof_value<=11'd0;
      end
    else if(!rst0_sync)
      begin
      sof_tick<=1'b0;
      sof_value<=11'd0;
      end      
    else
      begin
      sof_tick<=  rdec_pidsof;
      sof_value<= rdec_pidsof ? rdec_addrsof : sof_value;
      end
    end
  
  //USB RESET DETECTION: 
  //                  ~240 CYCLES ~5us (FULL SPEED) 
  //                  ~30 CYCLES  ~5us (LOW SPEED)
  //USB SUSPEND DETECTION:
  //                  ~262143 CYCLES ~5,2ms (FULL SPEED)
  //                  ~33330 CYCLES ~5,5ms (LOW SPEED)
  assign se0= !drx_plus_sync & !drx_minus_sync ? 1'b1 : 1'b0;
  assign usb_j= (speed & drx_plus_sync & !drx_minus_sync) |
                (!speed & !drx_plus_sync & drx_minus_sync) ? 1'b1 : 1'b0;
  assign usb_k= (speed & !drx_plus_sync & drx_minus_sync) |
                (!speed & drx_plus_sync & !drx_minus_sync) ? 1'b1 : 1'b0;
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      usb_rst<=0;
      usb_spnd<=0;
      usb_timer<=0;
      usb_state<=USB_SELECT;
      end
    else if(!rst0_sync)
      begin
      usb_rst<=0;
      usb_spnd<=0;
      usb_timer<=0;
      usb_state<=USB_SELECT;
      end
    else
      begin
      case(usb_state)
      USB_SELECT:
        begin
        usb_rst<=1'b0;
        usb_spnd<=1'b0;
        usb_interpack<=1'b0;
        usb_timer<=18'd0;
        usb_state<= se0 ? USB_RSTTIME_1 :
                    usb_j ? USB_SPNDTIME :
                    usb_state;
        end
      USB_RSTTIME_1:
        begin
        usb_timer<= usb_timer+1'b1;
        usb_state<= (speed & usb_timer[7:0]==8'd240) |
                    (!speed & usb_timer[4:0]==5'd30) ? USB_RSTTIME_2 :
                    se0 ? usb_state :
                    USB_SELECT;
        end
      USB_RSTTIME_2:
        begin
        usb_rst<= se0 ? 1'b0 : 1'b1;
        usb_state<= se0 ? usb_state : USB_SELECT;
        end
      USB_SPNDTIME:
        begin
        usb_interpack <= usb_timer[2:0]==3'd5 ? 1'b1 : usb_interpack;
        usb_timer<= usb_timer+1'b1;
        usb_state<= (speed & usb_timer==18'd262143) | 
                    (!speed & usb_timer==18'd33330) ? USB_SPNDENTER :
                    usb_j & !dtx_oe ? usb_state :
                    USB_SELECT;
        end
      USB_SPNDENTER:
        begin
        usb_spnd<= usb_j ? 1'b1 : 1'b0;
        usb_state<= usb_j ? usb_state : USB_SELECT;
        end  
      endcase
      end
    end
endmodule
