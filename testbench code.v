
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg reset;

    wire [15:0] pc;
    wire [15:0] instruction;

    integer i;
    integer errors;
    integer stall_count;
    integer branch_count;
    integer jump_count;

    // =========================================
    // PROCESSOR UNDER TEST
    // =========================================

    pipelined_processor dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction)
    );


    // =========================================
    // CLOCK GENERATION
    // 10 ns clock period
    // =========================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // =========================================
    // COUNT HAZARDS AND CONTROL-FLOW EVENTS
    // =========================================

    always @(posedge clk) begin
        if (!reset) begin
            if (dut.hazard_stall)
                stall_count = stall_count + 1;

            if (dut.branch_taken_ex)
                branch_count = branch_count + 1;

            if (dut.jump_id)
                jump_count = jump_count + 1;
        end
    end


    // =========================================
    // TEST PROGRAM AND INITIALIZATION
    // =========================================

    initial begin
        reset = 1'b1;
        errors = 0;
        stall_count = 0;
        branch_count = 0;
        jump_count = 0;

        // Allow instruction_memory's own initial block
        // to run before loading our test program.
        #1;

        // Initialize instruction memory.
        for (i = 0; i < 256; i = i + 1)
            dut.imem.memory[i] = 16'b0;

        // Initialize data memory.
        for (i = 0; i < 256; i = i + 1)
            dut.dmem.memory[i] = 16'b0;


        // =====================================
        // INSTRUCTION PROGRAM
        // =====================================

        // Address 0: ADD R3, R1, R2
        // Expected: R3 = 4 + 7 = 11
        dut.imem.memory[0] =
            16'b0000_011_001_010_000;

        // Address 1: SUB R4, R3, R1
        // Expected: R4 = 11 - 4 = 7
        // Tests forwarding from an earlier ADD.
        dut.imem.memory[1] =
            16'b0000_100_011_001_001;

        // Address 2: AND R5, R1, R2
        // Expected: R5 = 4 AND 7 = 4
        dut.imem.memory[2] =
            16'b0000_101_001_010_010;

        // Address 3: OR R6, R1, R2
        // Expected: R6 = 4 OR 7 = 7
        dut.imem.memory[3] =
            16'b0000_110_001_010_011;

        // Address 4: ADDI R7, R1, 5
        // Expected: R7 = 4 + 5 = 9
        dut.imem.memory[4] =
            16'b0101_111_001_000101;

        // Address 5: STORE R3, 0(R1)
        // Expected: data_memory[4] = 11
        dut.imem.memory[5] =
            16'b0111_011_001_000000;

        // Address 6: LOAD R2, 0(R1)
        // Expected: R2 = data_memory[4] = 11
        dut.imem.memory[6] =
            16'b0110_010_001_000000;

        // Address 7: ADD R4, R2, R3
        // Expected: R4 = 11 + 11 = 22
        // Tests a LOAD immediately followed by its consumer.
        dut.imem.memory[7] =
            16'b0000_100_010_011_000;

        // Address 8: BEQ R4, R4, 2
        // Always taken; target = 8 + 2 = 10.
        dut.imem.memory[8] =
            16'b1000_100_100_000010;

        // Address 9: ADDI R0, R1, 9
        // Wrong-path instruction.
        // R0 should remain zero if flushing works.
        dut.imem.memory[9] =
            16'b0101_000_001_001001;

        // Address 10: ADDI R5, R1, 2
        // Expected: R5 = 4 + 2 = 6
        dut.imem.memory[10] =
            16'b0101_101_001_000010;

        // Address 11: BEQ R1, R2, 2
        // Not taken because R1 = 4 and R2 = 11.
        dut.imem.memory[11] =
            16'b1000_001_010_000010;

        // Address 12: ADDI R6, R1, 3
        // Expected: R6 = 4 + 3 = 7
        dut.imem.memory[12] =
            16'b0101_110_001_000011;

        // Address 13: JUMP 15
        // Expected: PC redirects to address 15.
        dut.imem.memory[13] =
            16'b1001_000000001111;

        // Address 14: ADDI R0, R1, 20
        // Wrong-path instruction after the jump.
        dut.imem.memory[14] =
            16'b0101_000_001_010100;

        // Address 15: JUMP 15
        // Self-loop to stop the test program from
        // executing uninitialized instructions.
        dut.imem.memory[15] =
            16'b1001_000000001111;


        // =====================================
        // RESET PROCESSOR
        // =====================================

        repeat (2) @(posedge clk);

        @(negedge clk);

        reset = 1'b0;

        // Initialize source registers after reset.
        dut.rf.registers[0] = 16'd0;
        dut.rf.registers[1] = 16'd4;
        dut.rf.registers[2] = 16'd7;
        dut.rf.registers[3] = 16'd0;
        dut.rf.registers[4] = 16'd0;
        dut.rf.registers[5] = 16'd0;
        dut.rf.registers[6] = 16'd0;
        dut.rf.registers[7] = 16'd0;


        // =====================================
        // RUN PROGRAM
        // =====================================

        // Allow enough cycles for execution and
        // pipeline write-back to finish.
        repeat (40) @(posedge clk);

        #1;

        $display("");
        $display("====================================");
        $display("  PIPELINED16 PROCESSOR TEST RESULTS");
        $display("====================================");

        $display("R0 = %0d", dut.rf.registers[0]);
        $display("R1 = %0d", dut.rf.registers[1]);
        $display("R2 = %0d", dut.rf.registers[2]);
        $display("R3 = %0d", dut.rf.registers[3]);
        $display("R4 = %0d", dut.rf.registers[4]);
        $display("R5 = %0d", dut.rf.registers[5]);
        $display("R6 = %0d", dut.rf.registers[6]);
        $display("R7 = %0d", dut.rf.registers[7]);

        $display("Data memory[4] = %0d",
                 dut.dmem.memory[4]);

        $display("Load-use stalls observed = %0d",
                 stall_count);

        $display("Taken branches observed = %0d",
                 branch_count);

        $display("Jumps observed = %0d",
                 jump_count);

        $display("------------------------------------");


        // =====================================
        // CHECK EXPECTED RESULTS
        // =====================================

        if (dut.rf.registers[0] !== 16'd0) begin
            $display("FAIL: R0 changed; a wrong-path instruction may have executed.");
            errors = errors + 1;
        end

        if (dut.rf.registers[1] !== 16'd4) begin
            $display("FAIL: R1 should equal 4.");
            errors = errors + 1;
        end

        if (dut.rf.registers[2] !== 16'd11) begin
            $display("FAIL: LOAD result in R2 should equal 11.");
            errors = errors + 1;
        end

        if (dut.rf.registers[3] !== 16'd11) begin
            $display("FAIL: ADD result in R3 should equal 11.");
            errors = errors + 1;
        end

        if (dut.rf.registers[4] !== 16'd22) begin
            $display("FAIL: dependent ADD result in R4 should equal 22.");
            errors = errors + 1;
        end

        if (dut.rf.registers[5] !== 16'd6) begin
            $display("FAIL: R5 should equal 6.");
            errors = errors + 1;
        end

        if (dut.rf.registers[6] !== 16'd7) begin
            $display("FAIL: R6 should equal 7.");
            errors = errors + 1;
        end

        if (dut.rf.registers[7] !== 16'd9) begin
            $display("FAIL: R7 should equal 9.");
            errors = errors + 1;
        end

        if (dut.dmem.memory[4] !== 16'd11) begin
            $display("FAIL: STORE result in memory[4] should equal 11.");
            errors = errors + 1;
        end

        if (stall_count < 1) begin
            $display("FAIL: Expected a load-use stall.");
            errors = errors + 1;
        end

        if (branch_count < 1) begin
            $display("FAIL: Expected a taken branch.");
            errors = errors + 1;
        end

        if (jump_count < 1) begin
            $display("FAIL: Expected a jump.");
            errors = errors + 1;
        end


        // =====================================
        // FINAL STATUS
        // =====================================

        if (errors == 0) begin
            $display("PASS: All programmed checks passed.");
        end
        else begin
            $display("FAIL: %0d check(s) failed.", errors);
        end

        $display("====================================");
        $finish;
    end

endmodule
