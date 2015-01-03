
task gen_data (
              input integer     buffer_ptr,
              input integer     size
              );
  //LOCAL
  parameter   block_name="tenv_usbhost/gen_data";
  integer     i;
  
  begin
  i=0;
  repeat(size)
    begin
    `tenv_usbhost.buffer[buffer_ptr+i]=$random;
    i=i+1;
    end
  end
endtask
