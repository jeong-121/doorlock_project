// -----------------------------------------------------------------------------
// auto_lock_timer.v
// 10-second auto-lock timer for 1 kHz system clock.
//
// enable = 1 while the FSM is in UNLOCK state.
// timeout becomes 1 after TIMEOUT_TICKS clock cycles.
// The timer is cleared when enable=0 or rst=1.
// -----------------------------------------------------------------------------
module auto_lock_timer #(
    parameter integer TIMEOUT_TICKS = 10000  // 1 kHz * 10 sec = 10,000 ticks
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
        end else begin
            if (count >= TIMEOUT_TICKS - 1) begin
                count   <= count;
                timeout <= 1'b1;
            end else begin
                count   <= count + 32'd1;
                timeout <= 1'b0;
            end
        end
    end

endmodule
