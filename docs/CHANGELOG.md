# 수정 내역

## 수정한 문제점

1. `rst` 고정 0 문제 수정
   - `top_module`에 `RESET_N` 입력 추가
   - `wire rst = ~RESET_N;`로 active-low reset을 active-high reset으로 변환
   - HBE-Combo II-SE의 `RESET_N` 핀은 Cyclone II 기준 `PIN_206`

2. 4자리 입력 검증 추가
   - 기존 `digit_count[1:0]`는 0~3만 표현 가능해서 4자리 완료 상태를 정확히 저장하지 못함
   - `digit_count[2:0]`로 변경하여 0~4를 명확히 표현
   - `enter_pulse && digit_count == 3'd4`일 때만 CHECK 진입

3. 비밀번호 변경 로직 보강
   - CHANGE 상태에서도 4자리가 입력되어야만 저장
   - 1~3자리만 입력하고 ENTER를 눌렀을 때 잘못 저장되는 문제 방지

4. 자동잠금 유지
   - 1kHz 기준 `AUTO_LOCK_TICKS = 10000`
   - UNLOCK 상태에서 10초 후 자동으로 IDLE 복귀

5. 추가 입력 처리 안정화
   - 4자리 초과 숫자 입력은 ENTER 전까지 무시
   - 입력 버퍼가 5자리 이상 밀려서 비밀번호가 꼬이는 문제 방지

## 주의사항

- 버튼 디바운싱은 아직 별도 모듈로 추가하지 않았습니다.
- 실제 버튼이 active-low로 동작하면 `TACT_SW` 입력을 반전해야 합니다.
- Quartus 프로젝트에는 `rtl/top_module.v`, `rtl/fsm_module.v`, `rtl/auto_lock_timer.v` 세 파일만 추가하세요.


## 2026-06-01 추가 수정: 입력 무활동 타임아웃

- `fsm_module.v`에 `INPUT_TIMEOUT_TICKS` 파라미터 추가
- `INPUT_TIMEOUT_TIMER` 인스턴스 추가
- `INPUT` 상태에서 10초 무입력 시 `IDLE` 복귀
- `CHANGE` 상태에서 10초 무입력 시 비밀번호 변경 취소 후 `IDLE` 복귀
- 기존 `UNLOCK` 상태 10초 자동잠금 유지
