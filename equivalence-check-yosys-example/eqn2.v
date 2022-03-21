module eqn
    (
        input  clk_i,
        input  rst_i,
        input  ai,
        input  bi,
        output yo
    );
    reg        yo;
    always @ (posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            yo <= 1'b0;
        end else begin
            yo <= (ai|bi);
        end
    end
endmodule
