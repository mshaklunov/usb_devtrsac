/*------------------------------------------------------------------------

Purpose

  Processing next standard requests on default pipe (endpoint 0):
  - SetAddress(). It is used for device address assigning. Request 
    don't pass to user.
  - SetConfiguration(). It is used for device configuration assigning,
    resetting toggle bits. Request pass to user. And it is successfull 
    when user reply with ACK.
  - ClearFeature(). It is used for resetting toggle bits. Request pass to 
    user. And it is successfull when user reply with ACK.
  Other requests must be solely processed by user.
  
------------------------------------------------------------------------*/
module usb_reqster (
                    input             clk,
                    input             rst0_async,
                    input             rst0_sync,
                    //STD REQUEST FIELDS
                    input[7:0]        bm_request_type,
                    input[7:0]        b_request,
                    input[15:0]       w_value,
                    input[15:0]       w_index,
                    //TRSAC 
                    input[1:0]        trsac_type,
                    input[3:0]        trsac_ep,
                    input[1:0]        trsac_reply_in,
                    input[1:0]        trsac_req_in,
                    output[1:0]       trsac_reply_out,
                    output[1:0]       trsac_req_out,
                    
                    output reg[6:0]   dev_addr,
                    output reg[7:0]   dev_configval,
                    output reg[15:0]  togglebit_rst
                    );
                    
  reg[6:0]      dev_addr_new;
  reg           status_setaddr;
  reg           switch;
  reg           reply;
  localparam    REPLY_ACK=2'd0,
                REPLY_NAK=2'd1,
                REPLY_STALL=2'd2;
  reg           req_hold;
  localparam    REQ_OK=2'd0,
                REQ_ACTIVE=2'd1,
                REQ_FAIL=2'd2;
  reg[1:0]      st_reqblock;
  localparam    IDLE_1=2'd0,
                SETADDR_SETUP=2'd1,
                SETADDR_STATUS=2'd2,
                BYPASS=2'd3;
  reg[3:0]      clearfeat_ep;
  reg[7:0]      dev_configval_new;
  reg[2:0]      st_reqpass;
  localparam    IDLE_2=3'd0,
                SETCONF_SETUP=3'd1,
                SETCONF_STATUS_1=3'd2,
                SETCONF_STATUS_2=3'd3,
                CLEARFEAT_SETUP=3'd4,
                CLEARFEAT_STATUS_1=3'd5,
                CLEARFEAT_STATUS_2=3'd6;
  localparam    TYPE_SETUP=2'd0,
                TYPE_OUT=2'd1,
                TYPE_IN=2'd2;

  assign  trsac_req_out= switch ? trsac_req_in : req_hold;
  assign  trsac_reply_out= switch ? trsac_reply_in : reply;
  
  //SetAddress() PROCESSING
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      dev_addr<=6'd0;
      dev_addr_new<=6'd0;
      status_setaddr<=1'b0;
      switch<=1'b0;
      reply<=1'b0;
      req_hold<=1'b0;
      st_reqblock<=IDLE_1;
      end
    else if(!rst0_sync)
      begin
      dev_addr<=6'd0;
      dev_addr_new<=6'd0;
      status_setaddr<=1'b0;
      switch<=1'b0;
      reply<=1'b0;
      req_hold<=1'b0;
      st_reqblock<=IDLE_1;
      end
    else
      begin
      case(st_reqblock)
      IDLE_1:
        begin
        switch<= 1'b0;
        status_setaddr<= trsac_req_in==REQ_ACTIVE & 
                         trsac_type==TYPE_SETUP &
                         trsac_ep==4'd0 ? 1'b0 : status_setaddr;
        st_reqblock<= trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_SETUP &
                      trsac_ep==4'd0 &
                      b_request==8'h5 ? SETADDR_SETUP :
                      
                      trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_IN &
                      trsac_ep==4'd0 &
                      status_setaddr ? SETADDR_STATUS :
                      
                      trsac_req_in==REQ_ACTIVE ? BYPASS :
                      st_reqblock;
        end
      SETADDR_SETUP:
        begin
        dev_addr_new<= w_value[6:0];
        status_setaddr<= trsac_req_in==REQ_OK ? 1'b1 : status_setaddr;
        reply<= REPLY_ACK;
        st_reqblock<= trsac_req_in!=REQ_ACTIVE ? IDLE_1 :
                      st_reqblock;
        end
      SETADDR_STATUS:
        begin
        dev_addr<= trsac_req_in==REQ_OK ? dev_addr_new : dev_addr;
        reply<= REPLY_ACK;
        st_reqblock<= trsac_req_in!=REQ_ACTIVE ? IDLE_1 : st_reqblock;
        end
      BYPASS:
        begin
        switch<= 1'b1;
        req_hold<= trsac_req_in;
        reply<= trsac_reply_in;
        st_reqblock<= trsac_req_in!=REQ_ACTIVE ? IDLE_1 : st_reqblock;
        end
      endcase
      end  
    end

  //SetConfiguratio(), ClearFeature() PROCESSING
  always @(posedge clk, negedge rst0_async)
    begin
    if(!rst0_async)
      begin
      dev_configval_new<=8'd0;
      dev_configval<=8'd0;
      togglebit_rst<=16'h0000;
      clearfeat_ep<=4'd0;
      st_reqpass<=IDLE_2;
      end
    else if(!rst0_sync)
      begin
      dev_configval_new<=8'd0;
      dev_configval<=8'd0;
      togglebit_rst<=16'h0000;
      clearfeat_ep<=4'd0;
      st_reqpass<=IDLE_2;
      end      
    else
      begin
      case(st_reqpass)
      IDLE_2:
        begin
        togglebit_rst<=16'h0000;
        st_reqpass<=  trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_SETUP &
                      trsac_ep==4'd0 &
                      bm_request_type==8'h00 &
                      b_request==8'h09 ? SETCONF_SETUP :
                      
                      trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_SETUP &
                      trsac_ep==4'd0 &
                      bm_request_type==8'h02 &
                      b_request==8'h01 &
                      w_value==16'h0000 ? CLEARFEAT_SETUP :
                      st_reqpass;
        end
      SETCONF_SETUP:
        begin
        dev_configval_new<= w_value[7:0];
        st_reqpass<= trsac_req_in==REQ_OK ? SETCONF_STATUS_1 :
                       trsac_req_in==REQ_FAIL ? IDLE_2 :
                       st_reqpass;
        end
      SETCONF_STATUS_1:
        begin
        st_reqpass<=  trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_IN &
                      trsac_ep==4'd0 ? SETCONF_STATUS_2 :
                      
                      trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_SETUP &
                      trsac_ep==4'd0 ? IDLE_2 :
                      
                      st_reqpass;
        end
      SETCONF_STATUS_2:
        begin
        dev_configval<= trsac_req_in==REQ_OK & 
                        trsac_reply_in==REPLY_ACK ? dev_configval_new :
                        dev_configval;
        togglebit_rst<= trsac_req_in==REQ_OK & 
                        trsac_reply_in==REPLY_ACK ? 16'hFFFE : 16'h0000;
        st_reqpass<= trsac_req_in!=REQ_ACTIVE ? IDLE_2 :
                       st_reqpass;
        end
      CLEARFEAT_SETUP:
        begin
        clearfeat_ep<= w_index[3:0];
        st_reqpass<= trsac_req_in==REQ_OK ? CLEARFEAT_STATUS_1 :
                     trsac_req_in==REQ_FAIL ? IDLE_2 :
                     st_reqpass;
        end
      CLEARFEAT_STATUS_1:
        begin
        st_reqpass<=  trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_IN &
                      trsac_ep==4'd0 ? CLEARFEAT_STATUS_2 :
                      
                      trsac_req_in==REQ_ACTIVE & 
                      trsac_type==TYPE_SETUP &
                      trsac_ep==4'd0 ? IDLE_2 :
                      
                      st_reqpass;
        end
      CLEARFEAT_STATUS_2:
        begin
        togglebit_rst[clearfeat_ep]<= trsac_req_in==REQ_OK & 
                                      trsac_reply_in==REPLY_ACK ? 1'b1 : 
                                      1'b0;
        st_reqpass<= trsac_req_in!=REQ_ACTIVE ? IDLE_2 :
                     st_reqpass;
        end
      endcase
      end  
    end
endmodule
