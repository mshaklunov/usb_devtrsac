	
`define   tenv_clock 					      tenv_clock
`define   tenv_descstd_device       tenv_descstd_device
`define   tenv_usbhost              tenv_usbhost
`define   tenv_usbdev               tenv_usbdev
`define   tenv_usb_encoder			    tenv_usb_encoder
`define   tenv_usb_decoder			    tenv_usb_decoder
`include  "tenv_test/tenv_test.v"	

`define   dut 						          dut
`define   tenv_usb_encoder			    tenv_usb_encoder
`define   tenv_usb_decoder			    tenv_usb_decoder
`define   tenv_clock 					      tenv_clock
`define   tenv_usbdev               tenv_usbdev
`include  "tenv_link/tenv_link.v"

`include  "tenv_usbhost/tenv_usbhost.v"
`include  "tenv_usbdev/tenv_usbdev.v"
`include  "tenv_desc/tenv_descstd_device.v"
`include  "tenv_clock/tenv_clock.v"
`include  "tenv_usb_decoder.v"
`include  "tenv_usb_encoder.v"
	
module testbench();

//INSTANCE TEST ENVIRONMENT
  tenv_test               tenv_test();
	tenv_link               tenv_link();
	tenv_clock              `tenv_clock();
  tenv_usb_decoder        `tenv_usb_decoder();	
  tenv_usb_encoder        `tenv_usb_encoder();
  tenv_usbhost            `tenv_usbhost();
  tenv_usbdev             `tenv_usbdev();
  tenv_descstd_device     `tenv_descstd_device();
  
//INSTANCE DUT
  usb_devtrsac            `dut();
	
//LAUNCH TEST
	initial
		begin
		tenv_test.start=1;
		wait(tenv_test.start==0)
		#1000;
		$finish;
		end
endmodule
