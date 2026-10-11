`timescale 1ns / 1ps

//======================================================
// PROGRAM COUNTER
//======================================================
module pc(
    input wire clk,
    input wire reset,
    input wire [15:0] next_pc,
    output reg [15:0] pc
);
    always @(posedge clk) begin
        if (reset)
            pc <= 16'b0;
        else
            pc <= next_pc;
    end
endmodule

//======================================================
// INSTRUCTION MEMORY
//======================================================
module instruction_memory(
    input wire [15:0] address,
    output wire [15:0] instruction
);
    reg [15:0] memory [0:255];
    integer i;

    assign instruction = memory[address[7:0]];

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 16'b0;

        memory[0] = 16'b0000_011_001_010_000;
        memory[1] = 16'b0000_100_011_001_001;
        memory[2] = 16'b0000_101_001_010_010;
        memory[3] = 16'b0000_110_001_010_011;
        memory[4] = 16'b0101_011_001_000101;
    end
endmodule

//======================================================
// REGISTER FILE
//======================================================
module register_file(
    input wire clk,
    input wire reset,
    input wire [2:0] read_addr1,
    input wire [2:0] read_addr2,
    output wire [15:0] read_data1,
    output wire [15:0] read_data2,
    input wire [2:0] write_addr,
    input wire [15:0] write_data,
    input wire write_enable
);
    reg [15:0] registers [0:7];
    integer i;

    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'b0;
        end
        else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule

//======================================================
// ALU
//======================================================
module alu(
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [2:0] alu_control,
    output reg [15:0] result
);
    always @(*) begin
        case (alu_control)
            3'b000: result = A + B;
            3'b001: result = A - B;
            3'b010: result = A & B;
            3'b011: result = A | B;
            3'b100: result = A ^ B;
            default: result = 16'b0;
        endcase
    end
endmodule

//======================================================
// IMMEDIATE GENERATOR
//======================================================
module immediate_generator(
    input wire [15:0] instruction,
    output reg [15:0] immediate
);
    always @(*) begin
        immediate = {{10{instruction[5]}}, instruction[5:0]};
    end
endmodule

//======================================================
// MULTIPLEXER
//======================================================
module mux(
    input wire [15:0] input0,
    input wire [15:0] input1,
    input wire select,
    output wire [15:0] output_data
);
    assign output_data = select ? input1 : input0;
endmodule

//======================================================
// DATA MEMORY
//======================================================
module data_memory(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [15:0] address,
    input wire [15:0] write_data,
    output wire [15:0] read_data
);
    reg [15:0] memory [0:255];

    assign read_data =
        mem_read ? memory[address[7:0]] : 16'b0;

    always @(posedge clk) begin
        if (mem_write)
            memory[address[7:0]] <= write_data;
    end
endmodule

//======================================================
// CONTROL UNIT
//======================================================
module control_unit(
    input wire [3:0] opcode,
    input wire [2:0] funct,
    output reg reg_write,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [2:0] alu_control
);
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_control = 3'b000;

        case (opcode)
            4'b0000: begin
                reg_write = 1'b1;

                case (funct)
                    3'b000: alu_control = 3'b000;
                    3'b001: alu_control = 3'b001;
                    3'b010: alu_control = 3'b010;
                    3'b011: alu_control = 3'b011;
                    3'b100: alu_control = 3'b100;
                    default: alu_control = 3'b000;
                endcase
            end

            4'b0101: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_control = 3'b000;
            end

            4'b0110: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                alu_control = 3'b000;
            end

            4'b0111: begin
                alu_src = 1'b1;
                mem_write = 1'b1;
                alu_control = 3'b000;
            end

            4'b1000: begin
                branch = 1'b1;
                alu_control = 3'b001;
            end

            4'b1001: begin
                jump = 1'b1;
            end

            default: begin
                // All control signals remain at defaults.
            end
        endcase
    end
endmodule

//======================================================
// BRANCH UNIT
//======================================================
module branch_unit(
    input wire [15:0] rs1_value,
    input wire [15:0] rs2_value,
    input wire [15:0] pc,
    input wire [15:0] offset,
    output wire branch_taken,
    output wire [15:0] branch_target
);
    assign branch_taken = (rs1_value == rs2_value);
    assign branch_target = pc + offset;
endmodule

//======================================================
// IF/ID PIPELINE REGISTER
//======================================================
module if_id_register(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,
    input wire [15:0] pc_in,
    input wire [15:0] instruction_in,
    output reg [15:0] pc_out,
    output reg [15:0] instruction_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            pc_out <= 16'b0;
            instruction_out <= 16'b0;
        end
        else if (enable) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
    end
endmodule

//======================================================
// ID/EX PIPELINE REGISTER
//======================================================
module id_ex_register(
    input wire clk,
    input wire reset,
    input wire flush,

    input wire [15:0] pc_in,
    input wire [15:0] read_data1_in,
    input wire [15:0] read_data2_in,
    input wire [15:0] immediate_in,

    input wire [2:0] rs1_in,
    input wire [2:0] rs2_in,
    input wire [2:0] rd_in,

    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,
    input wire alu_src_in,
    input wire branch_in,
    input wire [2:0] alu_control_in,

    output reg [15:0] pc_out,
    output reg [15:0] read_data1_out,
    output reg [15:0] read_data2_out,
    output reg [15:0] immediate_out,

    output reg [2:0] rs1_out,
    output reg [2:0] rs2_out,
    output reg [2:0] rd_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out,
    output reg alu_src_out,
    output reg branch_out,
    output reg [2:0] alu_control_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            pc_out <= 16'b0;
            read_data1_out <= 16'b0;
            read_data2_out <= 16'b0;
            immediate_out <= 16'b0;

            rs1_out <= 3'b0;
            rs2_out <= 3'b0;
            rd_out <= 3'b0;

            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_src_out <= 1'b0;
            branch_out <= 1'b0;
            alu_control_out <= 3'b0;
        end
        else begin
            pc_out <= pc_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            immediate_out <= immediate_in;

            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;

            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out <= alu_src_in;
            branch_out <= branch_in;
            alu_control_out <= alu_control_in;
        end
    end
endmodule

//======================================================
// EX/MEM PIPELINE REGISTER
//======================================================
module ex_mem_register(
    input wire clk,
    input wire reset,

    input wire [15:0] alu_result_in,
    input wire [15:0] read_data2_in,
    input wire [2:0] rd_in,

    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire mem_to_reg_in,

    output reg [15:0] alu_result_out,
    output reg [15:0] read_data2_out,
    output reg [2:0] rd_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out
);
    always @(posedge clk) begin
        if (reset) begin
            alu_result_out <= 16'b0;
            read_data2_out <= 16'b0;
            rd_out <= 3'b0;

            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end
        else begin
            alu_result_out <= alu_result_in;
            read_data2_out <= read_data2_in;
            rd_out <= rd_in;

            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule

//======================================================
// MEM/WB PIPELINE REGISTER
//======================================================
module mem_wb_register(
    input wire clk,
    input wire reset,

    input wire [15:0] alu_result_in,
    input wire [15:0] memory_data_in,
    input wire [2:0] rd_in,

    input wire reg_write_in,
    input wire mem_to_reg_in,

    output reg [15:0] alu_result_out,
    output reg [15:0] memory_data_out,
    output reg [2:0] rd_out,

    output reg reg_write_out,
    output reg mem_to_reg_out
);
    always @(posedge clk) begin
        if (reset) begin
            alu_result_out <= 16'b0;
            memory_data_out <= 16'b0;
            rd_out <= 3'b0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end
        else begin
            alu_result_out <= alu_result_in;
            memory_data_out <= memory_data_in;
            rd_out <= rd_in;
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule

//======================================================
// FORWARDING UNIT
//======================================================
module forwarding_unit(
    input wire [2:0] rs1_ex,
    input wire [2:0] rs2_ex,

    input wire [2:0] rd_exmem,
    input wire reg_write_exmem,
    input wire mem_to_reg_exmem,

    input wire [2:0] rd_memwb,
    input wire reg_write_memwb,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (reg_write_exmem && !mem_to_reg_exmem &&
            (rd_exmem == rs1_ex))
            forward_a = 2'b10;

        if (reg_write_exmem && !mem_to_reg_exmem &&
            (rd_exmem == rs2_ex))
            forward_b = 2'b10;

        if (reg_write_memwb && (rd_memwb == rs1_ex) &&
            !(reg_write_exmem && !mem_to_reg_exmem &&
              (rd_exmem == rs1_ex)))
            forward_a = 2'b01;

        if (reg_write_memwb && (rd_memwb == rs2_ex) &&
            !(reg_write_exmem && !mem_to_reg_exmem &&
              (rd_exmem == rs2_ex)))
            forward_b = 2'b01;
    end
endmodule

//======================================================
// HAZARD DETECTION UNIT
//======================================================
module hazard_detection_unit(
    input wire idex_mem_read,
    input wire [2:0] idex_rd,
    input wire [2:0] ifid_rs1,
    input wire [2:0] ifid_rs2,
    input wire ifid_uses_rs1,
    input wire ifid_uses_rs2,
    output reg stall
);
    always @(*) begin
        stall = 1'b0;

        if (idex_mem_read) begin
            if ((ifid_uses_rs1 && (idex_rd == ifid_rs1)) ||
                (ifid_uses_rs2 && (idex_rd == ifid_rs2)))
                stall = 1'b1;
        end
    end
endmodule

//======================================================
// FIVE-STAGE PIPELINED PROCESSOR
//======================================================
module pipelined_processor(
    input wire clk,
    input wire reset,
    output wire [15:0] pc,
    output wire [15:0] instruction
);
    wire [15:0] next_pc;
    wire [15:0] fetched_instruction;

    wire hazard_stall;
    wire branch_taken_ex;
    wire branch_equal_ex;
    wire [15:0] branch_target_ex;
    wire [15:0] jump_target_id;

    // Instruction Fetch
    pc pc_unit(
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    instruction_memory imem(
        .address(pc),
        .instruction(fetched_instruction)
    );

    assign instruction = fetched_instruction;

    // IF/ID pipeline register
    wire [15:0] ifid_pc;
    wire [15:0] ifid_instruction;

    if_id_register ifid(
        .clk(clk),
        .reset(reset),
        .enable(~hazard_stall),
        .flush(branch_taken_ex || jump_id),
        .pc_in(pc),
        .instruction_in(fetched_instruction),
        .pc_out(ifid_pc),
        .instruction_out(ifid_instruction)
    );

    // Instruction Decode
    wire [3:0] opcode;
    wire [2:0] rd;
    wire [2:0] rs1;
    wire [2:0] rs2;
    wire [2:0] funct;

    assign opcode = ifid_instruction[15:12];
    assign rd = ifid_instruction[11:9];
    assign funct = ifid_instruction[2:0];

    assign rs1 = (opcode == 4'b1000)
                 ? ifid_instruction[11:9]
                 : ifid_instruction[8:6];

    assign rs2 = (opcode == 4'b0111)
                 ? ifid_instruction[11:9]
                 : (opcode == 4'b1000)
                   ? ifid_instruction[8:6]
                   : ifid_instruction[5:3];

    wire ifid_uses_rs1;
    wire ifid_uses_rs2;

    assign ifid_uses_rs1 =
        (opcode == 4'b0000) ||
        (opcode == 4'b0101) ||
        (opcode == 4'b0110) ||
        (opcode == 4'b0111) ||
        (opcode == 4'b1000);

    assign ifid_uses_rs2 =
        (opcode == 4'b0000) ||
        (opcode == 4'b0111) ||
        (opcode == 4'b1000);

    // Register File and Writeback
    wire [15:0] read_data1;
    wire [15:0] read_data2;
    wire [2:0] wb_rd;
    wire [15:0] wb_data;
    wire wb_reg_write;

    register_file rf(
        .clk(clk),
        .reset(reset),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .write_addr(wb_rd),
        .write_data(wb_data),
        .write_enable(wb_reg_write)
    );

    // Control Unit
    wire reg_write_id;
    wire alu_src_id;
    wire mem_read_id;
    wire mem_write_id;
    wire mem_to_reg_id;
    wire branch_id;
    wire jump_id;
    wire [2:0] alu_control_id;

    control_unit cu(
        .opcode(opcode),
        .funct(funct),
        .reg_write(reg_write_id),
        .alu_src(alu_src_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),
        .mem_to_reg(mem_to_reg_id),
        .branch(branch_id),
        .jump(jump_id),
        .alu_control(alu_control_id)
    );

    // Immediate Generator
    wire [15:0] immediate_id;

    immediate_generator imm_gen(
        .instruction(ifid_instruction),
        .immediate(immediate_id)
    );

    // Jump Target
    assign jump_target_id = {4'b0000, ifid_instruction[11:0]};

    // Pipeline Signals
    wire [15:0] idex_pc;
    wire [15:0] idex_read_data1;
    wire [15:0] idex_read_data2;
    wire [15:0] idex_immediate;

    wire [2:0] idex_rs1;
    wire [2:0] idex_rs2;
    wire [2:0] idex_rd;

    wire idex_reg_write;
    wire idex_mem_read;
    wire idex_mem_write;
    wire idex_mem_to_reg;
    wire idex_alu_src;
    wire idex_branch;
    wire [2:0] idex_alu_control;

    wire [15:0] exmem_alu_result;
    wire [15:0] exmem_read_data2;
    wire [2:0] exmem_rd;

    wire exmem_reg_write;
    wire exmem_mem_read;
    wire exmem_mem_write;
    wire exmem_mem_to_reg;

    wire [15:0] memwb_alu_result;
    wire [15:0] memwb_memory_data;
    wire [2:0] memwb_rd;

    wire memwb_reg_write;
    wire memwb_mem_to_reg;

    // Hazard Detection
    hazard_detection_unit hazard_detector(
        .idex_mem_read(idex_mem_read),
        .idex_rd(idex_rd),
        .ifid_rs1(rs1),
        .ifid_rs2(rs2),
        .ifid_uses_rs1(ifid_uses_rs1),
        .ifid_uses_rs2(ifid_uses_rs2),
        .stall(hazard_stall)
    );

    // ID/EX pipeline register
    wire idex_flush;

    assign idex_flush =
        hazard_stall || branch_taken_ex || jump_id;

    id_ex_register idex(
        .clk(clk),
        .reset(reset),
        .flush(idex_flush),

        .pc_in(ifid_pc),
        .read_data1_in(read_data1),
        .read_data2_in(read_data2),
        .immediate_in(immediate_id),

        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),

        .reg_write_in(reg_write_id),
        .mem_read_in(mem_read_id),
        .mem_write_in(mem_write_id),
        .mem_to_reg_in(mem_to_reg_id),
        .alu_src_in(alu_src_id),
        .branch_in(branch_id),
        .alu_control_in(alu_control_id),

        .pc_out(idex_pc),
        .read_data1_out(idex_read_data1),
        .read_data2_out(idex_read_data2),
        .immediate_out(idex_immediate),

        .rs1_out(idex_rs1),
        .rs2_out(idex_rs2),
        .rd_out(idex_rd),

        .reg_write_out(idex_reg_write),
        .mem_read_out(idex_mem_read),
        .mem_write_out(idex_mem_write),
        .mem_to_reg_out(idex_mem_to_reg),
        .alu_src_out(idex_alu_src),
        .branch_out(idex_branch),
        .alu_control_out(idex_alu_control)
    );

    // Forwarding Unit
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit forwarding(
        .rs1_ex(idex_rs1),
        .rs2_ex(idex_rs2),
        .rd_exmem(exmem_rd),
        .reg_write_exmem(exmem_reg_write),
        .mem_to_reg_exmem(exmem_mem_to_reg),
        .rd_memwb(memwb_rd),
        .reg_write_memwb(memwb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Execute Stage
    reg [15:0] forwarded_a;
    reg [15:0] forwarded_b;

    always @(*) begin
        case (forward_a)
            2'b10: forwarded_a = exmem_alu_result;
            2'b01: forwarded_a = wb_data;
            default: forwarded_a = idex_read_data1;
        endcase

        case (forward_b)
            2'b10: forwarded_b = exmem_alu_result;
            2'b01: forwarded_b = wb_data;
            default: forwarded_b = idex_read_data2;
        endcase
    end

    wire [15:0] alu_input_b;
    wire [15:0] alu_result_ex;

    mux alu_mux(
        .input0(forwarded_b),
        .input1(idex_immediate),
        .select(idex_alu_src),
        .output_data(alu_input_b)
    );

    alu alu_unit(
        .A(forwarded_a),
        .B(alu_input_b),
        .alu_control(idex_alu_control),
        .result(alu_result_ex)
    );

    // Branch Decision
    branch_unit branch_logic(
        .rs1_value(forwarded_a),
        .rs2_value(forwarded_b),
        .pc(idex_pc),
        .offset(idex_immediate),
        .branch_taken(branch_equal_ex),
        .branch_target(branch_target_ex)
    );

    assign branch_taken_ex = idex_branch && branch_equal_ex;

    // EX/MEM Pipeline Register
    ex_mem_register exmem(
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result_ex),
        .read_data2_in(forwarded_b),
        .rd_in(idex_rd),
        .reg_write_in(idex_reg_write),
        .mem_read_in(idex_mem_read),
        .mem_write_in(idex_mem_write),
        .mem_to_reg_in(idex_mem_to_reg),
        .alu_result_out(exmem_alu_result),
        .read_data2_out(exmem_read_data2),
        .rd_out(exmem_rd),
        .reg_write_out(exmem_reg_write),
        .mem_read_out(exmem_mem_read),
        .mem_write_out(exmem_mem_write),
        .mem_to_reg_out(exmem_mem_to_reg)
    );

    // Memory Access Stage
    wire [15:0] memory_data;

    data_memory dmem(
        .clk(clk),
        .mem_read(exmem_mem_read),
        .mem_write(exmem_mem_write),
        .address(exmem_alu_result),
        .write_data(exmem_read_data2),
        .read_data(memory_data)
    );

    // MEM/WB Pipeline Register
    mem_wb_register memwb(
        .clk(clk),
        .reset(reset),
        .alu_result_in(exmem_alu_result),
        .memory_data_in(memory_data),
        .rd_in(exmem_rd),
        .reg_write_in(exmem_reg_write),
        .mem_to_reg_in(exmem_mem_to_reg),
        .alu_result_out(memwb_alu_result),
        .memory_data_out(memwb_memory_data),
        .rd_out(memwb_rd),
        .reg_write_out(memwb_reg_write),
        .mem_to_reg_out(memwb_mem_to_reg)
    );

    // Writeback Stage
    mux writeback_mux(
        .input0(memwb_alu_result),
        .input1(memwb_memory_data),
        .select(memwb_mem_to_reg),
        .output_data(wb_data)
    );

    assign wb_rd = memwb_rd;
    assign wb_reg_write = memwb_reg_write;

    // Next PC selection
    assign next_pc =
        branch_taken_ex ? branch_target_ex :
        jump_id ? jump_target_id :
        hazard_stall ? pc :
        pc + 16'd1;

endmodule