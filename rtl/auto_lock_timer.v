// -----------------------------------------------------------------------------
// auto_lock_timer.v
// Generic active-high reset timer. With clk_1khz, TIMEOUT_TICKS=10000 means 10s.
// timeout stays high after expiration until enable=0 or rst=1.
// -----------------------------------------------------------------------------
module auto_lock_timer #(
    parameter integer TIMEOUT_TICKS = 10000
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  timeout
);

    reg [31:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else if (!enable) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else if (count >= TIMEOUT_TICKS - 1) begin
            count   <= count;
            timeout <= 1'b1;
        end else begin
            count   <= count + 32'd1;
            timeout <= 1'b0;
        end
    end

endmodule
