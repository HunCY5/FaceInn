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
    ),
    .remote(
      url: "https://github.com/WenchaoD/FSCalendar",
      requirement: .upToNextMajor(from: "2.8.2")
    ),
    .remote(
      url: "https://github.com/onevcat/Kingfisher.git",
      requirement: .upToNextMajor(from: "7.0.0")
    )
  ],
  platforms: [.iOS]
)
