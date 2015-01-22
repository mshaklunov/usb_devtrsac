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
                    input          rdec_ok,
                    input          rdec_fail,
                    //ENCODER
                    input           encfifo_full,
                    input           dtx_oe,
                    output reg      trsac_encfifo_wr,
                    output          trsac_encfifo_wdata,
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
  reg         datapid_valid;
  wire        datapid_valid_comb;
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
  assign datapid_valid_comb= (toggle_bit[rdec_epaddr] & rdec_piddata1) |
                              (!toggle_bit[rdec_epaddr] & rdec_piddata0) |
                              (was_in[rdec_epaddr] & rdec_piddata1);
  assign trsac_encfifo_wdata= trsac_state==SETUPHSK_SYNC |
                          trsac_state==OUTHSK_SYNC |
                          trsac_state==INDATA_SYNC ? sync[counter] :

                          trsac_state==INDATA_CRC16 ? ~crc16[8'd15] :

                          (trsac_state==OUTHSK_PID |
                          trsac_state==INDATA_PID) &
                          trsac_reply==REPLY_NAK ? pid_nak[counter] :

                          (trsac_state==OUTHSK_PID |
                          trsac_state==INDATA_PID) &
                          trsac_reply==REPLY_STALL ? pid_stall[counter] :

                          trsac_state==INDATA_PID &
                          !ep_isoch[trsac_ep] &
                          (was_out[trsac_ep] |
                          toggle_bit[trsac_ep]) ? pid_data1[counter] :

                          trsac_state==INDATA_PID ? pid_data0[counter] :

                          (trsac_state==OUTHSK_PID |
                          trsac_state==SETUPHSK_PID) ? pid_ack[counter] :
                          1'b0;

  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      trsac_encfifo_wr<=1'b0;
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
      datapid_valid<=1'b0;
      trsac_state<=4'd0;
      end
    else if(!rst0_sync)
      begin
      trsac_encfifo_wr<=1'b0;
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
      datapid_valid<=1'b0;
      trsac_state<=4'd0;
      end
    else
      begin
      case(trsac_state)
      TOKEN:
        begin
        datapid_valid<=1'b0;
        counter<=8'd0;
        was_in[15:1]<= was_in[15:1] & ~togglebit_rst;
        was_out[15:1]<= was_out[15:1] & ~togglebit_rst;
        toggle_bit[15:1]<= toggle_bit[15:1] & ~togglebit_rst;
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
        trsac_type<= rdec_piddata0 ? TYPE_SETUP : trsac_type;
        trsac_ep<= rdec_piddata0 ? rdec_epaddr : trsac_ep;
        trsac_req<= rdec_piddata0 ? REQ_ACTIVE : trsac_req;
        datapid_valid<= rdec_piddata0 ? 1'b1 : datapid_valid;
        trsac_state<= rdec_ok & datapid_valid ? SETUPHSK_SYNC :
                      (rdec_ok & !datapid_valid) | rdec_fail ? TRSAC_FAIL:
                      trsac_state;
        end
      SETUPHSK_SYNC:
        begin
        was_setup[trsac_ep]<= 1'b1;
        was_in[trsac_ep]<=1'b0;
        was_out[trsac_ep]<=1'b0;
        trsac_encfifo_wr<= counter==8'd7 & !encfifo_full &
                           trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? SETUPHSK_PID :
                      trsac_state;
        end
      SETUPHSK_PID:
        begin
        toggle_bit[trsac_ep]<=1'b1;
        trsac_encfifo_wr<=  counter==8'd7 & !encfifo_full &
                            trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? TRSAC_OK :
                      trsac_state;
        end
      OUTDATA:
        begin
        trsac_type<= datapid_valid_comb ? TYPE_OUT : trsac_type;
        trsac_ep<= datapid_valid_comb ? rdec_epaddr : trsac_ep;
        trsac_req<= datapid_valid_comb ? REQ_ACTIVE : trsac_req;
        datapid_valid<= datapid_valid_comb ? 1'b1 : datapid_valid;
        trsac_state<= ep_isoch[trsac_ep] & rdec_ok ? OUTHSK_NONE :
                      ep_isoch[trsac_ep] & rdec_fail ? TRSAC_FAIL :
                      rdec_ok |
                      (rdec_fail & trsac_reply==REPLY_NAK) |
                      (rdec_fail & trsac_reply==REPLY_STALL) ?OUTHSK_SYNC:
                      rdec_fail ? TRSAC_FAIL :
                      trsac_state;
        end
      OUTHSK_NONE:
        begin
        counter<= counter+1'b1;
        trsac_state<= counter==8'd34 ? TRSAC_OK : trsac_state;
        end
      OUTHSK_SYNC:
        begin
        was_setup[trsac_ep]<=1'b0;
        was_out[trsac_ep]<= was_setup[trsac_ep] ? 1'b1 :
                            was_out[trsac_ep];
        trsac_encfifo_wr<= counter==8'd7 & !encfifo_full &
                           trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? OUTHSK_PID :
                      trsac_state;
        end
      OUTHSK_PID:
        begin
        toggle_bit[trsac_ep]<= trsac_reply==REPLY_ACK &
                               counter==8'd7 & !encfifo_full &
                               trsac_encfifo_wr &
                               datapid_valid? ~toggle_bit[trsac_ep]:
                               toggle_bit[trsac_ep];
        trsac_encfifo_wr<=  counter==8'd7 & !encfifo_full &
                            trsac_encfifo_wr ? 1'b0 :
                            !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? TRSAC_OK :
                      trsac_state;
        end
      INDATA_SYNC:
        begin
        datapid_valid<=1'b1;
        trsac_type<= TYPE_IN;
        trsac_ep<= rdec_epaddr;
        trsac_req<= REQ_ACTIVE;
        trsac_encfifo_wr<= counter==8'd7 & !encfifo_full &
                           trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? INDATA_PID :
                      trsac_state;
        end
      INDATA_PID:
        begin
        was_setup[trsac_ep]<=1'b0;
        was_in[trsac_ep]<= was_setup[trsac_ep] ? 1'b1 :
                           was_in[trsac_ep];
        crc16<= 16'hFFFF;
        trsac_encfifo_wr<= counter==8'd7 & !encfifo_full &
                           trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        counter<= counter==8'd7 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr &
                      trsac_reply==REPLY_ACK ? INDATA_DATA :
                      counter==8'd7 & !encfifo_full &
                      trsac_encfifo_wr ? TRSAC_OK :
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
        trsac_encfifo_wr<= counter==8'd15 & !encfifo_full &
                           trsac_encfifo_wr ? 1'b0 :
                           !encfifo_full ? 1'b1 : 1'b0;
        crc16<= trsac_encfifo_wr & !encfifo_full ? {crc16[14:0],1'b0} :
                crc16;
        counter<= counter==8'd15 & !encfifo_full &
                  trsac_encfifo_wr ? 8'd0 :
                  trsac_encfifo_wr & !encfifo_full ? counter+1'b1 :
                  counter;
        trsac_state<= counter==8'd15 & !encfifo_full &
                      trsac_encfifo_wr &
                      !ep_isoch[trsac_ep] ? INHSK :
                      counter==8'd15 & !encfifo_full &
                      trsac_encfifo_wr ? TRSAC_OK :
                      trsac_state;
        end
      INHSK:
        begin
        counter<= !dtx_oe ? counter+1'b1 : counter;
        toggle_bit[trsac_ep]<= ep_intnoretry[trsac_ep] |
                                  rdec_pidack ? ~toggle_bit[trsac_ep] :
                                  toggle_bit[trsac_ep];
        trsac_state<=counter==(5'd16*3'd4+5'd17*3'd4) ? TRSAC_FAIL :
                     rdec_pidack | ep_intnoretry[trsac_ep] ? TRSAC_OK :
                     trsac_state;
        end
      TRSAC_OK:
        begin
        trsac_req<= datapid_valid ? REQ_OK : trsac_req;
        trsac_state<= TOKEN;
        end
      TRSAC_FAIL:
        begin
        trsac_req<= REQ_FAIL;
        trsac_state<= TOKEN;
        end
      default:
        begin
        trsac_encfifo_wr<=1'b0;
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
        datapid_valid<=1'b0;
        trsac_state<=4'd0;
        end
      endcase
      end
    end
endmodule
