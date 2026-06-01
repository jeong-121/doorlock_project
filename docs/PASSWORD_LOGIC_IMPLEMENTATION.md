# Password Logic Implementation

## 1. 구현 범위

본 구현은 디지털 도어락 FSM 통합 명세서의 C 담당 영역인 비밀번호 로직을 기준으로 작성했습니다.

담당 기능은 다음 네 가지입니다.

1. 비교기
2. 비밀번호 변경 로직
3. 시도 카운터
4. 자동잠금 타이머

## 2. 비교기

`CHECK` 상태에서 현재 입력 버퍼와 저장된 비밀번호를 비교합니다.

```verilog
if (input_buffer == saved_password)
```

일치하면 `UNLOCK` 상태로 이동하고, 실패 카운터를 0으로 초기화합니다.

## 3. 시도 카운터

비밀번호가 틀릴 때마다 `fail_count`가 증가합니다.

- 1회 실패: `IDLE` 복귀
- 2회 실패: `IDLE` 복귀
- 3회 실패: `ALARM` 진입

```verilog
if (fail_count == 2'd2) begin
    alarm_on <= 1'b1;
    state    <= ALARM;
end
```

## 4. 비밀번호 변경

`UNLOCK` 상태에서 `change` 버튼을 누르면 `CHANGE` 상태로 이동합니다.
새 4자리 비밀번호 입력 후 `enter`를 누르면 `saved_password`가 갱신되고 다시 잠금 상태로 돌아갑니다.

```verilog
saved_password <= input_buffer;
```

현재 팀 명세 기준으로는 새 비밀번호 재확인 입력은 포함하지 않았습니다.

## 5. 자동잠금 타이머

`auto_lock_timer.v`를 별도 모듈로 분리했습니다.

- `enable=1`: `UNLOCK` 상태에서 카운트 시작
- `enable=0`: 카운터 초기화
- `timeout=1`: 설정 시간 경과

10초 자동잠금 기준:

```text
clk_1khz = 1,000 Hz
10 sec = 10,000 clock ticks
```

`fsm_module.v`의 `UNLOCK` 상태에는 다음 전이를 추가했습니다.

```verilog
if (auto_lock_timeout) begin
    unlock_on <= 1'b0;
    state     <= IDLE;
end
```

## 6. 테스트벤치 검증 항목

`tb/tb_fsm_module.v`는 다음 케이스를 검증합니다.

1. 기본 비밀번호 `1234` 입력 성공
2. 자동잠금 타이머 만료 후 `IDLE` 복귀
3. 비밀번호 3회 실패 시 `ALARM` 진입
4. 리셋 후 경보 해제
5. 비밀번호를 `9999`로 변경 후 새 비밀번호로 잠금 해제
