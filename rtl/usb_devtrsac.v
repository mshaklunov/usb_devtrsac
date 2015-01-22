/*------------------------------------------------------------------------

Purpose

  Top module. USB device realization up to transaction level.

------------------------------------------------------------------------*/
module usb_devtrsac (
                    input             clk_4xrate,
                    input             rst0_async,
                    input             rst0_sync,
                    //USB TRANSCEIVER
                    input             drx_plus,
                    input             drx_minus,
                    input             drx,
                    output            dtx_plus,
                    output            dtx_minus,
                    output            dtx_oe,
                    //TRANSACTION
                    output[1:0]       trsac_type,
                    output[3:0]       trsac_ep,
                    output[1:0]       trsac_req,
                    input[1:0]        trsac_reply,
                    //RFIFO
                    input             rfifo_rd,
                    output            rfifo_empty,
                    output[7:0]       rfifo_rdata,
                    //TFIFO
                    input             tfifo_wr,
                    output            tfifo_full,
                    input[7:0]        tfifo_wdata,
                    //EP
                    input[15:1]       ep_enable,
                    input[15:1]       ep_isoch,
                    input[15:1]       ep_intnoretry,
                    //SOF
                    output            sof_tick,
                    output[10:0]      sof_value,
                    //DEVICE
                    input             device_speed,
                    input             device_wakeup,
                    input             device_addr_wr,
                    input[6:0]        device_addr,
                    input             device_config_wr,
                    input[7:0]        device_config,
                    output reg[2:0]   device_state
                    );

  wire          usb_rst;
  wire          usb_spnd;
  wire          usb_interpack;
  //PACKET
  wire[3:0]     rdec_epaddr;
  wire          rdec_pidin;
  wire          rdec_pidout;
  wire          rdec_pidsetup;
  wire          rdec_piddata0;
  wire          rdec_piddata1;
  wire          rdec_pidack;
  wire          rdec_ok;
  wire          rdec_fail;
  //RFIFO
  wire          rfifo_full;
  wire          rdec_rfifo_wr;
  wire          rextr_data;
  wire          rdec_rfifo_rst0;
  //TFIFO
  wire          tfifo_empty;
  wire          tfifo_rdata;
  //ENCFIFO
  wire          encfifo_wr;
  wire          encfifo_wdata;
  wire          encfifo_full;
  //TRSAC
  wire          trsac_encfifo_wr;
  wire          trsac_encfifo_wdata;
  wire          trsac_tfifoenc_en;
  wire[15:0]    togglebit_rst;
  //DEVICE STATE
  reg[6:0]      devaddr_hold;
  reg[7:0]      devconf_hold;
  localparam    DEVICE_POWERED=3'd0,
                DEVICE_DEFAULT=3'd1,
                DEVICE_ADDRESSED=3'd2,
                DEVICE_CONFIGURED=3'd3,
                DEVICE_SPND_PWR=3'd4,
                DEVICE_SPND_DFT=3'd5,
                DEVICE_SPND_ADDR=3'd6,
                DEVICE_SPND_CONF=3'd7;

  usb_decoder
    i_decoder     (
                  .clk(clk_4xrate),
                  .rst0_async(rst0_async),
                  .rst0_sync(rst0_sync & !usb_rst),
                  //USB TRANSCEIVER
                  .drx_plus(dtx_oe ? device_speed : drx_plus),
                  .drx_minus(dtx_oe ? ~device_speed : drx_minus),
                  .drx(dtx_oe ? device_speed : drx),

                  .dtx_oe(dtx_oe),
                  //USB LINES STATE
                  .usb_rst(usb_rst),
                  .usb_spnd(usb_spnd),
                  .usb_interpack(usb_interpack),
                  //PACKET
                  .dev_addr(devaddr_hold),
                  .ep_enable({ep_enable,1'b1}),
                  .rdec_epaddr(rdec_epaddr),
                  .rdec_pidin(rdec_pidin),
                  .rdec_pidout(rdec_pidout),
                  .rdec_pidsetup(rdec_pidsetup),
                  .rdec_piddata0(rdec_piddata0),
                  .rdec_piddata1(rdec_piddata1),
                  .rdec_pidack(rdec_pidack),
                  .rdec_ok(rdec_ok),
                  .rdec_fail(rdec_fail),
                  //SOF
                  .sof_tick(sof_tick),
                  .sof_value(sof_value),
                  //RFIFO
                  .rfifo_full(rfifo_full),
                  .rdec_rfifo_wr(rdec_rfifo_wr),
                  .rextr_data(rextr_data),
                  .rdec_rfifo_rst0(rdec_rfifo_rst0),

                  .speed(device_speed)
                  );

  usb_encoder
    i_encoder     (
                  .clk(clk_4xrate),
                  .rst0_async(rst0_async),
                  .rst0_sync(rst0_sync & !usb_rst),
                  //USB
                  .dtx_plus(dtx_plus),
                  .dtx_minus(dtx_minus),
                  .dtx_oe(dtx_oe),
                  //DECODER
                  .usb_interpack(usb_interpack),
                  //ENCFIFO
                  .encfifo_wr(trsac_encfifo_wr),
                  .encfifo_wdata(encfifo_wdata),
                  .encfifo_full(encfifo_full),

                  .remote_wakeup(device_wakeup & device_state[2]),
                  .speed(device_speed)
                  );

  usb_trsacner
    i_trsacner    (
                  .clk(clk_4xrate),
                  .rst0_async(rst0_async),
                  .rst0_sync(rst0_sync & !usb_rst),
                  //DECODER
                  .rdec_epaddr(rdec_epaddr),
                  .rdec_pidin(rdec_pidin),
                  .rdec_pidout(rdec_pidout),
                  .rdec_pidsetup(rdec_pidsetup),
                  .rdec_piddata0(rdec_piddata0),
                  .rdec_piddata1(rdec_piddata1),
                  .rdec_pidack(rdec_pidack),
                  .rdec_ok(rdec_ok),
                  .rdec_fail(rdec_fail),
                  //ENCODER
                  .encfifo_full(encfifo_full),
                  .dtx_oe(dtx_oe),
                  .trsac_encfifo_wr(trsac_encfifo_wr),
                  .trsac_encfifo_wdata(trsac_encfifo_wdata),
                  .trsac_tfifoenc_en(trsac_tfifoenc_en),
                  //TFIFO
                  .tfifo_empty(tfifo_empty),
                  .tfifo_rdata(tfifo_rdata),
                  //TRSAC
                  .trsac_reply(trsac_reply),
                  .trsac_req(trsac_req),
                  .trsac_type(trsac_type),
                  .trsac_ep(trsac_ep),
                  .ep_isoch({ep_isoch,1'b0}),
                  .ep_intnoretry({ep_intnoretry,1'b0}),

                  .togglebit_rst(~ep_enable[15:1]),
                  .device_state(device_state)
                  );

  usb_fifo_rcv  #(.ADDR_WIDTH(3'd5),.WDATA_WIDTH(1'd0),.RDATA_WIDTH(2'd3))
       i_rfifo
                (
                .clk(clk_4xrate),
                .rst0_async(rst0_async),
                .rst0_sync(rdec_rfifo_rst0 & !usb_rst),

                .wr_en(rdec_rfifo_wr),
                .wr_data(rextr_data),

                .rd_en(rfifo_rd),
                .rd_data(rfifo_rdata),

                .fifo_full(rfifo_full),
                .fifo_empty(rfifo_empty)
                );

  usb_fifo_sync #(.ADDR_WIDTH(3'd4),.WDATA_WIDTH(2'd3),.RDATA_WIDTH(1'd0))
        i_tfifo
                 (
                 .clk(clk_4xrate),
                 .rst0_async(rst0_async),
                 .rst0_sync(!usb_rst),

                 .wr_en(tfifo_wr),
                 .wr_data(tfifo_wdata),

                 .rd_en( trsac_encfifo_wr & !encfifo_full &
                         trsac_tfifoenc_en),
                 .rd_data(tfifo_rdata),

                 .fifo_full(tfifo_full),
                 .fifo_empty(tfifo_empty)
                 );

  assign encfifo_wdata= trsac_tfifoenc_en ? tfifo_rdata :
                        trsac_encfifo_wdata;

  //DEVICE STATE
  always @(posedge clk_4xrate, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      devaddr_hold<=7'd0;
      devconf_hold<=8'd0;
      device_state<=DEVICE_POWERED;
      end
    else if(!rst0_sync)
      begin
      devaddr_hold<=7'd0;
      devconf_hold<=8'd0;
      device_state<=DEVICE_POWERED;
      end
    else
      begin
      devaddr_hold<= usb_rst ? 7'd0 :
                     device_addr_wr ? device_addr :
                     devaddr_hold;
      devconf_hold<= usb_rst ? 8'd0 :
                     device_config_wr ? device_config :
                     devconf_hold;

      case(device_state)
      DEVICE_POWERED:
        begin
        device_state<= usb_rst ? DEVICE_DEFAULT :
                       usb_spnd ? DEVICE_SPND_PWR :
                       device_state;
        end
      DEVICE_DEFAULT:
        begin
        device_state<= devaddr_hold!=0 ? DEVICE_ADDRESSED :
                       usb_spnd ? DEVICE_SPND_DFT :
                       device_state;
        end
      DEVICE_ADDRESSED:
        begin
        device_state<= usb_rst | devaddr_hold==7'd0 ? DEVICE_DEFAULT :
                       devconf_hold!=0 ? DEVICE_CONFIGURED :
                       usb_spnd ? DEVICE_SPND_ADDR :
                       device_state;
        end
      DEVICE_CONFIGURED:
        begin
        device_state<= usb_rst ? DEVICE_DEFAULT :
                       usb_spnd ? DEVICE_SPND_CONF :
                       devconf_hold==8'd0 ? DEVICE_ADDRESSED :
                       device_state;
        end
      DEVICE_SPND_PWR:
        begin
        device_state<= !usb_spnd ? DEVICE_POWERED : device_state;
        end
      DEVICE_SPND_DFT:
        begin
        device_state<= !usb_spnd ? DEVICE_DEFAULT : device_state;
        end
      DEVICE_SPND_ADDR:
        begin
        device_state<= !usb_spnd ? DEVICE_ADDRESSED : device_state;
        end
      DEVICE_SPND_CONF:
        begin
        device_state<= !usb_spnd ? DEVICE_CONFIGURED : device_state;
        end
      endcase
      end
    end
endmodule
