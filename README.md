# FPGA Doorlock Password Logic - Fixed 10s Auto Lock

## 담당 파트

- Password Comparator
- Password Change Logic
- Attempt Counter
- Auto-Lock Timer

## 최종 RTL 파일

Quartus 프로젝트에는 아래 3개 파일만 추가합니다.

```text
rtl/top_module.v
rtl/fsm_module.v
rtl/auto_lock_timer.v
```

## 주요 수정사항

- `RESET_N` 입력 추가
- 기본 비밀번호 `16'h1234`
- 4자리 입력 완료 후에만 ENTER 동작
- CHANGE 상태에서도 4자리 입력 완료 후에만 저장
- 1kHz 클럭 기준 10초 자동잠금

## 핀 설정

HBE-Combo II-SE 기준 핀 설정 예시는 다음 파일에 있습니다.

```text
quartus/pin_assignments_hbe_combo2_se.qsf
```


## 추가 기능: 입력 무활동 타임아웃

- `INPUT` 상태에서 10초 동안 숫자키/ENTER 입력이 없으면 입력 중이던 비밀번호를 취소하고 `IDLE`로 복귀합니다.
- `CHANGE` 상태에서도 10초 동안 입력이 없으면 변경을 취소하고 `IDLE`로 복귀합니다.
- 기존 `UNLOCK` 상태의 10초 자동잠금 기능은 그대로 유지됩니다.

기준 클럭은 `clk_1khz`이며, 10초는 `10000` tick입니다.
