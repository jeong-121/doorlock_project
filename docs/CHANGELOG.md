# 변경점 정리

## 수정 목적
기존 도어락 FSM 초안에서 reset 미연결, 4자리 입력 검증 부재, 비밀번호 변경 검증 부재, 알람 상태 탈출 불가, 팀원 연동용 출력 부족 문제를 보완했다.

## 주요 변경점

### 1. reset 입력 실제 연결
- 기존 `top_module`은 `assign rst = 1'b0;`으로 reset이 항상 비활성화되어 있었다.
- 수정 후 `TACT_SW[13]`을 reset으로 연결했다.
- FPGA 전원 인가 후 상태 레지스터와 비밀번호/카운터가 명확히 초기화된다.

### 2. 4자리 입력 완료 검증 추가
- 기존 `digit_count`는 `reg [1:0]`라서 0~3까지만 표현 가능했다.
- 수정 후 `reg [2:0] digit_count`로 변경하여 0~4를 표현한다.
- `digit_count == 4`일 때만 `CHECK` 상태로 진입한다.
- 4자리 미만 입력 후 `#`을 누르면 입력을 취소하고 `IDLE`로 복귀한다.

### 3. 비밀번호 변경 검증 강화
- 기존에는 변경 모드에서 4자리 미만 입력 후 `#`을 눌러도 새 비밀번호가 저장될 수 있었다.
- 수정 후 `CHANGE` 상태에서도 `digit_count == 4`일 때만 `saved_password <= input_buffer`를 수행한다.
- 4자리 미만이면 저장하지 않고 변경을 취소한다.

### 4. ALARM 해제 신호 추가
- 기존 `ALARM` 상태는 reset 외에는 탈출 조건이 없었다.
- 수정 후 `alarm_clear` 입력을 추가했다.
- `TACT_SW[14]`를 `alarm_clear`로 연결했다.
- 3회 실패 후 알람 상태에서 관리자 해제/시연용 해제가 가능하다.

### 5. 내부 문 열림 버튼 유지
- `auto_open` 입력은 유지했다.
- `TACT_SW[12]`를 내부 문 열림 버튼으로 사용한다.
- 누르면 즉시 `UNLOCK` 상태로 진입한다.

### 6. 팀원 연동용 출력 보강
다른 팀원이 LCD, FND, LED, buzzer를 구현할 때 사용할 수 있도록 출력 신호를 추가했다.

- `locked_on` : 잠금 상태 표시
- `input_mode_on` : 비밀번호 입력 중 표시
- `change_mode_on` : 비밀번호 변경 모드 표시
- `beep_on` : 키 입력 1클럭 펄스
- `fail_count_out` : 실패 횟수 출력
- `digit_count_out` : 현재 입력 자리 수 출력
- `timer_count_out` : 자동잠금 타이머 경과 tick
- `timer_remain_ticks` : 자동잠금까지 남은 tick

### 7. 자동잠금 타이머 출력 확장
- 기존 timer는 `timeout`만 출력했다.
- 수정 후 `count`, `remain_ticks`를 추가했다.
- FND에 남은 시간을 표시하거나 LCD에 countdown을 표시할 수 있다.

### 8. 기본 비밀번호 유지
- 기본 비밀번호는 기존과 동일하게 `16'h1234`다.
- 이는 16진수 숫자값이 아니라 BCD 형태로 1, 2, 3, 4 네 자리 숫자를 저장한 것이다.

## 파일 구조

```text
rtl/
  top_module.v
  fsm_module.v
  auto_lock_timer.v

docs/
  CHANGELOG.md
  INTEGRATION_NOTES.md

tb/
  tb_fsm_module.v
```

## 주의사항
- 현재 `TACT_SW[11]`은 change/admin 입력으로 사용된다. 실제 keypad의 `A` 키와 연결하려면 keypad decoder의 `A_pulse`를 `change`에 연결하면 된다.
- 현재 `TACT_SW[10]`은 enter, 즉 `#` 키 역할이다.
- 실제 보드에서는 TACT 스위치 채터링 방지를 위해 디바운스 모듈을 앞단에 두는 것이 좋다.
