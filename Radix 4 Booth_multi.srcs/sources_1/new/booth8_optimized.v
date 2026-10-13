module booth8_optimized (
    input  signed [7:0]  a,
    input  signed [7:0]  b,
    output signed [15:0] product
);

    wire [8:0] booth_bits = {b, 1'b0};

    function signed [15:0] booth_pp;
        input signed [7:0] x;
        input [2:0] code;
        reg signed [15:0] x_ext;
        begin
            x_ext = {{8{x[7]}}, x};

            case (code)
                3'b000, 3'b111: booth_pp = 16'sd0;
                3'b001, 3'b010: booth_pp = x_ext;
                3'b011:         booth_pp = x_ext <<< 1;
                3'b100:         booth_pp = -(x_ext <<< 1);
                3'b101, 3'b110: booth_pp = -x_ext;
                default:        booth_pp = 16'sd0;
            endcase
        end
    endfunction

    wire signed [15:0] pp0 = booth_pp(a, booth_bits[2:0]);
    wire signed [15:0] pp1 = booth_pp(a, booth_bits[4:2]) <<< 2;
    wire signed [15:0] pp2 = booth_pp(a, booth_bits[6:4]) <<< 4;
    wire signed [15:0] pp3 = booth_pp(a, booth_bits[8:6]) <<< 6;

    // First carry-save compression: 3 partial products -> 2 vectors
    wire [15:0] sum1 = pp0 ^ pp1 ^ pp2;
    wire [15:0] carry1 =
        ((pp0 & pp1) | (pp0 & pp2) | (pp1 & pp2)) << 1;

    // Second compression: 3 vectors -> 2 vectors
    wire [15:0] sum2 = sum1 ^ carry1 ^ pp3;
    wire [15:0] carry2 =
        ((sum1 & carry1) | (sum1 & pp3) | (carry1 & pp3)) << 1;

    // Only one final carry-propagating addition
    assign product = sum2 + carry2;

endmodule