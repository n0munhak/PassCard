//
//  Structs.swift
//  PassCard
//
//  Created by Seongwon Min on 8/5/25.
//

import Foundation

enum AppError: Error {
    case LoginError(String)
}

extension Dictionary {
    func percentEncoded() -> String? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

struct LoginProcResponse: Decodable {
    var msg: String;
    var go_first_class: String;
}

struct LoginResponse {
    var userID: String;
    var classID: String;
    var name: String;
    var phone: String;
}

enum StringOrArrayString: Decodable {
  case string (String)
  case arrayString (Array<String>)
}

struct Exam: Hashable, Decodable {
    var id: String;
    var name: String;
    var numCards: String;
    var state: Int;
}

struct MultiChoiceOptions: Hashable, Decodable {
    var problemCode: Int;
    var optionCode: Int;
    var content: String;
}

final class ViewModel: ObservableObject {
    @Published var logined = false;
    @Published var sessionID = "";
    @Published var userID = "";
    @Published var classID = "";
    @Published var name = "";
    @Published var phone = "";
}
