/*------------------------------------------------------------------------

1 Purpose

  Transactions control, toggle bits control.

2 Transaction IN control

  - Receive TOKEN packet;
  - request to user and wait reply from user;
  - send DATA packet;
  - wait HANDSHAKE packet from USB host (for not isochronous endpoints);
  - status transaction.

3 Transaction OUT/SETUP control  

  - Receive TOKEN packet;
  - receive DATA packet;
  - request to user and wait reply from user;
  - send HANDSHAKE packet to USB host (for not isochronous endpoints);
  - status transaction.
  
------------------------------------------------------------------------*/
module usb_trsacner (
                    input           clk,
                    input           rst0_async,
                    input           rst0_sync,
                    //DECODER
                    input[3:0]      rdec_epaddr,
                    input           rdec_pidin,
                    input           rdec_pidout,
                    input           rdec_pidsetup,
                    input           rdec_piddata0,
                    input           rdec_piddata1,
                    input           rdec_pidack,
                    //ENCODER   
                    input           encfifo_full,
                    input           dtx_oe,
                    output reg      trsac_encfifo_wr,
                    output reg      trsac_encfifo_wdata,
                    output          trsac_tfifoenc_en,
                    //TFIFO   
                    input           tfifo_empty,
                    input           tfifo_rdata,
                    //TRSAC
                    input[1:0]      trsac_reply,
                    output reg[1:0] trsac_req,
                    output reg[1:0] trsac_type,
                    output reg[3:0] trsac_ep,
                    
                    input[15:0]     ep_isoch,
                    input[15:0]     ep_intnoretry,
                    
                    input[15:1]     togglebit_rst,
                    input[2:0]      device_state
                    );
                    
  reg[15:0]   was_setup;      
  reg[15:0]   was_out;
  reg[15:0]   was_in;
  reg[15:0]   toggle_bit;
  reg[15:0]   crc16;
  reg[7:0]    counter;
  reg         lastbit;
  reg         datapid;
  reg[3:0]    trsac_state;
  localparam  TOKEN=4'd0,
              //SETUP
              SETUPDATA=4'd1,
              SETUPHSK_SYNC=4'd2,
              SETUPHSK_PID=4'd3,
              //OUT
              OUTDATA=4'd4,
              OUTHSK_SYNC=4'd5,
              OUTHSK_PID=4'd6,
              OUTHSK_NONE=4'd7,              
              //IN
              INDATA_SYNC=4'd8,
              INDATA_PID=4'd9,
              INDATA_DATA=4'd10,
              INDATA_CRC16=4'd11,
              INHSK=4'd12,
              //STATUS
              TRSAC_OK=4'd13,
              TRSAC_FAIL=4'd14;
  localparam  PID_IN=4'b1001,
              PID_OUT=4'b0001,
              PID_SOF=4'b0101,
              PID_SETUP=4'b1101,
              PID_DATA0=4'b0011,
              PID_DATA1=4'b1011,
              PID_ACK=4'b0010,
              PID_NAK=4'b1010,
              PID_STALL=4'b1110;        
  wire[7:0]   sync;
  wire[7:0]   pid_ack;
  wire[7:0]   pid_nak;
  wire[7:0]   pid_stall;
  wire[7:0]   pid_data1;
  wire[7:0]   pid_data0;
  localparam  REQ_OK=2'd0,
              REQ_ACTIVE=2'd1,
              REQ_FAIL=2'd2;
  localparam  TYPE_SETUP=2'd0,
              TYPE_OUT=2'd1,
              TYPE_IN=2'd2;
  localparam  REPLY_ACK=2'd0,
              REPLY_NAK=2'd1,
              REPLY_STALL=2'd2;

  assign sync=8'b1000_0000;
  assign pid_ack= {~PID_ACK,PID_ACK};
  assign pid_nak= {~PID_NAK,PID_NAK};
  assign pid_stall= {~PID_STALL,PID_STALL};
  assign pid_data1= {~PID_DATA1,PID_DATA1};
  assign pid_data0= {~PID_DATA0,PID_DATA0};
  assign trsac_tfifoenc_en= trsac_state==INDATA_DATA;
  
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      trsac_encfifo_wr<=1'b0;
      trsac_encfifo_wdata<=1'b0;
      trsac_req<=REQ_OK;
      trsac_type<=2'd0;
      trsac_ep<=4'd0;
      was_setup<=16'd0;
      was_out<=16'd0;
      was_in<=16'd0;
      toggle_bit<=16'd0;
      crc16<=16'hFFFF;
      counter<=8'd0;
      lastbit<=1'b0;
      datapid<=1'b1;
      trsac_state<=4'd0;
      end
    else if(!rst0_sync)
      begin
      trsac_encfifo_wr<=1'b0;
      trsac_encfifo_wdata<=1'b0;
      trsac_req<=REQ_OK;
      trsac_type<=2'd0;
      trsac_ep<=4'd0;
      was_setup<=16'd0;
      was_out<=16'd0;
      was_in<=16'd0;
      toggle_bit<=16'd0;
      crc16<=16'hFFFF;
      counter<=8'd0;
      lastbit<=1'b0;
      datapid<=1'b1;
      trsac_state<=4'd0;
      end      
    else
      begin
      case(trsac_state)
      TOKEN:
        begin
        datapid<=1'b1;
        counter<=8'd0;
        toggle_bit[1]<= togglebit_rst[1] ? 1'b0 : toggle_bit[1];
        toggle_bit[2]<= togglebit_rst[2] ? 1'b0 : toggle_bit[2];
        toggle_bit[3]<= togglebit_rst[3] ? 1'b0 : toggle_bit[3];
        toggle_bit[4]<= togglebit_rst[4] ? 1'b0 : toggle_bit[4];
        toggle_bit[5]<= togglebit_rst[5] ? 1'b0 : toggle_bit[5];
        toggle_bit[6]<= togglebit_rst[6] ? 1'b0 : toggle_bit[6];
        toggle_bit[7]<= togglebit_rst[7] ? 1'b0 : toggle_bit[7];
        toggle_bit[8]<= togglebit_rst[8] ? 1'b0 : toggle_bit[8];
        toggle_bit[9]<= togglebit_rst[9] ? 1'b0 : toggle_bit[9];
        toggle_bit[10]<= togglebit_rst[10] ? 1'b0 : toggle_bit[10];
        toggle_bit[11]<= togglebit_rst[11] ? 1'b0 : toggle_bit[11];
        toggle_bit[12]<= togglebit_rst[12] ? 1'b0 : toggle_bit[12];
        toggle_bit[13]<= togglebit_rst[13] ? 1'b0 : toggle_bit[13];
        toggle_bit[14]<= togglebit_rst[14] ? 1'b0 : toggle_bit[14];
        toggle_bit[15]<= togglebit_rst[15] ? 1'b0 : toggle_bit[15];
        trsac_state<= device_state==4'd0 | 
                      (device_state==4'd1 & 
                       rdec_epaddr!=4'd0) |
                      (device_state==4'd2 & 
                       rdec_epaddr!=4'd0) ? trsac_state :
                      rdec_pidin ? INDATA_SYNC :
                      rdec_pidout ? OUTDATA :
                      rdec_pidsetup ? SETUPDATA :
                      trsac_state;
        end
      SETUPDATA:
        begin
        was_setup[rdec_epaddr]<=1'b1;
        was_in[rdec_epaddr]<=1'b0;
        was_out[rdec_epaddr]<=1'b0;
        trsac_state<= rdec_piddata0 ? SETUPHSK_SYNC : trsac_state;
        end
      SETUPHSK_SYNC:
        begin
        trsac_type<= TYPE_SETUP;
        trsac_ep<= rdec_epaddr;
        trsac_req<= REQ_ACTIVE;
        trsac_encfifo_wr<= lastbit & trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        trsac_encfifo_wdata<= !encfifo_full ? sync[counter] : 
                              trsac_encfifo_wdata;
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd7 ? counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr ? SETUPHSK_PID :
                      trsac_state;
        end  
      SETUPHSK_PID:
        begin
        toggle_bit[rdec_epaddr]<=1'b1;
        trsac_encfifo_wr<=  lastbit & trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;    
        trsac_encfifo_wdata<= !encfifo_full ? pid_ack[counter] : 
                              trsac_encfifo_wdata;
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd7 ? counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr ? TRSAC_OK : trsac_state;
        end
      OUTDATA:
        begin
        was_setup[rdec_epaddr]<=1'b0;
        was_out[rdec_epaddr]<=  was_setup[rdec_epaddr] ? 1'b1 : 
                                was_out[rdec_epaddr];
        datapid<= (toggle_bit[rdec_epaddr] & rdec_piddata1) | 
                  (!toggle_bit[rdec_epaddr] & rdec_piddata0) |
                  (was_in[rdec_epaddr] & rdec_piddata1);
        trsac_state<= ep_isoch[rdec_epaddr] & 
                      (rdec_piddata1 | rdec_piddata0) ? OUTHSK_NONE :
                      (was_in[rdec_epaddr] & rdec_piddata1) |
                      (rdec_piddata1) | 
                      (rdec_piddata0) ? OUTHSK_SYNC :
                      trsac_state;
        end
      OUTHSK_NONE:
        begin
        trsac_type<= TYPE_OUT;
        trsac_ep<= rdec_epaddr;
        trsac_req<= REQ_ACTIVE;
        counter<= counter+1'b1;
        trsac_state<= counter==8'd34 ? TRSAC_OK : trsac_state;
        end        
      OUTHSK_SYNC:
        begin
        trsac_type<= datapid ? TYPE_OUT : trsac_type;
        trsac_ep<= datapid ? rdec_epaddr : trsac_ep;
        trsac_req<= datapid ? REQ_ACTIVE : trsac_req;
        trsac_encfifo_wr<=  lastbit & trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;    
        trsac_encfifo_wdata<= !encfifo_full ? sync[counter] : 
                              trsac_encfifo_wdata;
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & counter!=8'd7 ? 
                  counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr ? OUTHSK_PID : 
                      trsac_state;
        end
      OUTHSK_PID:
        begin
        toggle_bit[rdec_epaddr]<= trsac_reply==REPLY_ACK & 
                                  lastbit & trsac_encfifo_wr & 
                                  datapid ? ~toggle_bit[rdec_epaddr] : 
                                  toggle_bit[rdec_epaddr];
        trsac_encfifo_wr<=  lastbit & trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;    
        trsac_encfifo_wdata<= encfifo_full ? trsac_encfifo_wdata :
        
                              trsac_reply==REPLY_NAK & 
                              datapid ? pid_nak[counter] :
                              
                              trsac_reply==REPLY_STALL & 
                              datapid ? pid_stall[counter] :
                              
                              pid_ack[counter];
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd7 ? counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr ? TRSAC_OK : trsac_state;
        end
      INDATA_SYNC:
        begin
        trsac_type<= TYPE_IN;
        trsac_ep<= rdec_epaddr;
        trsac_req<= REQ_ACTIVE;
        trsac_encfifo_wr<=  lastbit & trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;    
        trsac_encfifo_wdata<= !encfifo_full ? sync[counter] : 
                              trsac_encfifo_wdata;
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd7 ? counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr ? INDATA_PID : 
                      trsac_state;
        end
      INDATA_PID:
        begin
        was_setup[rdec_epaddr]<=1'b0;
        was_in[rdec_epaddr]<= was_setup[rdec_epaddr] ? 1'b1 : 
                              was_in[rdec_epaddr];
        crc16<= 16'hFFFF;
        trsac_encfifo_wr<= lastbit & trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        trsac_encfifo_wdata<= encfifo_full ? trsac_encfifo_wdata :
                            trsac_reply==REPLY_NAK ? pid_nak[counter] :
                            trsac_reply==REPLY_STALL ? pid_stall[counter]:
                            ep_isoch[rdec_epaddr] ? pid_data0[counter]:
                            was_out[rdec_epaddr] | 
                            toggle_bit[rdec_epaddr] ? pid_data1[counter] : 
                            pid_data0[counter];
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd7 ? counter+1'b1 : counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd7 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr & 
                      trsac_reply==REPLY_ACK ? INDATA_DATA :
                      lastbit & trsac_encfifo_wr ? TRSAC_OK :
                      trsac_state;
        end
      INDATA_DATA:
        begin
        trsac_encfifo_wr<=  tfifo_empty ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;
        crc16<= trsac_encfifo_wr & !encfifo_full &
                (crc16[15]^tfifo_rdata) ? 
                {crc16[14:0],1'b0}^16'h8005 :
                trsac_encfifo_wr & !encfifo_full ? {crc16[14:0],1'b0} :
                crc16;
        trsac_state<= tfifo_empty ? INDATA_CRC16 : trsac_state;
        end
      INDATA_CRC16:
        begin
        trsac_encfifo_wr<=  lastbit & trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;
        trsac_encfifo_wdata<= !encfifo_full ? ~crc16[4'd15-counter] : 
                              trsac_encfifo_wdata;
        counter<= lastbit & trsac_encfifo_wr ? 8'd0 : 
                  trsac_encfifo_wr & !encfifo_full & 
                  counter!=8'd15 ? counter+1'b1 : 
                  counter;
        lastbit<= lastbit & trsac_encfifo_wr ? 1'b0 :
                  counter==8'd15 ? 1'b1 : 1'b0;
        trsac_state<= lastbit & trsac_encfifo_wr &
                      ep_isoch[rdec_epaddr] ? TRSAC_OK :
                      lastbit & trsac_encfifo_wr ? INHSK : trsac_state;
        end
      INHSK:
        begin
        counter<= !dtx_oe ? counter+1'b1 : counter;
        toggle_bit[rdec_epaddr]<= ep_intnoretry[rdec_epaddr] |
                                  rdec_pidack ? ~toggle_bit[rdec_epaddr] :
                                  toggle_bit[rdec_epaddr];
        trsac_state<=counter==(5'd16*3'd4+5'd17*3'd4) ? TRSAC_FAIL :
                     rdec_pidack | ep_intnoretry[rdec_epaddr] ? TRSAC_OK : 
                     trsac_state;
        end
      TRSAC_OK:
        begin
        trsac_req<= datapid ? REQ_OK : trsac_req;
        trsac_state<= TOKEN;
        end
      TRSAC_FAIL:
        begin
        trsac_req<= REQ_FAIL;
        trsac_state<= TOKEN;
        end  
      endcase
      end
    end
endmodule
