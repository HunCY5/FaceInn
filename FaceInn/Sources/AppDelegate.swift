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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        if let user = Auth.auth().currentUser {
            print("✅ 로그인됨: \(user.uid)")
            print("이메일: \(user.email ?? "없음")")
            print("익명 사용자?: \(user.isAnonymous)")
            
            if user.isAnonymous {
                print("⚠️ 익명 로그인 상태입니다. 일반 로그인 필요")
            } else {
                print("✅ 일반 사용자 로그인 상태입니다.")
            }
        } else {
            print("❌ 로그인된 사용자 없음")
        }
        
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
