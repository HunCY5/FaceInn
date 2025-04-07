# FaceInn
## 프로젝트 구조
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
├── README.md

## 프로젝트 시작 방법
###1. Tuist 설치(최초 1회)
>> brew install tuist
###2. 프로젝트 Clone or Pull or Project.swift 수정 후 .xcodeproj 생성(최신화)
>> cd FaceInn
>> tuist generate
### 권한 에러 해결 (권한 문제 발생 시)
>> sudo mkdir -p ~/.local/state/tuist
>> sudo chown -R $(whoami) ~/.local

## .gitignore 설정
- .xcodeproj, .xcworkspace(현재 ignore되어 있는 상태. 변경사항 추적되면 아래의 작업 실행)
### 커밋할 때 추적될 시
>> git rm --cached *.xcodeproj
>> git rm --cached *.xcworkspace

## 커밋 메시지 규칙
- feat : 새로운 기능 추가               ex) feat.로그인 화면 구현
- fix : 버그 수정                     ex) fix.로그인 시도 시, ~오류 해결
- refactor : 코드 리팩토링(기능 변화 없음) ex) refactor.뷰 레이아웃 정리
- chore : 설정, 빌드, 의존성 etc..      ex) chore.Tuist 설정 수정
- docs : 문서 수정                    ex) docs. Tuist 사용법 작성
- style: 포맷팅, 주석 등               ex) style.코드 정렬 및 주석 수정
