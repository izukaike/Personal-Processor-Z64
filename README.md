# 64-Bit ARM Processor
64-Bit ARM Processor

As a computer engineering student I wanted to follow my curiosity and get more hardware experience and dive into the details of digital design. I am building a compiler, processor, and sensor interface in C++, Python, and SystemVerilog.As I dive deeper and get more interested in hardware design from my Computer Organization and Advanced Digital Logic classs at Baylor University I want to apply my knowledge and enjoy the process. I think that a 64-bit RISC design is important in many hardware engineering applications. Here is my journey!

# High-Level
### High Level Project Diagram
<p align="center">
  <img align="middle" alt="Java" width="750px" height="160px"src="https://github.com/user-attachments/assets/ca5eb641-1744-4098-b253-c763b970b78f">
</p>

### High Level Processor Design
<p align="center">
  <img align="middle" alt="Java" width="400px" height="250px"src="https://github.com/user-attachments/assets/72989766-272d-4b91-9ce7-69e18da24b90">
</p>



# Features
- 64-Bit ARM Processor
- Assembler
## To Do
  * Finalize Sensor Design
  * Finish Memory Block
  * Start Custom Compiler Based Off Of C++
  * Pipeline The Design
  * Custom Block Carry Look ahead adders

<p align="center">
  <img src="https://github.com/user-attachments/assets/865e264c-a4e5-4c0f-a108-eae295db90f5" alt="Image Description" width="490" height="350">
</p>

# Adder
<img align="middle" alt="Java" width="490px" height="350px" src="https://github.com/user-attachments/assets/a2224ca3-151d-4e10-a6e9-98754c971059"/>
     
      module adder(
          input  [64-1:0] a_in,
          input  [64-1:0] b_in,
          output [64-1:0] add_out
          );
          
      assign add_out = a_in + b_in;
      endmodule



# Program Counter
<img align="middle" alt="Java" width="490px" height="350px" src="https://github.com/user-attachments/assets/e84dac18-cf48-40c5-bbc6-beba34a6e512"/>

   
    `include "definitions.vh"
    module register(
        input clk,
        input reset,
        input  [`WORD-1:0] D,
        output reg [`WORD-1:0] Q
        );
        always @(posedge(clk),posedge(reset))begin
            if (reset==1'b1)
                Q<=`WORD'b0;
            else
                Q <= D;
        end
    endmodule
# Instruction Memory
<img align="middle" alt="Java" width="490px" height="350px" src="https://github.com/user-attachments/assets/eb80d6c3-5f13-41a6-93d0-dd7cce7b9296"/>
   
   
   
      `include "definitions.vh"
      module instr_mem#(
          parameter SIZE=1024)(
          input wire clk,
          input wire[`WORD-1:0] pc,
          output reg[`INSTR_LEN-1:0] instruction
          );
      	 // TODO: create imem array here
      	 reg[`INSTR_LEN-1:0] imem [SIZE-1:0];
          
      	 // TODO: insert code here to fetch the correct
          //initialize memory from file
          initial
              $readmemh(`IMEMFILE, imem);
          
          always @(posedge(clk)) begin
                 instruction <= imem[pc/4];
          end
       endmodule
   
# Full Fetch Stage 
<img align="middle" alt="Java" width="325px" height="400px" src="https://github.com/user-attachments/assets/933a462f-5f76-4ba2-8644-0317bf8eb2bd"/>
     
     module iFetch#(
         parameter SIZE=16)(
         input wire clk,
         input wire clk_delayed,
         input wire reset,
         input wire pc_src,
         input wire[`WORD-1:0] branch_target,
         output wire[`INSTR_LEN-1:0] instruction,
         input wire[`WORD-1:0] cur_pc,
         output wire[`WORD-1:0] incremented_pc
         );
        
        
        wire [`WORD-1:0] new_pc;
        //wire [`WORD-1:0] incremented_pc = `WORD'b0;
       
        instr_mem#(.SIZE(SIZE)) imem(
                 .clk(clk_delayed),
                 .pc(cur_pc),
                 .instruction(instruction)
         );
        mux#(.SIZE(`WORD)) m1(
                .a_in(incremented_pc),
                .b_in(branch_target),
                .control(pc_src), 
                .mux_out(new_pc)
         );
         register pc(
                   .clk(clk),
                   .reset(reset),
                   .D(new_pc),
                   .Q(cur_pc)
          );
          wire [`WORD-1:0] incr =  4;
          adder a1(
                 .a_in(cur_pc),
                 .b_in(incr),
                 .add_out(incremented_pc)
         );
      
                           
     endmodule

  # Decode Stage
    module iDecode(
    input clk,
    input read_clk,
    input write_clk,
    input [`INSTR_LEN-1:0] instruction,
    input [`WORD-1:0] write_data,
    output [10:0] opcode,
    output [`WORD-1:0] sign_extended_output,
    output reg2_loc,        
    output uncondbranch,
    output branch,
    output mem_read,
    output mem_to_reg,
    output [1:0] alu_op,
    output mem_write,
    output alu_src,
    output reg_write,
    output wire[`WORD-1:0] read_data1,
    output wire [`WORD-1:0] read_data2,
    output wire  [`WORD-1:0] val
    );
    
    //instruction parser
    wire [4:0] rm_num;
    wire [4:0] rn_num;
    wire [4:0] rd_num;
    wire [8:0] address;
    wire [10:0] op;
    wire [4:0]  mux_out;
    wire [`WORD-1:0] df [32-1:0];
    
    assign opcode = op;
    
   
    instr_parse ip(
        .instruction(instruction),
        .rm_num(rm_num),
        .rn_num(rn_num),
        .rd_num(rd_num),
        .address(address),
        .opcode(op)
        //.val(val)
    );
    
    //control unit
    control ctrl(
       .opcode(op),
       .reg2_loc(reg2_loc),
       .uncondbranch(uncondbranch),
       .branch(branch),
       .mem_read(mem_read),
       .mem_to_reg(mem_to_reg),
       .alu_op(alu_op),
       .mem_write(mem_write),
       .alu_src(alu_src),
       .reg_write(reg_write)
    );
   
    //reg file
    regfile r(
            .read_clk(read_clk),
            .write_clk(write_clk),
            .read_register1(rn_num),
            .read_register2(mux_out),
            .write_register(rd_num), // X9
            .reg_write(reg_write),
            .write_data(write_data), // this just isnt working
            .read_data1(read_data1),
            .read_data2(read_data2),
            .val(val)
    );

    
    //sign extender
    sign_extender sign_X(
            .instruction(instruction),
            .sign_extended_output(sign_extended_output)
            //.val(val)
    );
    
    //mux
    mux#(.SIZE(5)) m(
           .a_in(rm_num),
           .b_in(rd_num),
           .control(reg2_loc), 
           .mux_out(mux_out)
           //.val(val)
     );
    endmodule
   ### Reg File
    module regfile(
    input read_clk,
    input write_clk,
    input [4:0] read_register1,
    input [4:0] read_register2,
    input [4:0] write_register,
    input       reg_write,
    input  reg [`WORD-1:0]  write_data,
    output reg [`WORD -1:0] read_data1,
    output reg [`WORD -1:0] read_data2,
    output reg [`WORD-1:0] df [32-1:0],
    output wire [`WORD-1:0] val
    );

    //datafile array

	 reg[`WORD-1:0] datafile [32-1:0];
    
    initial
        $readmemb(`RMEMFILE, datafile);
  
    //should retrieve data from the registers on the rising edge of read clk
    always @(posedge(read_clk),posedge(write_clk)) begin
            read_data1 <= datafile[read_register1];
            read_data2 <= datafile[read_register2];
            //val <= datafile[read_register2];
     end
    
    always @(posedge(write_clk)) begin 
            if(reg_write == 1'b1)
                datafile[write_register] <= write_data;
            else   
                datafile[write_register] <= datafile[write_register];
              
          //val <= write_data;    
    end
       
    endmodule


