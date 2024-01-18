`timescale 1ns/1ns
/*
requirements
- unit level testing of each module
- mixture of directed + randomized test cases
- more than 10 test cases
- reusable (parameterized)
*/

`define assert(value1, value2) \
if (value1 !== value2) $display("time = %0t assertion failed with %0h !== %0h", $time, value1, value2); \
else $display("time = %0t assertion passed with %0h === %0h", $time, value1, value2);


module tb_multiplier;

// multiplier
reg [7:0] A, B;
reg S, V;
wire [15:0] Y_ref, Y;

// FA
reg a, b, cin;
wire s, cout, s_ref, cout_ref;

FA fa0(
    .a(a),
    .b(b),
    .cin(cin),
    .s(s),
    .cout(cout)
);

FA_reference fa_reference0(
    .a(a),
    .b(b),
    .cin(cin),
    .s(s_ref),
    .cout(cout_ref)
);

multiplier_reference UUT1(
    .A(A),
    .B(B),
    .S(S),
    .V(V),
    .Y(Y_ref)
);

multiplier UUT2(
    .A(A),
    .B(B),
    .S(S),
    .V(V),
    .Y(Y)
);

task verify_FA ();
begin
    repeat (10) begin
        a = $random;
        b = $random;
        cin = $random;
        #1;
        `assert({cout, s}, {cout_ref, s_ref});
    end
end
endtask

task verify_multiplier ();
begin
    // directed stimulus
    A = 8'h00;
    B = 8'h00;
    S = 1'b0;
    V = 1'b0;
    #1;
    `assert(Y, Y_ref);
    A = 8'h00;
    B = 8'h00;
    S = 1'b1;
    V = 1'b1;
    #1;
    `assert(Y, Y_ref);
    A = 8'hff;
    B = 8'h00;
    S = 1'b0;
    V = 1'b0;
    #1;
    `assert(Y, Y_ref);
    A = 8'hff;
    B = 8'hff;
    S = 1'b0;
    V = 1'b0;
    #1;
    `assert(Y, Y_ref);
    A = 8'hff;
    B = 8'hff;
    S = 1'b1;
    V = 1'b0;
    #1;
    `assert(Y, Y_ref);
    // random stimulus
    repeat (30) begin
        A = $random;
        B = $random;
        S = $random;
        V = $random;
        #1;
        `assert(Y, Y_ref);
    end
end
endtask

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    //verify_FA();
    verify_multiplier();
    $finish;
end

endmodule