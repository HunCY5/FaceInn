//
//  Dependenciese.swift
//  FaceInn
//
//  Created by CHOI on 5/15/25.
//

import ProjectDescription

let dependencies = Dependencies(
  swiftPackageManager: [
    .remote(
      url: "https://github.com/firebase/firebase-ios-sdk.git",
      requirement: .upToNextMajor(from: "10.15.0")
    )
  ],
  platforms: [.iOS]
)
