`include "verification_functions.sv"

module adder_test;

import verification::*;

// input and output signals for the adder module
reg [`WORD-1:0] a;
reg [`WORD-1:0] b;
wire [`WORD-1:0] sum;

// expected results signals
reg [`WORD-1:0] er_sum;

// declare a test case variable to clearly indicate which
// test case is being run
// this variable will be incremented after each test case
int tc = 1;

// declare a test case variable to clearly indicate which
// test step is being run
// this variable will be incremented after each test step
// but will be set back to 1 for each new test case
// each test case has one or more test steps
int ts = 1;

// string to identify that we are verifying the sum
string sum_string = "|sum|";


// TODO: create an adder instance called UUT
// use signals a, b, and sum to connect to
// the module ports a_in, b_in, add_out

adder dut(
       .a_in(a),
       .b_in(b),
       .add_out(sum)
);


initial
begin
    begin_test();

///// TEST CASE 1 /////
    $display("Test Case %0d", tc++);
	a = `WORD'd5;
	b = `WORD'd10;
	er_sum = `WORD'd15;
	#((`CYCLE*7)/10);
	
    // wait for one cycle (10ns)
    
    
    
    $display("Inputs: a = %0d | b = %0d", $signed(a), $signed(b));     
    verify(ts, sum_string, er_sum, $bits(er_sum), sum, $bits(sum), `S_DEC);

///// TEST CASE 2 /////
    $display("\nTest Case %0d", tc++);            
 
 	// TODO: add test details here
 	a = `WORD'd280;
	b = `WORD'd1000;
	
	er_sum = `WORD'd1280;
	#((`CYCLE*4)/10);
	

	$display("Inputs: a = %0d | b = %0d", $signed(a), $signed(b));     
    verify(ts, sum_string, er_sum, $bits(er_sum), sum, $bits(sum), `S_DEC);

///// TEST CASE 3 /////
    $display("\nTest Case %0d", tc++);

	// TODO: add test details here
    a = `WORD'd280;
	b = -`WORD'd1000;
	
	er_sum = -`WORD'd720;
	#((`CYCLE*2)/10);
	
	
    $display("Inputs: a = %0d | b = %0d", $signed(a), $signed(b));     
    verify(ts, sum_string, er_sum, $bits(er_sum), sum, $bits(sum), `S_DEC);

///// TEST CASE 4 /////
    $display("\nTest Case %0d", tc++);  

	// TODO: add test details here
	a = -`WORD'd280;
	b = `WORD'd1000;
	
	er_sum = `WORD'd720;
	#((`CYCLE*5)/10);
	

    $display("Inputs: a = %0d | b = %0d", $signed(a), $signed(b));     
    verify(ts, sum_string, er_sum, $bits(er_sum), sum, $bits(sum), `S_DEC);

///// TEST CASE 5 /////
    $display("\nTest Case %0d", tc++);    
	
	// TODO: add test details here
	a = -`WORD'd54321;
	b = `WORD'd1000;
	er_sum = -`WORD'd53321;
	#((`CYCLE*6)/10);
	

    $display("Inputs: a = %0d | b = %0d", $signed(a), $signed(b));     
    verify(ts, sum_string, er_sum, $bits(er_sum), sum, $bits(sum), `S_DEC);
    
    final_result();
    $finish;
end

endmodule
