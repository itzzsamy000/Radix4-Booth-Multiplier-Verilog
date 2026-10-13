`timescale 1ns / 1ps

module tb_booth8_baseline;

    reg signed [7:0] a, b;
    wire signed [15:0] product;
    reg signed [15:0] expected;
    integer i, j;

    booth8_baseline dut (
        .a(a),
        .b(b),
        .product(product)
    );

    initial begin
        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin
                a = i;
                b = j;
                expected = a * b;
                #1;

                if (product !== expected) begin
                    $display("FAIL: a=%0d b=%0d got=%0d expected=%0d",
                             a, b, product, expected);
                    $finish;
                end
            end
        end

        $display("PASS: All 65,536 signed input combinations matched.");
        $finish;
    end

endmodule