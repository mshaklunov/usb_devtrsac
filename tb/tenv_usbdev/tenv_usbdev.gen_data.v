
task gen_data (
              input integer buffer_ptr,
              input integer size
              );
  //LOCAL
  parameter   block_name="tenv_usbdev/gen_data";
  integer     i;

  begin
  i=0;
  repeat(size)
    begin
    buffer[buffer_ptr+i]=$random;
    i=i+1;
    end
  end
endtask

