//
//  HostSignUpModel.swift
//  FaceInn
//
//  Created by CHOI on 5/27/25.
//


import Foundation

final class HostSignUpModel {

    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var name: String = ""
    var phone: String = ""
    var businessNumber: String = ""

    /// 이메일 중복 확인 여부
    var isEmailChecked: Bool = false
    /// 사업자 등록 번호 유효성 여부
    var isBusinessNumberValid: Bool = false

    /// 모든 입력값이 유효한지 판단
    var canProceed: Bool {
        return !email.isEmpty &&
               password.count >= 6 &&
               password == confirmPassword &&
               !name.isEmpty &&
               !phone.isEmpty &&
               isEmailChecked &&
               isBusinessNumberValid
    }
}
