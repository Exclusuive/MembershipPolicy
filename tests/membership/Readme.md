# 📑 Membership Module Test Specification

## 🏷️ 테스트 개요

- **대상 모듈**: `exclusuive::membership`
- **테스트 도구**: Move Unit Test Framework (`sui move test`)
- **테스트 목적**:
  - `MembershipType` 등록/업데이트 로직
  - `Membership` 발급/업데이트 로직
  - 권한 제어(`MembershipManager`, `allow_user_mint`, `allow_transfer`) 검증
  - Transfer 동작 여부 검증

---

## ✅ MembershipType Tests

### 1. `test_register_membership_type_success`

- **목적**: 권한 있는 계정이 MembershipType 등록 성공 여부 확인
- **기대 결과**: 정상 실행, abort 없음

### 2. `test_register_membership_type_without_permission_fail`

- **목적**: 권한 없는 계정이 MembershipType 등록 시도
- **기대 결과**: `ENotAuthorized`로 실패

### 3. `test_register_membership_type_with_same_name_fail`

- **목적**: 동일한 MembershipType 이름을 중복 등록 시도
- **기대 결과**: `EAlreadyExists`로 실패

### 4. `test_update_membership_type_success`

- **목적**: 기존 MembershipType 속성을 업데이트
- **기대 결과**: 정상 실행, MembershipType 속성이 변경됨

### 5. `test_update_membership_type_with_wrong_name_fail`

- **목적**: 존재하지 않는 MembershipType 업데이트 시도
- **기대 결과**: `EObjectNotExist`로 실패

---

## ✅ Membership Tests

### 6. `test_mint_membership_with_permission_success`

- **목적**: 권한 있는 관리자가 Membership 발급
- **기대 결과**: 정상 발급됨

### 7. `test_mint_membership_without_permission_fail`

- **목적**: 권한 없는 유저가 발급 시도 (allow_user_mint = false)
- **기대 결과**: `ENotAuthorized`로 실패

### 8. `test_mint_membership_with_user_mint_allowed_success`

- **목적**: `allow_user_mint = true`일 때, 유저가 직접 Membership 발급
- **기대 결과**: 정상 발급됨

### 9. `test_mint_membership_with_nonexistent_type_fail`

- **목적**: 존재하지 않는 MembershipType 기반으로 Membership 발급 시도
- **기대 결과**: `EObjectNotExist`로 실패

### 10. `test_update_membership_success`

- **목적**: MembershipType 업데이트 후, 기존 Membership을 동기화(`update_membership`)
- **기대 결과**: Membership 속성이 최신 MembershipType 값으로 반영됨

---

## ✅ Transfer Tests

### 11. `test_transfer_success_when_allowed`

- **목적**: `allow_transfer = true`일 때, Membership 전송 가능 여부 확인
- **기대 결과**: 정상 전송됨

### 12. `test_transfer_fail_when_not_allowed`

- **목적**: `allow_transfer = false`일 때, Membership 전송 시도
- **기대 결과**: `ENotAuthorized`로 실패

---

## 🧪 실행 방법

```bash
# 모듈 디렉토리에서 실행
sui move test --filter membership_tests
```

- **성공 케이스** → 아무런 abort 없이 PASS
- **실패 케이스** → 지정된 abort code (`ENotAuthorized`, `EAlreadyExists`, `EObjectNotExist`)로 실패
