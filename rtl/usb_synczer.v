/*------------------------------------------------------------------------

Purpose
  
  Data synchronizing between asynchronous domains

------------------------------------------------------------------------*/
module usb_synczer #(parameter DATA_WIDTH=1, parameter DATA_ONRST=0)
                        (
                        input           reset0_async,
                        input           reset0_sync,
                        input           clock,
                        input[2:0]      datain_async,
                        output reg[2:0] dataout_sync
                        );
  
  reg [DATA_WIDTH-1:0] data_sync;

  always @(posedge clock, negedge reset0_async)
    if(!reset0_async) 
      {dataout_sync,data_sync}<={DATA_ONRST,DATA_ONRST};
    else if(!reset0_sync) 
      {dataout_sync,data_sync}<={DATA_ONRST,DATA_ONRST};
    else 
      {dataout_sync,data_sync}<={data_sync,datain_async};
endmodule
