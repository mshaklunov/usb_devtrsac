/*------------------------------------------------------------------------

Purpose

  - Data serializing;
  - bit staffing;
  - nrzi encoding;
  - remote wakeup signaling.

------------------------------------------------------------------------*/
module usb_encoder  (
                    input       clk,
                    input       rst0_async,
                    input       rst0_sync,
                    //USB
                    output reg  dtx_plus,
                    output reg  dtx_minus,
                    output reg  dtx_oe,
                    //DECODER
                    input       usb_interpack,
                    //ENCFIFO
                    input       encfifo_wr,
                    input       encfifo_wdata,
                    output      encfifo_full,

                    input       remote_wakeup,
                    input       speed
                    );

  wire              usb_j;
  wire              usb_k;
  wire              encfifo_empty;
  reg               encfifo_rd;
  wire              encfifo_rdata;
  reg[17:0]         counter;
  reg[2:0]          stuffbit;
  reg[3:0]          enc_state;
  localparam        ENC_IDLE=4'd0,
                    ENC_TIME1=4'd1,
                    ENC_DRIVE=4'd2,
                    ENC_STUFF=4'd3,
                    ENC_SE0=4'd4,
                    ENC_TIME2=4'd5,
                    ENC_DRIVEJ=4'd6,
                    ENC_TIME3=4'd7,
                    ENC_DRIVEK=4'd8;

  usb_fifo_sync #(.ADDR_WIDTH(1'd1),.WDATA_WIDTH(1'd0),.RDATA_WIDTH(1'd0))
      i_encfifo
                 (
                 .clk(clk),
                 .rst0_async(rst0_async),
                 .rst0_sync(rst0_sync),

                 .wr_en(encfifo_wr),
                 .wr_data(encfifo_wdata),

                 .rd_en(encfifo_rd),
                 .rd_data(encfifo_rdata),

                 .fifo_full(encfifo_full),
                 .fifo_empty(encfifo_empty)
                 );

  assign  usb_j= speed ? 1'b1 : 1'b0;
  assign  usb_k= speed ? 1'b0 : 1'b1;
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      dtx_plus<=1'b1;
      dtx_minus<=1'b0;
      dtx_oe<=1'b0;
      encfifo_rd<=1'b0;
      counter<=18'd0;
      stuffbit<=3'd0;
      enc_state<=ENC_IDLE;
      end
    else if(!rst0_sync)
      begin
      dtx_plus<=1'b1;
      dtx_minus<=1'b0;
      dtx_oe<=1'b0;
      encfifo_rd<=1'b0;
      counter<=18'd0;
      stuffbit<=3'd0;
      enc_state<=ENC_IDLE;
      end
    else
      begin
      case(enc_state)
      ENC_IDLE:
        begin
        stuffbit<=3'd0;
        counter<=18'd0;
        encfifo_rd<=1'b0;
        dtx_plus<= usb_j;
        dtx_minus<= ~usb_j;
        dtx_oe<=  (!encfifo_empty & usb_interpack) |
                  remote_wakeup ? 1'b1 : 1'b0;
        enc_state<= remote_wakeup ? ENC_DRIVEK :
                    !encfifo_empty & usb_interpack ? ENC_TIME1 :
                    enc_state;
        end
      ENC_TIME1:
        begin
        counter<= counter+1'b1;
        encfifo_rd<= counter==18'd2 & stuffbit!=3'd6 &
                     !encfifo_empty ? 1'b1 :
                     1'b0;
        enc_state<= counter==18'd2 & stuffbit==3'd6 ? ENC_STUFF :
                    counter==18'd2 & encfifo_empty ? ENC_SE0 :
                    counter==18'd2 ? ENC_DRIVE :
                    enc_state;
        end
      ENC_DRIVE:
        begin
        counter<=18'd0;
        encfifo_rd<=1'b0;
        stuffbit<= encfifo_rdata ? stuffbit+1'b1 : 3'd0;
        dtx_plus<= encfifo_rdata ? dtx_plus : ~dtx_plus;
        dtx_minus<= encfifo_rdata ? ~dtx_plus : dtx_plus;
        enc_state<= ENC_TIME1;
        end
      ENC_STUFF:
        begin
        counter<=18'd0;
        stuffbit<=3'd0;
        dtx_plus<= ~dtx_plus;
        dtx_minus<= dtx_plus;
        enc_state<= ENC_TIME1;
        end
      ENC_SE0:
        begin
        counter<=18'd0;
        dtx_plus<=1'b0;
        dtx_minus<=1'b0;
        enc_state<= ENC_TIME2;
        end
      ENC_TIME2:
        begin
        counter<= counter+1'b1;
        enc_state<= counter==18'd6 ? ENC_DRIVEJ :
                    enc_state;
        end
      ENC_DRIVEJ:
        begin
        counter<=18'd0;
        dtx_plus<= usb_j;
        dtx_minus<= ~usb_j;
        enc_state<= ENC_TIME3;
        end
      ENC_TIME3:
        begin
        counter<= counter+1'b1;
        enc_state<= counter==18'd2 ? ENC_IDLE :
                    enc_state;
        end
      ENC_DRIVEK:
        begin
        counter<= counter+1'b1;
        dtx_plus<= usb_k;
        dtx_minus<= ~usb_k;
        //REMOTE WAKEUP SIGNALING:
        //                        ~145000 CYCLES ~2,9ms (FULL SPEED)
        //                        ~18000 CYCLES ~3ms (LOW SPEED)
        enc_state<= (speed & counter==18'd145000) |
                    (!speed & counter==18'd18000) ? ENC_IDLE : enc_state;
        end
      default:
        begin
        dtx_plus<=1'b1;
        dtx_minus<=1'b0;
        dtx_oe<=1'b0;
        encfifo_rd<=1'b0;
        counter<=18'd0;
        stuffbit<=3'd0;
        enc_state<=ENC_IDLE;
        end
      endcase
      end
    end
endmodule
