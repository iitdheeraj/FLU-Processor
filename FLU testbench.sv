module testbench;
  reg [31:0] control;
  reg clock;
  wire [31:0] out;
  
  
  controller uut(.control(control),.clock(clock),.out(out));
  
  initial
    begin
      clock = 0;
      forever #1 clock = ~clock;
    end 
  initial
    begin 
      $dumpfile("dump.vcd");
      $dumpvars(1);
      
      control = 32'b00000000000100010000111111001011;
      #20;
      $display(out);
      control = 32'b00001000001100100000111101001011;
      #20;
      $display(out);
      control = 32'b00010000010100110000111011001011;
      #10;
      $display(out);
      control = 32'b00011000100101010000110111001011;
      #10;
	  $display(out);
      $finish();
    
    end
endmodule
