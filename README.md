# FLU-Processor
We are making a processor for floating-point where we will be doing four operations, adder, subtractor, multiplier, and divisor. We are using the IEEE 754 standard to convert floating-point into 32-bit binary single-precision representation. We save our inputs and the outputs into the memory module and then use our controller module to call the different operations.

# Adder Module
First, we checked which input is bigger and which one is smaller, to make the exponent equal before adding their mantissa. Then we found out if there any negative input followed by adding the two significands using an efficient method. Then we generate a sum output by combining the sum_sign, sum_exponent, and sum_mantissa. We have three major tasks pre normalization, the addition of mantissa, post normalization, and exceptional handling.

# Subtractor Module
Everything is similar to that of the Adder module except the signbit of the second input. In subtractor we did the adding operation after changing the second input floating Point Number.

# Multiplier Module
Constructing an efficient multiplication module is an iterative process and a 2n-digit product is obtained from the product of two n-digit operands. In IEEE 754 floating-point multiplication, the two mantissae are multiplied, and the two exponents are added. Here first the exponents are added from which the exponent bias (127) is removed. Then mantissa has been multiplied using a feasible algorithm and the output sign bit is determined by exploring the two input sign bits. The obtained result has been normalized and checked for exceptions. 

# Divider Module
Division operation has two components as its result i.e. quotient and a remainder when two inputs, a dividend, and a divisor are given. The sign of result has been calculated from the exoring sign of two operands. Then the obtained quotient has been normalized. This division occurs in a non restoring algorithm. Non restoring algorithms have no error in delay. 

# Controller Module, Memory Module, Integration of all Modules
In the controller, we used a four-bit control signal, by using which we called our different operations module. 

We have created a 32*32 bits memory module. Which we have used to read and write the inputs.
