// -----------------------------------------------------------------------------
// auto_lock_timer.v
// Auto-lock timer for the digital doorlock FSM.
//
// enable = 1 while the FSM is in UNLOCK state.
// timeout becomes 1 after TIMEOUT_TICKS clock cycles.
// The timer is cleared when enable=0 or rst=1.
// remain_ticks is provided for FND/LCD countdown integration.
// -----------------------------------------------------------------------------
module auto_lock_timer #(
    parameter integer TIMEOUT_TICKS = 10000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    output reg         timeout,
    output reg  [31:0] count,
    output wire [31:0] remain_ticks
);

    assign remain_ticks = (count >= TIMEOUT_TICKS) ? 32'd0 : (TIMEOUT_TICKS - count);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else if (!enable) begin
            count   <= 32'd0;
            timeout <= 1'b0;
        end else begin
            if (count >= TIMEOUT_TICKS - 1) begin
                count   <= TIMEOUT_TICKS;
                timeout <= 1'b1;
            end else begin
                count   <= count + 32'd1;
                timeout <= 1'b0;
            end
        end
    end

endmodule
