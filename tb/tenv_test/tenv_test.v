//MODULE REFERENCE
`define   tenv_clock                tenv_clock
`define   tenv_descstd_device       tenv_descstd_device
`define   tenv_usbhost              tenv_usbhost
`define   tenv_usbdev               tenv_usbdev

module tenv_test;

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
  `include "tenv_test/tenv_test.check_data.v"
  `include "tenv_test/tenv_test.check_descdev.v"

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
      `tenv_usbdev.speed=1;//SELECT FULL SPEED
      `tenv_usbdev.ep_enable=15'h7FFF;//ENABLE ALL EP
      `tenv_usbdev.ep_isoch=15'd000_0000_0000_0000;
      `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
      `tenv_usbhost.speed=`tenv_usbdev.speed;
      `tenv_usbhost.bit_time=`tenv_clock.x4_period*4;

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
      `tenv_usbdev.ep_enable=15'h7FFF;//ENABLE ALL EP
      `tenv_usbdev.ep_isoch=15'd000_0000_0000_0000;
      `tenv_usbdev.ep_intnoretry=15'b000_0000_0000_0000;
      `tenv_usbhost.speed=`tenv_usbdev.speed;
      `tenv_usbhost.bit_time=`tenv_clock.x4_period*4;

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
      repeat(300) #(1000*1000);//100 ms
      $write  ("\n");
      $write  ("%0t [%0s]: ",$realtime,block_name);
      $display("Error - test time is run out.");
      disable TEST_SEQUENCE;
      end//TIMEBOMB
    join

    start=0;
    end
endmodule
