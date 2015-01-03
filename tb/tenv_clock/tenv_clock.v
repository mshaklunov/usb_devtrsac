
`include "tenv_clock/tenv_clockgen.v"
module tenv_clock;
  //IFACE
  wire        x4;
  integer     x4_timehigh=10;
  integer     x4_timelow=10;
  integer     x4_period=20;
  reg         x4_en=0;
  reg         x4_init=0;
  //LOCAL
  localparam  block_name="tenv_clock";

	always @* x4_period= x4_timehigh+x4_timelow;
  always
    begin
    wait(!x4_en);
    wait(x4_en);
    @(posedge x4);
    $write  ("\n");
    $write  ("%0t [%0s]: ",$realtime,block_name);
    $write  ("Launch clocks. ");
    $write  ("Period of x4=%0d ns.\n",x4_period);
    end
  
	tenv_clockgen   #(.clocks_number(1))
     i_clockgen		 ( 	
                   .init(x4_init),
                   .en(x4_en ),
                   .time_high(x4_timehigh),
                   .time_low(x4_timelow),
                   .clocks(x4)
                   );
endmodule
