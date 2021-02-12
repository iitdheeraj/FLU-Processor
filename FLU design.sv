module controller(control,clock,out);
  input  [31:0]  control;
  input  clock;
  output [31:0]  out;
  
  reg [4:0]     operation;
  reg [4:0]     rs2;
  reg [4:0]     rs1;
  reg [4:0]     frd;
  reg [6:0]     opcode;
  
  reg [31:0]  num1,num2;
  reg [31:0]  temp, temp1, temp2, temp3, temp4;
  
  parameter     A = 00000;
  parameter     B = 00001;
  parameter     C = 00010;
  parameter     D = 00011;
  reg [4:0]     state;
  
  assign operation = control[31:27];
  assign rs2       = control[24:20];
  assign rs1       = control[19:15];
  assign frd       = control[11:7] ;
  assign opcode    = control[6:0]  ; ///  1001011

  memory r1(,,rs1,rs2,1'b1,1'b0,clock,num1,num2);

  fp_adder add1(temp1,num1,num2,1'b1,clock);
  fp_subtractor sub1(temp2,num1,num2,1'b1,clock);
  fp_multiplier mult1(num1,num2,temp3);
  fp_divider div1(num1,num2,temp4);
  
  assign state = operation;
  always @(posedge clock)
    case( state )
      A: begin
        temp <= temp1;
      end
      B: begin
        temp <= temp2;
      end
      C: begin
        temp <= temp3;
      end
      D: begin
        temp <= temp4;
      end
    endcase
  
  assign out = temp;
  
  memory w1(out,frd,,,1'b0,1'b1,clock,,);
  
endmodule

////////////////////////////////////////////////////////////
module memory(data_in,address_write,address_read1, address_read2, read, write, clk, data_out1, data_out2);
  input  [31:0] data_in;
  input  [4:0]  address_read1;
  input  [4:0]  address_read2;
  input  [4:0]  address_write;
  input  read,write,clk;
  output [31:0] data_out1;
  output [31:0] data_out2;
  
  reg    [31:0] memory_array[0:31];
  reg    [31:0] out_data1;
  reg    [31:0] out_data2;
  
  assign memory_array[5'b00001] = 32'b01000000100000000000000000000000;
  assign memory_array[5'b00010] = 32'b01000000101000000000000000000000;
  assign memory_array[5'b00011] = 32'b01000000110000000000000000000000;
  assign memory_array[5'b00100] = 32'b01000000111000000000000000000000;
  assign memory_array[5'b00101] = 32'b01000001000000000000000000000000;
  assign memory_array[5'b00110] = 32'b01000001000100000000000000000000;
  assign memory_array[5'b00111] = 32'b01000001001000000000000000000000;
  assign memory_array[5'b01000] = 32'b01000001001100000000000000000000;
  assign memory_array[5'b01001] = 32'b01000001010000000000000000000000;
  assign memory_array[5'b01010] = 32'b01000001010100000000000000000000;
  
  always@(posedge clk)
    begin
      if(read)
        begin
          out_data1 = memory_array[address_read1];
          out_data2 = memory_array[address_read2];
        end
    end
  assign data_out1 = out_data1;
  assign data_out2 = out_data2;
  always@(posedge clk)
    begin
      if(write)
        begin
          memory_array[address_write] = data_in;
        end
      end
endmodule

//////////////////////////////////////////////////////////////
module fp_adder(sum,a_fpn,b_fpn,enable,clock);
  input [31:0]  a_fpn, b_fpn;
  input         enable, clock;
  
  reg           sum_signbit;
  reg [7:0]     sum_exponent;
  reg [25:0]    sum_significand;
  
  reg [31:0]    a, b;
  reg [25:0]    a_significand, b_significand;
  reg [7:0]     a_exponent, b_exponent;
  reg           a_signbit, b_signbit;
  reg [7:0]     diff;
  
  parameter     A = 0;
  parameter     B = 1;
  parameter     C = 2;
  parameter     D = 3;
  reg [1:0]     state;
  output [31:0] sum;
  
  assign        sum[31]    = sum_signbit;
  assign        sum[30:23] = sum_exponent;
  assign        sum[22:0]  = sum_significand;
  
  initial state = A;
  always @( posedge clock )
    case( state )
      0:
        if ( enable ) begin
          if ( a_fpn[30:23] < b_fpn[30:23] ) begin
            a = b_fpn;  b = a_fpn;
          end else begin
            a = a_fpn;  b = b_fpn;
          end
          state = 1;
        end
      1:begin
        a_signbit = a[31];     b_signbit = b[31];
        a_exponent = a[30:23];  b_exponent = b[30:23];
      // Put a 0 in bits 24 and 25,and a 1 in bit 23 of significand if exponent is non-zero.
        a_significand = { 2'b0, a_exponent ? 1'b1 : 1'b0, a[22:0] };
        b_significand = { 2'b0, b_exponent ? 1'b1 : 1'b0, b[22:0] };

        diff = a_exponent - b_exponent;
        b_significand = b_significand >> diff;
        state = 2;
      end
      2:begin
        if ( a_signbit ) 
          a_significand = -a_significand;
        if ( b_signbit ) 
          b_significand = -b_significand;
        sum_significand = a_significand + b_significand;
        state = 3;
      end
      3:begin
        sum_signbit = sum_significand[25];
        if ( sum_signbit )
          sum_significand = -sum_significand;
        if ( sum_significand[24] ) begin
          sum_exponent = a_exponent + 1;
          sum_significand = sum_significand >> 1;
        end else if ( sum_significand )
          begin:K
          integer position, adj, i;
          position = 0;
          for (i = 23; i >= 0; i = i - 1 )
            if ( !position && sum_significand[i] )
              position = i;
          adj = 23 - position;
          if ( a_exponent < adj ) begin
            sum_exponent = 0;
            sum_significand = 0;
            sum_signbit = 0;
          end else begin
            sum_exponent = a_exponent - adj;
            sum_significand = sum_significand << adj;
          end
        end else begin
          sum_exponent = 0;
          sum_significand = 0;
        end
        state = A;
      end
      endcase
endmodule

//////////////////////////////////////////////////////////////
module fp_subtractor(difference,a_fpn,b_fpn,enable,clock);
  input [31:0]  a_fpn, b_fpn;
  input         enable, clock;
  
  reg           difference_signbit;
  reg [7:0]     difference_exponent;
  reg [25:0]    difference_significand;
  
  reg [31:0]    a, b;
  reg [25:0]    a_significand, b_significand;
  reg [7:0]     a_exponent, b_exponent;
  reg           a_signbit, b_signbit;
  reg [7:0]     diff;
  
  parameter     A = 0;
  parameter     B = 1;
  parameter     C = 2;
  parameter     D = 3;
  reg [1:0]     state;
  output [31:0] difference;
  
  assign        difference[31]    = difference_signbit;
  assign        difference[30:23] = difference_exponent;
  assign        difference[22:0]  = difference_significand;
  
  initial state = A;
  always @( posedge clock )
    case( state )
      A:
        if ( enable ) begin
          if ( a_fpn[30:23] < b_fpn[30:23] ) begin
            a = b_fpn;  b = a_fpn;
          end else begin
            a = a_fpn;  b = b_fpn;
          end
          state = B;
        end
      B:begin
        a_signbit = a[31];      b_signbit = ~b[31];
        a_exponent = a[30:23];  b_exponent = b[30:23];
        a_significand = { 2'b0, a_exponent ? 1'b1 : 1'b0, a[22:0] };
        b_significand = { 2'b0, b_exponent ? 1'b1 : 1'b0, b[22:0] };

        diff = a_exponent - b_exponent;
        b_significand = b_significand >> diff;
        state = C;
      end
      C:begin
        if ( a_signbit ) 
          a_significand = -a_significand;
        if ( b_signbit ) 
          b_significand = -b_significand;
        difference_significand = a_significand + b_significand;
        state = D;
      end
      D:begin
        difference_signbit = difference_significand[25];
        if ( difference_signbit )
          difference_significand = -difference_significand;
        if ( difference_significand[24] ) begin
          difference_exponent = a_exponent + 1;
          difference_significand = difference_significand >> 1;
        end else if ( difference_significand )
          begin:K
          integer position, adj, i;
          position = 0;
          for (i = 23; i >= 0; i = i - 1 )
            if ( !position && difference_significand[i] )
              position = i;
          adj = 23 - position;
          if ( a_exponent < adj ) begin
            difference_exponent = 0;
            difference_significand = 0;
            difference_signbit = 0;
          end else begin
            difference_exponent = a_exponent - adj;
            difference_significand = difference_significand << adj;
          end
        end else begin
          difference_exponent = 0;
          difference_significand = 0;
        end
        state = A;
      end
      endcase
endmodule

//////////////////////////////////////////////////////////////
module fp_multiplier(
  input [31:0] a_input,
  input [31:0] b_input,
  output [31:0] result);
  
  wire [8:0] exp,sum_exp;
  wire [22:0] multi_mantissa;
  wire [23:0] temp_a,temp_b;
  wire [47:0] product,result_normalised;
  wire sign,multi_round,normalised,zero,exception,overflow,underflow;
  
  assign sign = (a_input[31] ^ b_input[31]);
  assign temp_a = (|a_input[30:23]) ? {1'b1,a_input[22:0]} : {1'b0,a_input[22:0]};
  assign temp_b = (|b_input[30:23]) ? {1'b1,b_input[22:0]} : {1'b0,b_input[22:0]};
  
  assign product = temp_a * temp_b;
  assign multi_round = |result_normalised[22:0];
  assign normalised = product[47] ? 1'b1 : 1'b0;
  assign result_normalised = normalised ? product : product << 1;
  assign multi_mantissa = result_normalised[46:24] + (result_normalised[23] & multi_round);

  assign exception = (&a_input[30:23]) | (&b_input[30:23]);
  assign zero = exception ? 1'b0 : (multi_mantissa == 23'd0) ? 1'b1 : 1'b0;
  assign sum_exp = a_input[30:23] + b_input[30:23];
  assign exp = sum_exp - 8'd127 + normalised;
  assign overflow = ((exp[8] & !exp[7]) & !zero) ;
  assign underflow = ((exp[8] & exp[7]) & !zero) ? 1'b1 : 1'b0; 
  assign result = exception ? 32'd0 : zero ? {sign,31'd0} : overflow ? {sign,8'hFF,23'd0} : underflow ? {sign,31'd0} : {sign,exp[7:0],multi_mantissa};
endmodule

//////////////////////////////////////////////////////////////
module fp_divider(
  input [31:0] a_input,
  input [31:0] b_input,
  output [31:0] out);
  
  wire [7:0]  shift;
  wire [31:0] a;
  wire [7:0]  a_exp;
  wire [31:0] divisor;
  wire [31:0] Intermediate0;
  wire [31:0] Iteration0;
  wire [31:0] Iteration1;
  wire [31:0] Iteration2;
  wire [31:0] Iteration3;
  wire [31:0] solution;
  wire sign, exception;  //Exception flag sets 1 if either one of the exponent is 255.
  
  assign sign    = a_input[31] ^ b_input[31];
  assign shift   = 8'd126 - b_input[30:23];
  assign divisor = {1'b0,8'd126,b_input[22:0]};
  assign a_exp   = a_input[30:23] + shift;
  assign a  = {a_input[31],a_exp,a_input[22:0]};
  assign exception = (&a_input[30:23]) | (&b_input[30:23]);

  fp_multiplier  part0(32'hC00B_4B4B,divisor,Intermediate0);
  fp_add         part1(Intermediate0,32'h4034_B4B5,Iteration0);
  Iteration      part2(Iteration0,divisor,Iteration1);
  Iteration      part3(Iteration1,divisor,Iteration2);
  Iteration      part4(Iteration2,divisor,Iteration3);
  fp_multiplier  part5(Iteration3,a,solution);
  assign out = {sign,solution[30:0]};
endmodule

module Iteration(
  input [31:0] a,
  input [31:0] b,
  output [31:0] soln);
  wire [31:0] iv1,iv2;
  
  fp_multiplier X1(a,b,iv1);
  fp_add A1(32'h4000_0000,{1'b1,iv1[30:0]},iv2);
  fp_multiplier X2(a,iv2,soln);
endmodule


module fp_add(a_input,b_input, sum);
  input  [31:0] a_input, b_input;
  output [31:0] sum;
  reg           sum_sign;
  reg [7:0]     sum_exp;
  reg [25:0]    sum_significant;
  assign        sum[31]    = sum_sign;
  assign        sum[30:23] = sum_exp;
  assign        sum[22:0]  = sum_significant;
  reg [31:0]    a, b;
  reg [25:0]    a_significant, b_significant;
  reg [7:0]     a_exp, b_exp;
  reg           a_sign, b_sign;
  reg [7:0]    diff;
  
  always @( a_input or b_input )
    begin
      if ( a_input[30:23] < b_input[30:23] ) begin
        a = b_input;  b = a_input;
      end else begin
        a = a_input;  b = b_input;
      end
      a_sign = a[31];     b_sign = b[31];
      a_exp = a[30:23];  b_exp = b[30:23];
      a_significant = { 2'b0,    a_exp ? 1'b1 : 1'b0,    a[22:0] };
      b_significant = { 2'b0, b_exp ? 1'b1 : 1'b0, b[22:0] };
      diff = a_exp - b_exp;
      b_significant = b_significant >> diff;
      if ( a_sign ) a_significant = -a_significant;
      if ( b_sign ) b_significant = -b_significant;
      sum_significant = a_significant + b_significant;
      sum_sign = sum_significant[25];
      if ( sum_sign ) sum_significant = -sum_significant;
      if ( sum_significant[24] ) begin
        sum_exp = a_exp + 1;
        sum_significant = sum_significant >> 1;
      end else if ( sum_significant ) begin:A
        integer position, adj, i;
        position = 0;
        for (i = 23; i >= 0; i = i - 1 ) if ( !position && sum_significant[i] ) position = i;
        adj = 23 - position;
        if ( a_exp < adj ) begin
          sum_exp = 0;
          sum_significant = 0;
          sum_sign = 0;
        end else begin
          sum_exp = a_exp - adj;
          sum_significant = sum_significant << adj;
        end
      end else begin
        sum_exp = 0;
        sum_significant = 0;
      end
    end
endmodule
