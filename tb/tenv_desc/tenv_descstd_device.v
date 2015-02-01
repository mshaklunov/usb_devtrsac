
module tenv_descstd_device();
  //IFACE
  reg[7:0]            bNumConfigurations=8'h00;
  reg[7:0]            iSerialNumber=8'h00;
  reg[7:0]            iProduct=8'h00;
  reg[7:0]            iManufacturer=8'h00;
  reg[15:0]           bcdDevice=16'h0000;
  reg[15:0]           idProduct=16'h0000;
  reg[15:0]           idVendor=16'h0000;
  reg[7:0]            bMaxPacketSize0=8'h08;
  reg[7:0]            bDeviceProtocol=8'hFF;
  reg[7:0]            bDeviceSubClass=8'hFF;
  reg[7:0]            bDeviceClass=8'hFF;
  reg[15:0]           bcdUSB=16'h0110;
  reg[7:0]            bDescriptorType=8'h01;
  reg[7:0]            bLength=8'd18;

  reg[(18*8)-1:0]     data_bybit;
  reg[7:0]            data_bybyte[17:0];
  //LOCAL
  integer       i;

  initial
    begin
    data_bybit={
                bNumConfigurations,
                iSerialNumber,
                iProduct,
                iManufacturer,
                bcdDevice,
                idProduct,
                idVendor,
                bMaxPacketSize0,
                bDeviceProtocol,
                bDeviceSubClass,
                bDeviceClass,
                bcdUSB,
                bDescriptorType,
                bLength
                };

    i=0;
    while(i<(18*8))
      begin
      data_bybyte[i/8][i%8]=data_bybit[i];
      i= i+1;
      end
    end
endmodule
