# FPGA Doorlock Password Logic

FPGA 디지털 도어락 프로젝트 중 비밀번호 로직 담당 파트입니다.

## 담당 기능

- 비밀번호 비교기(Comparator)
- 비밀번호 변경 로직(Password Change Logic)
- 시도 카운터(Attempt Counter)
- 자동잠금 타이머(Auto-Lock Timer)

## 구현 파일

```text
rtl/
  fsm_module.v          # 메인 FSM + 비밀번호 비교/변경/실패카운터/자동잠금 연동
  auto_lock_timer.v     # 10초 자동잠금 타이머
  top_module.v          # TACT_SW 입력 매핑 + FSM 인스턴스

tb/
  tb_fsm_module.v       # 통합 테스트벤치

docs/
  PASSWORD_LOGIC_IMPLEMENTATION.md
```

## 자동잠금 기준

시스템 클럭은 팀 명세 기준 `clk_1khz`입니다.

```text
1 kHz × 10 sec = 10,000 ticks
```

따라서 `top_module.v`에서는 다음과 같이 설정했습니다.

```verilog
fsm_module #(
    .AUTO_LOCK_TICKS(10000)
) FSM (...);
```

시뮬레이션에서는 시간을 줄이기 위해 테스트벤치에서 `AUTO_LOCK_TICKS=10`으로 오버라이드합니다.

## FSM 상태

```text
IDLE   = 3'd0
INPUT  = 3'd1
CHECK  = 3'd2
UNLOCK = 3'd3
ALARM  = 3'd4
CHANGE = 3'd5
```

## 주요 동작

1. 기본 비밀번호는 `16'h1234`입니다.
2. 입력 비밀번호와 저장 비밀번호가 같으면 `UNLOCK` 상태로 전이합니다.
3. 실패 3회째에는 `ALARM` 상태로 전이합니다.
4. `UNLOCK` 상태에서 `change` 입력 시 새 비밀번호 입력 모드로 진입합니다.
5. `UNLOCK` 상태에서 10초가 지나면 자동으로 `IDLE` 상태로 복귀합니다.

## GitHub 업로드 예시

```bash
git init
git add .
git commit -m "Implement password logic with 10s auto lock"
git branch -M main
git remote add origin https://github.com/<USER>/<REPO>.git
git push -u origin main
```
