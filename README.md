# FPGA Digital Doorlock FSM

Verilog HDL 기반 디지털 도어락 FSM 구현 파일입니다.

## 구조

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

## 핵심 기능

- 4자리 비밀번호 입력
- `#` 입력 시 비밀번호 비교
- 기본 비밀번호: `1234` (`16'h1234`, BCD 저장)
- 비밀번호 3회 오류 시 ALARM 진입
- UNLOCK 상태에서 10초 후 자동 잠금
- UNLOCK 상태에서 admin/change 입력 시 비밀번호 변경
- 내부 문 열림 버튼 `auto_open` 지원
- LCD/FND/LED/Buzzer 연동용 상태 출력 제공

## TACT_SW 매핑

| 입력 | 역할 |
|---|---|
| `TACT_SW[0]~[9]` | 숫자 0~9 |
| `TACT_SW[10]` | enter / `#` |
| `TACT_SW[11]` | change / admin `A` |
| `TACT_SW[12]` | 내부 문 열림 버튼 |
| `TACT_SW[13]` | reset |
| `TACT_SW[14]` | alarm clear |

## 업로드 순서 예시

```bash
git init
git add .
git commit -m "Implement improved doorlock FSM"
git branch -M main
git remote add origin <YOUR_REPOSITORY_URL>
git push -u origin main
```
