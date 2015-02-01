
task check_descdev  (
                    input integer     buffer_ptr,
                    input integer     size
                    );
  //LOCAL
  parameter     block_name="tenv_test/check_descdev";
  integer       i;

  begin
  i=buffer_ptr;
  repeat(size)
    begin
    if(`tenv_usbhost.buffer[i]!==`tenv_descstd_device.data_bybyte[i])
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - received invalid descriptor:");
      $display("buffer=%0h vs desc=%0h ",
               `tenv_usbhost.buffer[i],
               `tenv_descstd_device.data_bybyte[i]);
      $finish;
      end
    i=i+1;
    end
  end
endtask

