module HA
(
    input a,
    input b,
    output s,
    output c
);

xor xor0 (s, a, b);
and and0 (c, a, b);

endmodule

module FA
(
    input a,
    input b,
    input cin,
    output s,
    output cout
);

wire ha0_s, ha0_cout, ha1_cout;

HA ha0 (.a(a), .b(b), .s(ha0_s), .c(ha0_cout));
HA ha1 (.a(cin), .b(ha0_s), .s(s), .c(ha1_cout));
or or0 (cout, ha0_cout, ha1_cout);
endmodule

module FA_reference
(
    input a,
    input b,
    input cin,
    output s,
    output cout
);

assign {cout, s} = a + b + cin;

endmodule

module multiplier_reference
(
    input [7:0] A,
    input [7:0] B,
    input S,
    input V,
    output reg [15:0] Y
);

wire [7:0] u_uab, u_lab, s_uab, s_lab;
assign u_uab = $unsigned(A[7:4]) * $unsigned(B[7:4]);
assign u_lab = $unsigned(A[3:0]) * $unsigned(B[3:0]);
assign s_uab = $signed(A[7:4]) * $signed(B[7:4]);
assign s_lab = $signed(A[3:0]) * $signed(B[3:0]);

always @(*) begin
    case({S,V})
        2'b00: Y = $unsigned(A) *  $unsigned(B);
        2'b01: Y = {u_uab, u_lab};
        2'b10: Y = $signed(A) * $signed(B);
        2'b11: Y = {s_uab, s_lab};
    endcase
end

endmodule

// parameterized signed/unsigned baugh-wooley array multiplier
module unit_multiplier #(
    parameter WIDTH = 4
) (
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input S,
    output [2*WIDTH-1:0] Y
);

// x, y order
wire and_array [WIDTH-1:0] [WIDTH-1:0]; // results

genvar i, j;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin
        for (j = 0; j < WIDTH; j = j + 1) begin
            if ((j == WIDTH-1 && i != WIDTH-1) || (i == WIDTH-1 && j != WIDTH-1)) begin
                assign and_array[i][j] = S ? ~(A[i] & B[j]) : A[i] & B[j];
            end
            else begin
                assign and_array[i][j] = A[i] & B[j];
            end
        end
    end
endgenerate

wire FA_x [WIDTH-1:0] [WIDTH-2:0];
wire FA_y [WIDTH-1:0] [WIDTH-1:0];

// connections for FA
genvar k, l;
generate
    for (k = 0; k < WIDTH; k = k + 1) begin
        for (l = 0; l < WIDTH - 1; l = l + 1) begin
            if (k == 0) begin
                FA fa0(.a(FA_y[k][l]), .b(and_array[k][l+1]), .cin(FA_x[k][l]), .s(Y[l+1]), .cout(FA_x[k+1][l]));
            end
            else if (k == WIDTH-1) begin
                FA fa0(.a(FA_y[k][l]), .b(and_array[k][l+1]), .cin(FA_x[k][l]), .s(FA_y[k-1][l+1]), .cout(FA_y[k][l+1]));
            end
            else begin
                FA fa0(.a(FA_y[k][l]), .b(and_array[k][l+1]), .cin(FA_x[k][l]), .s(FA_y[k-1][l+1]), .cout(FA_x[k+1][l]));
            end
        end
    end
endgenerate

// initial connections for FA_x
genvar m;
generate
    for (m = 0; m < WIDTH - 1; m = m + 1) begin
        assign FA_x[0][m] = 1'b0;
    end
endgenerate

// initial connections for FA_y
genvar n;
generate
    for (n = 0; n < WIDTH; n = n + 1) begin
        if (n == WIDTH-1) begin
            assign FA_y[n][0] = S ? 1'b1 : 1'b0;
        end
        else begin
            assign FA_y[n][0] = and_array[n+1][0];
        end
    end
endgenerate

// connections for output Y
genvar o;
generate
    for (o = 0; o < WIDTH - 1; o = o + 1) begin
        assign Y[WIDTH+o] = FA_y[o][WIDTH-1];
    end
endgenerate

assign Y[0] = and_array[0][0];
assign Y[2*WIDTH-1] = S ? 1'b1 ^ FA_y[WIDTH-1][WIDTH-1] : FA_y[WIDTH-1][WIDTH-1];

endmodule

// student multiplier
module multiplier
(
    input [7:0] A,
    input [7:0] B,
    input S,
    input V,
    output [15:0] Y
);

wire [15:0] Y_nonvectorized, Y_vectorized;
assign Y = V ? Y_vectorized : Y_nonvectorized;

unit_multiplier #(.WIDTH(4)) unit_mult4_high (.A(A[7:4]), .B(B[7:4]), .S(S), .Y(Y_vectorized[15:8]));
unit_multiplier #(.WIDTH(4)) unit_mult4_low (.A(A[3:0]), .B(B[3:0]), .S(S), .Y(Y_vectorized[7:0]));
unit_multiplier #(.WIDTH(8)) unit_mult8 (.A(A), .B(B), .S(S), .Y(Y_nonvectorized));

endmodule