module digital_safe #(
 parameter integer CLK_HZ=100_000_000,
 parameter integer DEBOUNCE_CYCLES=1_000_000,
 parameter integer ALARM_SECONDS=2,
 parameter integer LOCKOUT_SECONDS=15,
 parameter [15:0] USER_PIN=16'hA5C3,
 parameter [15:0] ADMIN_CODE=16'hC0DE
)(input wire CLK100MHZ,input wire CPU_RESETN,input wire [15:0] SW,
 input wire BTNC,BTNU,BTNL,BTNR,BTND,
 output reg [15:0] LED,output wire [6:0] SEG,output wire [7:0] AN,output wire DP);
 localparam [2:0] LOCKED=0,CHECKING=1,UNLOCKED=2,ALARM=3,LOCKOUT=4;
 localparam [7:0] ALARM_DURATION=(ALARM_SECONDS<1)?8'd1:(ALARM_SECONDS>255)?8'd255:ALARM_SECONDS[7:0];
 localparam [7:0] LOCKOUT_DURATION=(LOCKOUT_SECONDS<1)?8'd1:(LOCKOUT_SECONDS>255)?8'd255:LOCKOUT_SECONDS[7:0];
 wire rst=~CPU_RESETN;
 reg [15:0] sw_meta,sw_sync;
 always @(posedge CLK100MHZ) if(rst) begin sw_meta<=0;sw_sync<=0;end else begin sw_meta<=SW;sw_sync<=sw_meta;end
 wire submit,up,left,tamper,manual_lock;
 wire unused0,unused1,unused2,unused3,unused4;
 button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db_c(CLK100MHZ,rst,BTNC,unused0,submit);
 button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db_u(CLK100MHZ,rst,BTNU,unused1,up);
 button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db_l(CLK100MHZ,rst,BTNL,unused2,left);
 button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db_r(CLK100MHZ,rst,BTNR,unused3,tamper);
 button_debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db_d(CLK100MHZ,rst,BTND,unused4,manual_lock);
 wire [15:0] captured_pin; wire captured_valid,pin_match;
 pin_capture cap(CLK100MHZ,rst,submit,sw_sync,captured_pin,captured_valid);
 pin_compare #(.USER_PIN(USER_PIN)) cmp(captured_pin,pin_match);
 wire [1:0] failed_count; wire third_failure,wrong,correct,start_alarm,start_lockout;
 wire tamper_latched,tamper_event,admin_done,admin_recover;
 wire [1:0] admin_progress; wire tick,alarm_done,lockout_done,blink;
 wire [7:0] alarm_remaining,lockout_remaining; wire [2:0] state;
 wire clear_attempts=correct || admin_recover || lockout_done;
 failed_attempt_counter attempts(CLK100MHZ,rst,wrong,clear_attempts,failed_count,third_failure);
 tamper_detector td(CLK100MHZ,rst,tamper,admin_recover,tamper_latched,tamper_event);
 admin_sequence admin_seq(CLK100MHZ,rst,left,up,admin_progress,admin_done);
 recovery_controller #(.ADMIN_CODE(ADMIN_CODE)) recovery(CLK100MHZ,rst,admin_done,sw_sync,admin_recover);
 tick_generator #(.CLK_HZ(CLK_HZ)) ticks(CLK100MHZ,rst,tick);
 countdown_timer #(.MAX_SECONDS(ALARM_DURATION)) alarm_timer(CLK100MHZ,rst,tick,start_alarm,state!=ALARM,ALARM_DURATION,alarm_remaining,alarm_done);
 countdown_timer #(.MAX_SECONDS(LOCKOUT_DURATION)) lockout_timer(CLK100MHZ,rst,tick,start_lockout,state!=LOCKOUT,LOCKOUT_DURATION,lockout_remaining,lockout_done);
 alarm_blinker ab(CLK100MHZ,rst,tick,state==ALARM,blink);
 safe_fsm fsm(CLK100MHZ,rst,captured_valid,pin_match,third_failure,tamper_latched,tamper_event,admin_recover,alarm_done,lockout_done,manual_lock,state,wrong,correct,start_alarm,start_lockout);
 wire [7:0] remaining=(state==ALARM)?alarm_remaining:(state==LOCKOUT)?lockout_remaining:8'd0;
 wire [31:0] display_digits;
 display_formatter fmt(state,failed_count,remaining,display_digits);
 sevenseg_mux mux(CLK100MHZ,rst,display_digits,SEG,AN,DP);
 always @* begin
  LED=16'b0; LED[0]=(state!=UNLOCKED); LED[1]=(state==UNLOCKED);
  LED[2]=(state==ALARM) & blink; LED[3]=(state==LOCKOUT); LED[5]=tamper_latched;
  // Match INTERFACE_CONTRACTS: LED[5] is tamper; LED[8:6] show cumulative admin progress.
  case(admin_progress) 0:LED[8:6]=3'b000;1:LED[8:6]=3'b001;2:LED[8:6]=3'b011;3:LED[8:6]=3'b111;endcase
 end
endmodule
