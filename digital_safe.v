module digital_safe #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer DEBOUNCE_CYCLES = 1_000_000,
    parameter integer ALARM_SECONDS = 2,
    parameter integer LOCKOUT_SECONDS = 15,
    parameter integer MAX_ATTEMPTS = 3,
    parameter [15:0] USER_PIN = 16'hA5C3,
    parameter [15:0] ADMIN_CODE = 16'hC0DE
)(
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    input wire [15:0] SW,
    input wire BTNC, BTNU, BTNL, BTNR, BTND,
    output reg [15:0] LED,
    output wire [6:0] SEG,
    output wire [7:0] AN,
    output wire DP
);
    localparam [2:0] LOCKED=0, CHECKING=1, UNLOCKED=2, ALARM=3, LOCKOUT=4;
    // CPU_RESETN is active-low; rst is the active-high synchronous reset.
    wire rst = ~CPU_RESETN;
    wire submit_pulse, up_pulse, left_pulse, tamper_pulse, lock_pulse;
    wire unused_stable_c,unused_stable_u,unused_stable_l,unused_stable_r,unused_stable_d;
    reg [15:0] captured_pin;
    wire pin_match, limit_violation, alarm_request, tamper_latched;
    reg failed_check;
    wire override_pulse, tick_1hz, alarm_done, lockout_done, alarm_led;
    wire [1:0] attempts, override_progress;
    reg [2:0] state;
    localparam integer ALARM_WIDTH = (ALARM_SECONDS < 2) ? 1 : $clog2(ALARM_SECONDS + 1);
    localparam integer LOCKOUT_WIDTH = (LOCKOUT_SECONDS < 2) ? 1 : $clog2(LOCKOUT_SECONDS + 1);
    wire [ALARM_WIDTH-1:0] alarm_elapsed;
    wire [LOCKOUT_WIDTH-1:0] lockout_elapsed;
    wire clear_counters = override_pulse || lockout_done;
    wire [7:0] remaining = (state == ALARM)   ? ((ALARM_SECONDS >= alarm_elapsed) ? (ALARM_SECONDS - alarm_elapsed) : 8'd0) :
                           (state == LOCKOUT) ? ((LOCKOUT_SECONDS >= lockout_elapsed) ? (LOCKOUT_SECONDS - lockout_elapsed) : 8'd0) : 8'd0;
    wire [3:0] status_code = (state == LOCKED) ? 4'h1 :
                             (state == CHECKING) ? 4'hC :
                             (state == UNLOCKED) ? 4'h2 :
                             (state == ALARM) ? 4'hA : 4'hD;
    wire [31:0] display_value = 32'd0;

    safe_button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) debounce_submit (
        .clk(CLK100MHZ), .reset(rst), .button_in(BTNC),
        .stable_level(unused_stable_c), .press_pulse(submit_pulse)
    );
    safe_button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) debounce_up (
        .clk(CLK100MHZ), .reset(rst), .button_in(BTNU),
        .stable_level(unused_stable_u), .press_pulse(up_pulse)
    );
    safe_button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) debounce_left (
        .clk(CLK100MHZ), .reset(rst), .button_in(BTNL),
        .stable_level(unused_stable_l), .press_pulse(left_pulse)
    );
    safe_button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) debounce_tamper (
        .clk(CLK100MHZ), .reset(rst), .button_in(BTNR),
        .stable_level(unused_stable_r), .press_pulse(tamper_pulse)
    );
    safe_button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) debounce_lock (
        .clk(CLK100MHZ), .reset(rst), .button_in(BTND),
        .stable_level(unused_stable_d), .press_pulse(lock_pulse)
    );

    assign pin_match = (state == CHECKING) && (captured_pin == USER_PIN);

    reg [1:0] attempt_reg;
    assign attempts = attempt_reg;

    always @(posedge CLK100MHZ) begin
        if (rst || clear_counters || (state == UNLOCKED)) begin
            attempt_reg <= 2'd0;
        end else if (failed_check) begin
            if (attempt_reg < 2'd3)
                attempt_reg <= attempt_reg + 1'b1;
        end
    end

    reg tamper_latched_reg;
    assign tamper_latched = tamper_latched_reg;

    always @(posedge CLK100MHZ) begin
        if (rst || clear_counters) begin
            tamper_latched_reg <= 1'b0;
        end else if (tamper_pulse && (state == LOCKED)) begin
            tamper_latched_reg <= 1'b1;
        end
    end

    assign limit_violation = (attempts >= MAX_ATTEMPTS[1:0]);
    assign alarm_request = limit_violation || tamper_latched;
    assign override_pulse = 1'b0;
    assign override_progress = 2'd0;
    localparam integer TICK_LIMIT = (CLK_HZ > 0) ? CLK_HZ : 1;
    localparam integer TICK_WIDTH = (TICK_LIMIT < 2) ? 1 : $clog2(TICK_LIMIT + 1);
    reg [TICK_WIDTH-1:0] tick_counter;
    reg tick_1hz_reg;
    assign tick_1hz = tick_1hz_reg;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            tick_counter <= {TICK_WIDTH{1'b0}};
            tick_1hz_reg <= 1'b0;
        end else if (tick_counter >= TICK_LIMIT - 1) begin
            tick_counter <= {TICK_WIDTH{1'b0}};
            tick_1hz_reg <= 1'b1;
        end else begin
            tick_counter <= tick_counter + 1'b1;
            tick_1hz_reg <= 1'b0;
        end
    end
    safe_timer #(.DURATION_SECONDS(ALARM_SECONDS)) timer_alarm (
        .clk(CLK100MHZ),
        .reset(rst),
        .enable(state == ALARM),
        .tick(tick_1hz),
        .elapsed(alarm_elapsed),
        .done(alarm_done)
    );

    safe_timer #(.DURATION_SECONDS(LOCKOUT_SECONDS)) timer_lockout (
        .clk(CLK100MHZ),
        .reset(rst),
        .enable(state == LOCKOUT),
        .tick(tick_1hz),
        .elapsed(lockout_elapsed),
        .done(lockout_done)
    );
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            state <= LOCKED;
            captured_pin <= 16'h0000;
            failed_check <= 1'b0;
        end else begin
            failed_check <= 1'b0;
            if (override_pulse) begin
                state <= LOCKED;
            end else if (alarm_request && (state != ALARM) && (state != LOCKOUT)) begin
                state <= ALARM;
            end else begin
                case (state)
                    LOCKED: begin
                        if (submit_pulse) begin
                            captured_pin <= SW;
                            state <= CHECKING;
                        end
                    end
                    CHECKING: begin
                        if (lock_pulse) begin
                            state <= LOCKED;
                        end else if (pin_match) begin
                            state <= UNLOCKED;
                        end else begin
                            failed_check <= 1'b1;
                            state <= LOCKED;
                        end
                    end
                    UNLOCKED: begin
                        if (lock_pulse)
                            state <= LOCKED;
                    end
                    ALARM: begin
                        if (alarm_done)
                            state <= LOCKOUT;
                    end
                    LOCKOUT: begin
                        if (lockout_done)
                            state <= LOCKED;
                    end
                    default: state <= LOCKED;
                endcase
            end
        end
    end
    localparam integer BLINK_LIMIT = (CLK_HZ > 1) ? (CLK_HZ / 2) : 1;
    localparam integer BLINK_WIDTH = (BLINK_LIMIT < 2) ? 1 : $clog2(BLINK_LIMIT + 1);
    reg [BLINK_WIDTH-1:0] blink_counter;
    reg blink_tick;
    reg alarm_blink_reg;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            blink_counter <= {BLINK_WIDTH{1'b0}};
            blink_tick <= 1'b0;
        end else if (blink_counter >= BLINK_LIMIT - 1) begin
            blink_counter <= {BLINK_WIDTH{1'b0}};
            blink_tick <= 1'b1;
        end else begin
            blink_counter <= blink_counter + 1'b1;
            blink_tick <= 1'b0;
        end
    end

    always @(posedge CLK100MHZ) begin
        if (rst || (state != ALARM)) begin
            alarm_blink_reg <= 1'b1;
        end else if (blink_tick) begin
            alarm_blink_reg <= ~alarm_blink_reg;
        end
    end

    assign alarm_led = (state == ALARM) && alarm_blink_reg;
    assign SEG = 7'b1111111;
    assign AN = 8'hFF;
    assign DP = 1'b1;

    always @(*) begin
        LED = 16'b0;
        LED[0] = (state != UNLOCKED);     // locked indicator
        LED[1] = (state == UNLOCKED);     // simulated unlock output
        LED[2] = alarm_led;               // alarm indicator
        LED[4:3] = attempts;              // attempt count
        LED[5] = tamper_latched;          // tamper indicator
    end
endmodule

module safe_button_debounce #(
    parameter integer DEBOUNCE_CYCLES = 1
)(
    input wire clk,
    input wire reset,
    input wire button_in,
    output reg stable_level,
    output reg press_pulse
);
    localparam integer COUNTER_WIDTH =
        (DEBOUNCE_CYCLES < 2) ? 1 : $clog2(DEBOUNCE_CYCLES);
    reg [COUNTER_WIDTH-1:0] debounce_count;

    always @(posedge clk) begin
        if (reset) begin
            debounce_count <= {COUNTER_WIDTH{1'b0}};
            stable_level <= 1'b0;
            press_pulse <= 1'b0;
        end else begin
            press_pulse <= 1'b0;
            if (button_in == stable_level) begin
                debounce_count <= {COUNTER_WIDTH{1'b0}};
            end else if (debounce_count == DEBOUNCE_CYCLES - 1) begin
                debounce_count <= {COUNTER_WIDTH{1'b0}};
                stable_level <= button_in;
                if (button_in)
                    press_pulse <= 1'b1;
            end else begin
                debounce_count <= debounce_count + 1'b1;
            end
        end
    end
endmodule

module safe_timer #(
    parameter integer DURATION_SECONDS = 1,
    parameter integer TIMER_WIDTH = (DURATION_SECONDS < 2) ? 1 : $clog2(DURATION_SECONDS + 1)
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire tick,
    output wire [TIMER_WIDTH-1:0] elapsed,
    output wire done
);
    reg [TIMER_WIDTH-1:0] elapsed_reg;
    reg done_reg;

    assign elapsed = elapsed_reg;
    assign done = done_reg;

    always @(posedge clk) begin
        if (reset || !enable) begin
            elapsed_reg <= {TIMER_WIDTH{1'b0}};
            done_reg <= 1'b0;
        end else begin
            done_reg <= 1'b0;
            if (tick) begin
                if (elapsed_reg + 1'b1 >= DURATION_SECONDS) begin
                    elapsed_reg <= DURATION_SECONDS[TIMER_WIDTH-1:0];
                    done_reg <= 1'b1;
                end else begin
                    elapsed_reg <= elapsed_reg + 1'b1;
                end
            end
        end
    end
endmodule
