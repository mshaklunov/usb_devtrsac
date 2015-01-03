
module tenv_test;
  /*MODULE REFERENCE
      `tenv_clock
      `tenv_usbhost
      `tenv_usbdev
      `tenv_descstd_device
      `tenv_usbdecoder
      `tenv_usbencoder
  */
  //IFACE
  reg           start=0;
  //LOCAL   
  localparam    block_name="tenv_test";
  integer       seed;
  integer       i;
  //TASKS
  `include "tenv_test/tenv_test.tcase_powered.v"
  `include "tenv_test/tenv_test.tcase_default.v"
  `include "tenv_test/tenv_test.tcase_addressed.v"
  `include "tenv_test/tenv_test.tcase_configured.v"
  `include "tenv_test/tenv_test.tcase_suspended.v"
  `include "tenv_test/tenv_test.tcase_trfer_bulkint.v"
  `include "tenv_test/tenv_test.tcase_trfer_isoch.v"
  `include "tenv_test/tenv_test.tcase_trfer_control.v"
  `include "tenv_test/tenv_test.tcase_bitstream.v"
  `include "tenv_test/tenv_test.tcase_reply_delay.v"
  `include "tenv_test/tenv_test.trsac.v"
  
  initial forever
    begin
    wait(start==1);
    $timeformat(-9, 0, " ns", 10);
    #100;
    $write("%0t [%0s]: ",$realtime,block_name);
    $write("--- Functional verification of \"usb_devtrsac\" ---\n");

    fork
      begin:TEST_SEQUENCE

      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $write("FULL SPEED FUNCTION");
      $write("\n");      
      //LAUNCH CLOCKS
      `tenv_clock.x4_timehigh=10;
      `tenv_clock.x4_timelow=11;
      `tenv_clock.x4_en=1;
      @(posedge `tenv_clock.x4);
      
      //INIT
      `tenv_descstd_device.bNumConfigurations=8'h01;
      `tenv_descstd_device.iSerialNumber=8'h00;
      `tenv_descstd_device.iProduct=8'h00;
      `tenv_descstd_device.iManufacturer=8'h00;
      `tenv_descstd_device.bcdDevice=16'h0000;
      `tenv_descstd_device.idProduct=16'h0000;
      `tenv_descstd_device.idVendor=16'h0000;
      `tenv_descstd_device.bMaxPacketSize0=8'h08;
      `tenv_descstd_device.bDeviceProtocol=8'hFF;
      `tenv_descstd_device.bDeviceSubClass=8'hFF;
      `tenv_descstd_device.bDeviceClass=8'hFF;
      `tenv_descstd_device.bcdUSB=16'h0110;
      `tenv_descstd_device.bDescriptorType=8'h01;
      `tenv_descstd_device.bLength=8'd18;
      
      `tenv_usbdev.speed=1;//SELECT FULL SPEED
      `tenv_usb_encoder.bit_time=`tenv_clock.x4_period*4;
      `tenv_usb_decoder.bit_time=`tenv_clock.x4_period*4;
      `tenv_usb_encoder.speed=`tenv_usbdev.speed;
      `tenv_usb_decoder.speed=`tenv_usbdev.speed;
      `tenv_usbdev.ep_enable=15'h7FFF;//ENABLE ALL EP
      `tenv_usbdev.ep_isoch=15'd000_0000_0000_0000;
      `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;      
      
      //TESTCASES
      tcase_powered;
      tcase_default;
      tcase_addressed;
      tcase_configured;
      tcase_suspended;
      tcase_trfer_bulkint;
      tcase_trfer_isoch;
      tcase_trfer_control;
      tcase_bitstream;
      tcase_reply_delay;
      
      //STOP CLOCKS
      @(negedge `tenv_clock.x4);
      `tenv_clock.x4_en=0;
      
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $write("LOW SPEED FUNCTION");
      $write("\n");
      //LAUNCH CLOCKS
      `tenv_clock.x4_timehigh=83;
      `tenv_clock.x4_timelow=84;
      `tenv_clock.x4_en=1;
      @(posedge `tenv_clock.x4);
      
      //INIT
      `tenv_usbdev.speed=0;//SELECT LOW SPEED
      `tenv_usb_encoder.bit_time=`tenv_clock.x4_period*4;
      `tenv_usb_decoder.bit_time=`tenv_clock.x4_period*4;
      `tenv_usb_encoder.speed=`tenv_usbdev.speed;
      `tenv_usb_decoder.speed=`tenv_usbdev.speed;
      `tenv_usbdev.ep_enable=15'h7FFF;//ENABLE ALL EP
      `tenv_usbdev.ep_isoch=15'd000_0000_0000_0000;
      `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;      
      
      //TESTCASES
      tcase_powered;
      tcase_default;
      tcase_addressed;
      tcase_configured;
      tcase_suspended;
      tcase_trfer_bulkint;
      tcase_trfer_control;
      tcase_bitstream;      
      tcase_reply_delay;
      
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $write("--- Functional verification of \"usb_devtrsac\" ");
      $write("is successfull ---\n");
      disable TIMEBOMB;
      end//TEST_SEQUENCE

      begin:TIMEBOMB
      repeat(150) #(1000*1000);//100 ms
      $write  ("\n");    
      $write  ("%0t [%0s]: ",$realtime,block_name);    
      $display("Error - test time is run out.");
      disable TEST_SEQUENCE;
      end//TIMEBOMB
    join

    start=0;
    end
endmodule
