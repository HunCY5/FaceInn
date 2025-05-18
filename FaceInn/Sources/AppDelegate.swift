//
//  AppDelegate.swift
//  FaceInn
//
//  Created by CHOI on 3/31/25.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        if FirebaseApp.app() != nil {
            print("configure 호출 성공")
        } else {
            print("configure 호출 실패")
        }
        // Analytics 이벤트 로깅
        Analytics.logEvent("app_launch", parameters: [
            "platform": "iOS",
            "timestamp": "\(Date())"
        ])
        // 익명 로그인 테스트 (Auth)
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Auth 익명 로그인 실패:", error.localizedDescription)
            } else {
                print("Auth 익명 로그인 성공, UID:", result?.user.uid ?? "(없음)")
                
                // 로그인 성공 시 Analytics 이벤트 추가
                Analytics.logEvent("anonymous_login_success", parameters: [
                    "uid": result?.user.uid ?? "unknown"
                ])
            }
        }
        
        // Firestore 테스트
        let firestore = Firestore.firestore()
        firestore
            .collection("init_check")
            .document("ios_app")
            .setData(["timestamp": Timestamp(date: Date())]) { error in
                if let error = error {
                    print("Firestore 쓰기 실패:", error.localizedDescription)
                } else {
                    print("Firestore 쓰기 성공")
                }
            }
        
//        // Realtime Database 테스트
//        let realtime = Database.database().reference()
//        realtime
//            .child("init_check/ios_app")
//            .setValue(Date().timeIntervalSince1970) { error, _ in
//                if let error = error {
//                    print("RealtimeDB 쓰기 실패:", error.localizedDescription)
//                } else {
//                    print("RealtimeDB 쓰기 성공")
//                }
//            }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
