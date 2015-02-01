//MODULE INCLUDING
`include  "tenv_test/tenv_test.v"
`include  "tenv_link/tenv_link.v"
`include  "tenv_usbhost/tenv_usbhost.v"
`include  "tenv_usbdev/tenv_usbdev.v"
`include  "tenv_desc/tenv_descstd_device.v"
`include  "tenv_clock/tenv_clock.v"

module testbench();

//INSTANCE TEST ENVIRONMENT
  tenv_test               tenv_test();
  tenv_link               tenv_link();
  tenv_clock              tenv_clock();
  tenv_usbhost            #(.PACKET_MAXSIZE(64),
                            .DATA_MAXSIZE(512))
                          tenv_usbhost();
  tenv_usbdev             #(.DATA_MAXSIZE(512))
                          tenv_usbdev();
  tenv_descstd_device     tenv_descstd_device();

//INSTANCE DUT
  usb_devtrsac            dut();

//LAUNCH TEST
  initial
    begin
    tenv_test.start=1;
    wait(tenv_test.start==0)
    #1000;
    $finish;
    end
endmodule
