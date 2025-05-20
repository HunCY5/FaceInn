import ProjectDescription

let project = Project(
  name: "FaceInn",
  packages: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.15.0")),
    .package(url: "https://github.com/WenchaoD/FSCalendar", .upToNextMajor(from: "2.8.2")) // ✅ 패키지 추가
  ],
  targets: [
    .target(
      name: "FaceInn",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.FaceInn",
      infoPlist: .extendingDefault(
        with: [
          "UIMainStoryboardFile": "",
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ],
          "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
              "UIWindowSceneSessionRoleApplication": [
                [
                  "UISceneConfigurationName": "Default Configuration",
                  "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                ]
              ]
            ]
          ]
        ]
      ),
      sources: ["FaceInn/Sources/**"],
      resources: ["FaceInn/Resources/**"],
      dependencies: [
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseAuth"),
        .package(product: "FirebaseFirestore"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseDatabase"),
        .package(product: "FSCalendar")
      ],
      settings: .settings(
        base: [
          "OTHER_LDFLAGS": "$(inherited) -ObjC"
        ]
      )
    ),
    .target(
      name: "FaceInnTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.FaceInnTests",
      infoPlist: .default,
      sources: ["FaceInn/Tests/**"],
      resources: [],
      dependencies: [
        .target(name: "FaceInn")
      ]
    ),
  ]
)
