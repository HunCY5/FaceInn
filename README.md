# FaceInn - iOS App
> AI 얼굴 인식 기반 비대면 숙소 체크인·체크아웃 iOS 앱

<p align="center">
  <img src="https://github.com/user-attachments/assets/de978f75-a9c5-4ccf-a727-735348cdb3ae" width="80%" alt="페이스인 썸네일"/>
</p>


### 📱 프로젝트 소개

**페이스인(FaceInn)** 은 얼굴 인식만으로 진행하는 비대면 숙소 체크인·체크아웃 iOS 앱입니다.

기존 비대면 체크인은 키오스크 장비가 필요해 소규모 숙소가 도입하기 어려웠습니다. 별도 장비 없이 호스트의 모바일 기기 하나로 동작하도록 만들었습니다.

---

### ✨ 주요 기능

- **얼굴 등록** - 화면 안내에 맞춰 정면·좌·우 세 방향이 자동으로 촬영되고, 기기에서 MobileFaceNet 모델을 통해 128차원 벡터로 변환되어 저장됩니다.
  > `ARKit` 얼굴 각도 추적 + 자동 촬영 · `MobileFaceNet` 온디바이스 임베딩 추출 · 원본 이미지 저장 X
- **비대면 체크인** - 프런트에 들르지 않고 얼굴 인식만으로 체크인·체크아웃이 끝납니다.
  > `MobileFaceNet` 온디바이스 임베딩 대조 (등록된 벡터와 실시간 비교)
- **호스트 숙소 관리** - 예약 현황과 체크인·체크아웃 기록을 한 화면에서 확인합니다.
  > `Firestore` 실시간 수신 + `FSCalendar`
- **사업자 확인** - 호스트로 가입할 때 사업자등록 상태가 자동으로 확인됩니다.
  > 공공데이터포털 사업자등록 상태조회 API


---

## 🖥️ 화면 구성

<p align="center"><strong>게스트</strong></p>

<table align="center">
  <tr align="center">
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/d7597d3c-7c55-4f87-90aa-7b2b9eeb5f4d" width="200" alt="얼굴 등록"></td>
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/798c3f5d-e85b-44c4-b820-1755dc48ac3e" width="200" alt="정면 촬영"></td>
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/420c6c5d-cde3-4573-bda1-6f12be99ab28" width="200" alt="측면 촬영"></td>
  </tr>
  <tr align="center">
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/1b5bbdf0-8cd8-4304-ab0e-541d7cd83e78" width="200" alt="홈"></td>
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/8ae38f6c-103b-4f45-89a9-800055bd5059" width="200" alt="숙소 예약"></td>
    <td width="33.33%"><img src="https://github.com/user-attachments/assets/b82aa11b-106a-4462-a378-e1d5805ad762" width="200" alt="예약 현황"></td>
  </tr>
</table>

<p align="center"><strong>호스트</strong></p>

<table align="center">
  <tr align="center">
    <td width="50%"><img src="https://github.com/user-attachments/assets/70bcc9fa-a0de-4745-8366-79a1cf949f38" width="200" alt="예약 현황"></td>
    <td width="50%"><img src="https://github.com/user-attachments/assets/034f9c50-ce50-45d1-94db-76927d2d244f" width="200" alt="체크인 현황"></td>
  </tr>
  <tr align="center">
    <td width="50%"><img src="https://github.com/user-attachments/assets/39fa644b-54c1-4040-b0f9-f22d0c214ac9" width="253" alt="체크인·체크아웃 선택 (iPad)"></td>
    <td width="50%"><img src="https://github.com/user-attachments/assets/63e4fe6c-1e62-4037-a41d-a7c4777ea69f" width="253" alt="얼굴 인식 결과 (iPad)"></td>
  </tr>
</table>



---

### 🏗️ 시스템 아키텍처

<p align="center">
  <img src="https://github.com/user-attachments/assets/3e5ea5f0-97a4-4b6b-b1f3-efd112e0b018" width="100%" alt="시스템 아키텍처"/>
</p>


---

### ⚒️ 기술 스택

| 분류 | 기술 |
|------|------|
| **Language** | Swift 5 |
| **UI Framework** | UIKit (Programmatic UI) |
| **Architecture** | MVC |
| **Concurrency** | GCD (DispatchGroup) |
| **AR & Vision** | ARKit, SceneKit, Vision |
| **On-Device AI** | Core ML (MobileFaceNet, 128차원 임베딩) |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Open API** | 공공데이터포털 사업자등록 상태조회 |
| **Libraries** | Kingfisher, FSCalendar |
| **Project & Dependency** | Tuist, Swift Package Manager |

---

### 🗂️ 프로젝트 구조

```
FaceInn/                            # 레포 루트 (Tuist 프로젝트)
├── Project.swift                   # Tuist 프로젝트 설정 (tuist generate 기준)
├── Tuist.swift                     # Tuist 전역 설정
├── Tuist/                          # 플러그인·패키지 의존성 정의
├── Configs/                        # 서명 설정
│
└── FaceInn/                        # 앱 타겟
    ├── Sources/
    │   ├── MobileFaceNet.mlmodel   # 얼굴 인식 CoreML 모델
    │   ├── Auth/                   # 로그인 · 회원가입 (게스트 / 호스트 분리)
    │   ├── FaceId/                 # 얼굴 등록 · 인식 캡처 및 처리
    │   ├── HostMainView/           # 호스트 화면 - 예약·객실 관리 · 체크인
    │   ├── TabBar/                 # 게스트 / 호스트 탭 구성
    │   ├── MyPage/                 # 마이페이지 (게스트 프로필 · 호스트 페이지)
    │   ├── Model/                  # 데이터 모델
    │   ├── Cell/                   # 테이블 · 컬렉션 뷰 셀
    │   ├── View/                   # 재사용 커스텀 UIView (카드 · 등록 폼)
    │   └── ViewController/         # 화면 제어
    │
    └── Resources/                  # 이미지 리소스
```

---



## 🔍 문제 해결

### 1. 얼굴 대조에서 특징 벡터를 만들 수단이 앱에 없던 문제, 외부 모델의 온디바이스 추론 변환으로 해결

<img width="90%" alt="모델 변환 파이프라인" src="https://github.com/user-attachments/assets/46e97389-9a6a-44f9-b15e-d7ed0cae5829"/> <br>


**📍 제약 상황**

- Vision은 얼굴 위치·랜드마크 검출까지만 제공 → **신원 대조에 쓸 임베딩 벡터를 제공 안함**
- 등록 화면의 저장 대상과 인식 화면의 비교 대상이 모두 이 벡터라, 두 기능 개발 시점부터 막혀 있었음

**⚖️ 선택한 구조와 이유**

서버에 이미지를 보내 임베딩을 받아오면 모델 교체는 쉬워지지만 얼굴 원본이 기기 밖으로 나가고 체크인마다 네트워크에 의존하게 됩니다.<br>기기에서 돌리더라도 정확도만 보고 큰 모델을 얹으면 실시간 인식 화면에서 프레임이 밀립니다.<br>**얼굴을 기기 밖으로 내보내지 않으면서 실시간으로 돌아가는 크기를 기준으로 골랐습니다.**

**✅ 결과**

- `MobileFaceNet`을 `paddle2onnx` → `coremltools` 경로로 변환해 번들에 탑재 — 얼굴 원본을 저장하지 않고 `128차원` 벡터만 저장
- `VNCoreMLModel`로 로딩해 기기 안에서 추출 - 네트워크 없이 체크인 인식이 성립
- `.mlpackage`에서 무한 빌드가 발생해 `.mlmodel`로 교체 - 빌드가 멈추던 경로 제거
- 모델 경로를 Tuist 매니페스트에 추가 - 프로젝트 생성 시 모델 클래스가 함께 컴파일

<details>
<summary>근거</summary>

- 코드 — [`FaceProcessor.swift:15-49`](https://github.com/HunCY5/FaceInn/blob/develop/FaceInn/Sources/FaceId/FaceProcessor.swift#L15-L49)(모델 로딩·임베딩 추출) · [`:52-71`](https://github.com/HunCY5/FaceInn/blob/develop/FaceInn/Sources/FaceId/FaceProcessor.swift#L52-L71)(Vision 검출과 분리) · [`Project.swift:53-59`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/Project.swift#L53-L59)
- 커밋 — [`c9bc3fa`](https://github.com/HunCY5/FaceInn/commit/c9bc3fa) [`76a85a7`](https://github.com/HunCY5/FaceInn/commit/76a85a7) [`af8a870`](https://github.com/HunCY5/FaceInn/commit/af8a870) [`cc4b090`](https://github.com/HunCY5/FaceInn/commit/cc4b090) [`6482c97`](https://github.com/HunCY5/FaceInn/commit/6482c97)

</details>

---

### 2. 얼굴 등록에서 측면 포즈의 촬영 시점을 판정할 기준이 없던 문제, 목표 각도와 얼굴 중심선 겹침 판정으로 해결


<img width="90%" alt="측면 포즈 판정과 자동 촬영" src="https://github.com/user-attachments/assets/908b9ac6-264c-41bc-b24f-dfff15181932"/> <br>

**📍 제약 상황**

- 최초 등록 화면이 Vision 얼굴 사각형·랜드마크 검출로만 판정 → **정면 한 포즈에 대해서만 가이드 박스 진입 여부를 판단**
- 등록은 `정면·좌·우` 세 포즈를 모두 모아야 끝나는데 좌·우 단계에는 목표 각도도 판정 기준도 없음

**⚖️ 선택한 구조와 이유**

촬영 버튼을 그대로 두고 안내 문구만 더하면 얼마나 돌렸는지를 사용자가 스스로 가늠해야 하고, 각도를 숫자로 표시하면 목표에 가까워지고 있는지가 화면에서 읽히지 않습니다. <br>두 방식 모두 얼굴이 지금 어디를 향하는지를 사용자가 머릿속에서 계산하게 만듭니다. <br>**목표와 현재를 같은 화면에 겹쳐 보여주기로 했습니다.**

**✅ 결과**

- 카메라 입력을 `ARSCNView`·`ARFaceTrackingConfiguration`으로 교체하고 코끝 정점을 2D 투영해 현재 중심선을 실선으로, 목표 각도를 점선으로 표시 - 얼마나 돌려야 하는지가 화면에서 읽힘
- 두 선의 거리가 가이드 지름의 일정 비율 안에 들어오면 `3초 카운트다운` 후 자동 촬영 - 셔터 시점 판단이 사용자에게서 앱으로 이동
- 판정 통과 시 다음 포즈로 자동 전환 - 정면·좌·우가 끊기지 않고 이어짐
- 카운트다운 도중 인식이 풀리면 상태를 초기화하고 안내와 함께 재개

<details>
<summary>근거</summary>

- 코드 — [`FaceCaptureViewController.swift:254-370`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/FaceId/FaceCaptureViewController.swift#L254-L370)(우측 유도선) · [`:414-540`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/FaceId/FaceCaptureViewController.swift#L414-L540)(좌측 동일 구조) · [`:682-780`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/FaceId/FaceCaptureViewController.swift#L682-L780)(카운트다운·촬영) · [`FaceGuideOverlayView.swift:66-147`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/FaceId/FaceGuideOverlayView.swift#L66-L147)
- 커밋 — [`af8a870`](https://github.com/HunCY5/FaceInn/commit/af8a870) [`8372f8d`](https://github.com/HunCY5/FaceInn/commit/8372f8d) [`3c8d90d`](https://github.com/HunCY5/FaceInn/commit/3c8d90d) [`dbad867`](https://github.com/HunCY5/FaceInn/commit/dbad867) [`39e0ba5`](https://github.com/HunCY5/FaceInn/commit/39e0ba5) [`88d4088`](https://github.com/HunCY5/FaceInn/commit/88d4088)


</details>

---


### 3. 게스트 얼굴 대조에서 저장된 벡터의 타입·차원을 검증 없이 쓰던 문제, 스케일 무관 유사도와 타입 흡수 변환으로 해결

<img width="90%" alt="방향별 벡터 3개 AND 판정" src="https://github.com/user-attachments/assets/749dca61-0c1b-4cea-9852-d422f98260a2"/> <br>

**📍 제약 상황**

- 최초 대조가 촬영 벡터와 저장 벡터의 `L2 거리`로 판별 → 벡터 크기 차이가 결과에 직접 반영
- Firestore에서 읽은 값을 **캐스팅 한 번으로 타입을 단정하고 그대로 산술에 투입** → 실패하면 그 후보가 통째로 건너뛰어짐

**⚖️ 선택한 구조와 이유**

거리로 비교하면 같은 사람이라도 벡터의 크기가 달라질 때 값이 흔들리고, 캐스팅 하나로 타입을 단정하면 예상 밖 형태가 들어왔을 때 그 후보가 조용히 사라집니다. <br>두 문제 모두 입력이 언제나 예상한 모양이라고 가정한 데서 나옵니다. <br>**비교는 방향으로 하고, 입력은 검증한 뒤에 쓰기로 했습니다.**

**✅ 결과**

- 비교식을 `코사인 유사도`로 교체 - 벡터 크기 차이가 판정에 영향을 주던 경로 제거
- 정면·좌·우 세 값이 **모두** 임계값을 넘을 때만 매칭 - 한 방향만 우연히 맞는 경우 차단
- `toFloatArray()`가 `[Float]`·`[Double]`·`[NSNumber]`·중첩 배열·`Data`를 흡수 - 예상 밖 타입이 들어와도 그 후보만 건너뛰고 나머지 대조는 계속
- 차원 불일치와 분모 0·비유한 값은 `-1`을 반환해 매칭에서 자동 탈락

<details>
<summary>근거</summary>

- 코드 — [`GuestFaceRecognitionViewController.swift:815-855`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/HostMainView/CheckIn/GuestFaceRecognitionViewController.swift#L815-L855)(임베딩 추출) · [`:892-916`](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/HostMainView/CheckIn/GuestFaceRecognitionViewController.swift#L892-L916)(타입 흡수 변환) · [`:976-986`(코사인·임계값)](https://github.com/HunCY5/FaceInn/blob/ebc1003170e890780d4a6baa735aa362f8956291/FaceInn/Sources/HostMainView/CheckIn/GuestFaceRecognitionViewController.swift#L976-L986) · `:1031-1047`(3포즈 동시 판정)
- 커밋 — [`a2a704f`](https://github.com/HunCY5/FaceInn/commit/a2a704f) [`73a30d0`](https://github.com/HunCY5/FaceInn/commit/73a30d0) [`9f6f0e1`](https://github.com/HunCY5/FaceInn/commit/9f6f0e1) [`8e1d6fd`](https://github.com/HunCY5/FaceInn/commit/8e1d6fd) [`6415c52`](https://github.com/HunCY5/FaceInn/commit/6415c52)

</details>

---

## 👥 팀원 소개

| **iOS Developer** | **iOS Developer** |
| :---: | :---: |
| <a href="https://github.com/HunCY5"><img src="https://github.com/HunCY5.png" width="180px" alt="HunCY5"/></a> | <a href="https://github.com/ChanSolShin"><img src="https://github.com/ChanSolShin.png" width="180px" alt="ChanSolShin"/></a> |
| [**HunCY5**](https://github.com/HunCY5) | [**ChanSolShin**](https://github.com/ChanSolShin) |

---

### 🚀 프로젝트 실행 방법
> Tuist로 프로젝트를 생성하는 구조라 `.xcodeproj` 및 `.xcworkspace`가 레포에 포함돼 있지 않습니다.

```bash
# 1. Tuist 설치(최초 1회)
brew install tuist

# 2. 프로젝트 Clone or Pull or Project.swift 수정 후 .xcodeproj 생성(최신화)
cd FaceInn
tuist generate

# 권한 에러 해결 (권한 문제 발생 시)
mkdir -p ~/.local/state/tuist
sudo chown -R $(whoami) ~/.local/state/tuist
```

### 📄 .gitignore 설정
> `.xcodeproj` · `.xcworkspace` · `GoogleService-Info.plist`는 ignore 대상.
> 변경사항으로 추적되면 아래의 작업 실행.

```bash
git rm --cached *.xcodeproj
git rm --cached *.xcworkspace
```

---

## 📌 브랜치 전략

| 브랜치 | 용도 | 병합 대상 |
|--------|------|------|
| `main` | 앱스토어 출시용 | — |
| `release` | 출시 준비 | `main`, `develop` |
| `hotfix` | 배포 버전 버그 수정 | `main`, `develop` |
| `develop` | 개발 완료 | `release` |
| `feature` | 기능 개발 | `develop` |

## 📌 커밋 컨벤션

| 태그 | 설명 | 예시 |
|------|------|------|
| `feat` | 새로운 기능 추가 | feat.로그인 화면 구현 |
| `fix` | 버그 수정 | fix.로그인 시도 시 오류 해결 |
| `chore` | 빌드, 패키지 등 기타 작업 | chore.Tuist 설정 수정 |
| `refactor` | 코드 리팩토링 | refactor.뷰 레이아웃 정리 |
| `docs` | 문서 수정 | docs.Tuist 사용법 작성 |
| `style` | 포맷팅·주석 등 | style.코드 정렬 및 주석 수정 |
