# Neural_network_Zybo

In the master's thesis, we implemented a neural network capable of learning with the backpropagation algorithm in FPGA integrated circuits. The neural network was tested on a Zybo Zynq-7000 development board from Digilent. In addition to the FPGA part, a Zynq also contains a processor, which we used to control the neural network and load learning data. The implemented neural network takes advantage of a high parallelism, since it calculates the entire layer of neurons simultaneously. We analyzed the resource consumption and speed of the neural network operation, as well as the communications between the FPGA and the processor part. The disadvantage of this approach is high consumption of resources.

Directory fa_fs contains implementation of neural network which successfully solve full adder and full substractor in VHDL. 
Directory final_xor_vhdl_code contains all VHDL files of neural network which successfully solve XOR problem.
Directory neural_network_cpu contains implementation of neural network with 2 layers and 2 inputs as a IP block. It uses Zybos procesor and most of the parameters are send to FPGA part from processor. C code which run on processor control network which successfully solve XOR problem.
