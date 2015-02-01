
task check_data (
                input integer     buffer_ptr,
                input integer     size
                );
  //LOCAL
  parameter     block_name="tenv_test/check_data";
  integer       i;

  begin
  i=buffer_ptr;
  repeat(size)
    begin
    if(`tenv_usbdev.buffer[i]!==`tenv_usbhost.buffer[i])
      begin
      $write("\n");
      $write("%0t [%0s]: ",$realtime,block_name);
      $display("Error - received invalid data[%0d]",i);
      $finish;
      end
    i=i+1;
    end
  end
endtask

