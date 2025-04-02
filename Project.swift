import ProjectDescription

let project = Project(
    name: "FaceInn",
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
            dependencies: []
        ),
        .target(
            name: "FaceInnTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.FaceInnTests",
            infoPlist: .default,
            sources: ["FaceInn/Tests/**"],
            resources: [],
            dependencies: [.target(name: "FaceInn")]
        ),
    ]
)
