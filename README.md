# FaceInn
> AI 얼굴 인식 기반 비대면 숙소 체크인·체크아웃 서비스

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?style=flat&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-16.0+-147EFB?style=flat&logo=xcode&logoColor=white)
![Tuist](https://img.shields.io/badge/Tuist-4.45.1-9B51E0?style=flat)
![Kingfisher](https://img.shields.io/badge/Kingfisher-8.3.2+-FF6B6B?style=flat)
<br>
[![Notion Badge](https://img.shields.io/badge/Notion-000?logo=notion&logoColor=fff&style=for-the-badge)](https://www.notion.so/FaceInn-233bd8a384518067997ad2687a6e7112?source=copy_link)


## ⚒️ 기술 스택

| 분류 | 기술 |
|------|------|
| **UI** | UIKit |
| **Architecture** | MVC |
| **Face Recognition** | ARKit, Vision, CoreML |
| **ML Model** | MobileFaceNet (.mlmodel) |
| **3D / Scene** | SceneKit |
| **Backend** | Firebase (Auth, Firestore, Realtime Database, Storage) |
| **Open API** | 공공데이터포털 사업자등록정보 진위확인 API |
| **Dependency** | Swift Package Manager |
| **Project Generation** | Tuist |

## 👥 팀원 소개

| **iOS Developer** | **iOS Developer** |
| :---: | :---: |
| <a href="https://github.com/HunCY5"><img src="https://github.com/HunCY5.png" width="100px" style="border-radius: 50%;" alt="HunCY5"/></a> | <a href="https://github.com/ChanSolShin"><img src="https://github.com/ChanSolShin.png" width="100px" style="border-radius: 50%;" alt="ChanSolShin"/></a> |
| [**HunCY5**](https://github.com/HunCY5) | [**ChanSolShin**](https://github.com/ChanSolShin) |

## 🗂️ 프로젝트 구조
```
FaceInn/
├── Tuist/                
│   └── Package.swift     # Tuist 프러그인 용도 파일
├── Project/
│   └── Derived/
│       └── InfoPlists/
│       └── Resources/
│   └── FaceInn/
│       └── Sources/
│       └── Resources/
│       └── Tests/
├── Project.swift         # Tuist 설정 파일(tuist generate 시, 생성 기준)
├── .gitignore
└── README.md
```

## 프로젝트 시작 방법
```bash
###1. Tuist 설치(최초 1회)
>> brew install tuist

###2. 프로젝트 Clone or Pull or Project.swift 수정 후 .xcodeproj 생성(최신화)
>> cd FaceInn
>> tuist generate

### 권한 에러 해결 (권한 문제 발생 시)
>> sudo mkdir -p ~/.local/state/tuist
>> sudo chown -R $(whoami) ~/.local
```

## 📄 .gitignore 설정
- .xcodeproj, .xcworkspace(현재 ignore되어 있는 상태. 변경사항 추적되면 아래의 작업 실행), GoogleService-Info.plists

### 커밋할 때 추적될 시
```bash
>> git rm --cached *.xcodeproj
>> git rm --cached *.xcworkspace
```

<br>

<table>
<tr>
<td valign="top">

## 📌 브랜치 전략

| 브랜치 | 용도 | 병합 대상 |
|--------|------|------|
| `main` | 앱스토어 출시용 |  |
| `release` | 출시 준비 | `main`, `develop` |
| `hotfix` | 배포 버전 버그 수정 | `main`, `develop` |
| `develop` | 개발 완료 | `release` |
| `feature` | 기능 개발 | `develop` |

</td>
<td valign="top">

## 📌 커밋 컨벤션

| 태그 | 설명 | 예시 |
|------|------|------|
| `feat` | 새로운 기능 추가 | feat.로그인 화면 구현 |
| `fix` | 버그 수정 | fix.로그인 시도 시, ~오류 해결 |
| `chore` | 빌드, 패키지 등 기타 작업 | chore.Tuist 설정 수정 |
| `refactor` | 코드 리팩토링 | refactor.뷰 레이아웃 정리 |
| `docs` | 문서 수정 | docs. Tuist 사용법 작성 |
| `style` | 포맷팅·주석 등 | style.코드 정렬 및 주석 수정 |

</td>
</tr>
</table>

