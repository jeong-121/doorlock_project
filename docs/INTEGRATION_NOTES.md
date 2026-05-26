# 팀원 연동 메모

## FSM 상태 코드

```verilog
IDLE   = 3'd0;  // 잠금/대기
INPUT  = 3'd1;  // 비밀번호 입력 중
CHECK  = 3'd2;  // 비밀번호 비교
UNLOCK = 3'd3;  // 잠금 해제
ALARM  = 3'd4;  // 3회 실패 알람
CHANGE = 3'd5;  // 비밀번호 변경
```

## LCD 연동 예시

- `state == IDLE`   : "LOCKED" 또는 "ENTER PASSWORD"
- `state == INPUT`  : "ENTER PASSWORD"
- `state == CHECK`  : "CHECKING"
- `state == UNLOCK` : "UNLOCKED"
- `state == ALARM`  : "ALARM!"
- `state == CHANGE` : "NEW PASSWORD"

## FND 연동 예시

- `digit_count_out`으로 입력된 자리 수를 표시하거나 `****` masking 처리
- `timer_remain_ticks / 1000`으로 자동잠금 남은 초 표시
- clock이 1 kHz일 때 `1000 tick = 1초`

## LED 연동 예시

- `locked_on` : 잠금 상태 LED
- `unlock_on` : 해제 상태 LED
- `alarm_on` : 알람 LED 점멸 enable
- `input_count_led[3:0]` : 입력 자리 수 표시

## Buzzer 연동 예시

- `beep_on` : 키 입력 시 짧은 beep
- `alarm_on` : 알람 상태에서 연속 buzzer 또는 주기적 beep
