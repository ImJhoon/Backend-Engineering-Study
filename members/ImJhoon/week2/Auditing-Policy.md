# 엔티티 생성·수정 시간 적용 정책

이 문서는 각 테이블에 `created_at`, `updated_at`이 필요한지 판단한 결과와 JPA Auditing 적용 방법을 정리합니다.

## 1. 감사 시간의 의미

- `created_at`: 데이터베이스 레코드가 생성된 시간
- `updated_at`: 데이터베이스 레코드가 마지막으로 변경된 시간

모든 테이블에 두 컬럼을 일괄 추가하지 않고, 실제로 생성 또는 변경 시점 추적이 필요한 테이블에만 적용합니다.

`reserved_at`, `expires_at`, `paid_at`, `start_time`, `end_time`은 업무상 의미가 있는 시간이므로 공통 감사 컬럼으로 대체하지 않습니다.

## 2. 테이블별 적용 여부

| 테이블 | `created_at` | `updated_at` | 판단 이유 |
|---|---:|---:|---|
| `users` | 적용 | 적용 | 가입 시점과 회원정보 변경 시점 추적 |
| `movies` | 미적용 | 미적용 | 현재는 조회용 기준 데이터이며 관리자 수정 기능이 없음 |
| `cinemas` | 미적용 | 미적용 | 현재는 조회용 기준 데이터 |
| `theaters` | 미적용 | 미적용 | 현재는 조회용 기준 데이터 |
| `seats` | 미적용 | 미적용 | 물리 좌석 기준 데이터이며 현재 수정 기능이 없음 |
| `screenings` | 미적용 | 미적용 | 현재는 별도 수정 기능이 없고 상영 시간 필드가 존재함 |
| `screening_seats` | 미적용 | 적용 | 좌석 상태의 마지막 변경 시점 추적 필요 |
| `reservations` | 미적용 | 적용 | 생성 시점은 `reserved_at`, 상태 변경은 `updated_at`으로 표현 |
| `reservation_seats` | 미적용 | 미적용 | 취소 시점이 필요해지면 범용 수정 시간보다 `cancelled_at` 추가를 우선 검토 |
| `payments` | 미적용 | 적용 | 결제 완료는 `paid_at`, 결제 상태 변경은 `updated_at`으로 표현 |

관리자 수정 API가 추가되면 `movies`, `cinemas`, `theaters`, `seats`, `screenings`의 감사 컬럼 적용 여부를 다시 검토합니다.

## 3. 공통 클래스 구성

여러 엔티티가 공통으로 사용하는 `updatedAt`은 `BaseUpdatedEntity`에 정의합니다.

```java
@Getter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseUpdatedEntity {

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}
```

다음 엔티티가 이를 상속합니다.

- `User`
- `ScreeningSeat`
- `Reservation`
- `Payment`

`createdAt`은 현재 `User`만 사용하므로 `BaseCreatedEntity`를 만들지 않았습니다. 공통 사용처가 하나뿐인 상태에서 부모 클래스를 만들면 재사용 효과 없이 구조만 복잡해지기 때문입니다.

`User.createdAt`에는 `@CreatedDate`를 적용하여 최초 저장 시 자동 입력합니다.

```java
@CreatedDate
@Column(name = "created_at", nullable = false, updatable = false)
private OffsetDateTime createdAt;
```

향후 여러 엔티티가 `createdAt`을 공통으로 사용하게 되면 `BaseCreatedEntity` 도입을 다시 검토합니다.

## 4. 자동 시간 기록 방식

`JpaAuditingConfig`의 `@EnableJpaAuditing`이 JPA Auditing을 활성화합니다.

시간 제공자는 API 시간 정책과 동일하게 UTC를 사용합니다.

```java
return () -> Optional.of(OffsetDateTime.now(ZoneOffset.UTC));
```

그 결과 다음 시점에 시간이 자동 입력됩니다.

- 새로운 `User` 저장: `createdAt`, `updatedAt` 자동 입력
- `User` 수정: `updatedAt` 자동 갱신
- `ScreeningSeat`, `Reservation`, `Payment` 최초 저장 및 수정: `updatedAt` 자동 입력 또는 갱신

`@LastModifiedDate`는 기본 설정에서 최초 저장 시에도 값을 입력합니다. 따라서 `updated_at NOT NULL` 제약 조건을 만족할 수 있습니다.

## 5. 데이터베이스와의 관계

현재 DDL에는 적용 대상으로 결정한 컬럼이 이미 존재하므로 이번 변경에서 테이블 컬럼을 추가할 필요는 없습니다.

```text
users             → created_at, updated_at
screening_seats   → updated_at
reservations      → updated_at
payments          → updated_at
```

DDL의 `DEFAULT CURRENT_TIMESTAMP`는 직접 SQL을 실행하는 상황에 대한 데이터베이스 안전장치로 유지합니다. 일반적인 애플리케이션 저장에서는 JPA Auditing이 시간을 설정합니다.

## 6. 주의사항

JPA Auditing은 JPA가 감지한 저장과 변경에 적용됩니다. 데이터베이스에서 직접 실행한 SQL이나 JPQL 일괄 수정은 자동 감지되지 않을 수 있습니다.

업무상 특정 사건의 시간이 필요하면 범용 `updatedAt` 대신 의미가 분명한 필드를 사용합니다.

예시는 다음과 같습니다.

- 예약 시작: `reservedAt`
- 예약 만료: `expiresAt`
- 결제 완료: `paidAt`
- 좌석 취소: 필요 시 `cancelledAt`

