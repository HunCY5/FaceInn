import ProjectDescription

let baseSettings: SettingsDictionary = [
  "OTHER_LDFLAGS": "$(inherited) -ObjC"
]

let projectSettings = Settings.settings(
  base: baseSettings,
  configurations: [
    .debug(name: "Debug", xcconfig: "Configs/Signing.xcconfig"),
    .release(name: "Release", xcconfig: "Configs/Signing.xcconfig")
  ]
)

let project = Project(
  name: "FaceInn",
  packages: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.15.0")),
    .package(url: "https://github.com/WenchaoD/FSCalendar", .upToNextMajor(from: "2.8.2")),
    .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.3.2")),
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
          "UIUserInterfaceStyle": "Light",
          "NSCameraUsageDescription": "얼굴 정보를 등록하려면 카메라 접근이 필요합니다.",
          "UIRequiredDeviceCapabilities": [
            "arkit"
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
      resources: ["FaceInn/Resources/**", "FaceInn/GoogleService-Info.plist"],
      dependencies: [
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseAuth"),
        .package(product: "FirebaseFirestore"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseDatabase"),
        .package(product: "FirebaseMessaging"),
        .package(product: "FSCalendar"),
        .package(product: "Kingfisher"),
        .sdk(name: "ARKit", type: .framework),
        .sdk(name: "SceneKit", type: .framework),
      ],
      settings: projectSettings
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
