//
//  Account.swift
//  PassCard
//
//  Created by Seongwon Min on 8/5/25.
//

import Foundation

func GetSessionID(_ callback: @escaping (Bool, String?) -> Void) {
    URLSession.shared.dataTask(
        with: URL(string: "https://www.classcard.net/Main")!
    ) { data, response, error in
        guard let data = data, let response = response as? HTTPURLResponse,
            error == nil
        else {
            callback(false, nil)
            return
        }
        guard (200...299) ~= response.statusCode else {
            callback(false, nil)
            return
        }
        let match = response.value(forHTTPHeaderField: "Set-Cookie")?
            .firstMatch(of: /ci_session=[0-9A-Za-z]+;/)?.output
        if match != nil {
            callback(
                true,
                String(
                    match!.replacing(/ci_session=/, with: "").replacing(
                        ";",
                        with: ""
                    )
                )
            )
        } else {
            callback(false, nil)
        }
    }.resume()
}

func Login(
    username: String,
    password: String,
    vm: ViewModel,
    callback: @escaping (Bool, LoginResponse?) -> Void
) {
    var req = URLRequest(
        url: URL(string: "https://www.classcard.net/LoginProc")!
    )
    req.httpMethod = "POST"
    req.addValue("ci_session=\(vm.sessionID)", forHTTPHeaderField: "Cookie")
    req.addValue(
        "application/x-www-form-urlencoded; charset=UTF-8",
        forHTTPHeaderField: "Content-Type"
    )
    req.httpBody =
        "sess_key=\(vm.sessionID)&redirect=&login_id=\(username)&login_pwd=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        .data(using: .utf8)
    URLSession.shared.dataTask(with: req) { data, response, error in
        guard let data = data, let response = response as? HTTPURLResponse,
            error == nil
        else {
            callback(false, nil)
            return
        }
        guard (200...299) ~= response.statusCode else {
            callback(false, nil)
            return
        }
        guard
            let output = try? JSONDecoder().decode(
                LoginProcResponse.self,
                from: data
            )
        else {
            callback(false, nil)
            return
        }
        let sessMatch = response.value(forHTTPHeaderField: "Set-Cookie")?
            .firstMatch(of: /ci_sesion=[0-9A-Za-z]+;/)?.output
        if sessMatch != nil {
            let sid = String(
                sessMatch!.replacing(/ci_session=/, with: "").replacing(
                    ";",
                    with: ""
                )
            )
            vm.sessionID = sid
        }
        var req2 = URLRequest(
            url: URL(string: "https://www.classcard.net/Main/user")!
        )
        req2.addValue(
            "ci_session=\(vm.sessionID)",
            forHTTPHeaderField: "Cookie"
        )
        URLSession.shared.dataTask(with: req2) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse,
                error == nil
            else {
                callback(false, nil)
                return
            }
            guard (200...299) ~= response.statusCode else {
                callback(false, nil)
                return
            }
            let page = String(data: data, encoding: .utf8)!
            let name = String(
                (page.firstMatch(of: /content-cell">\n[ ]+([^ ]+)[ ]+<a/)?.output.1)!
            )
            let phone = String(
                (page.firstMatch(
                    of:
                        /<div class=" content-cell">\n[ ]+<div>\n[ ]+([0-9\-\*]+)/
                )?.output.1)!
            )
            callback(
                true,
                LoginResponse(
                    userID: output.msg,
                    classID: String(
                        output.go_first_class.split(separator: "/").reversed()[
                            0
                        ]
                    ),
                    name: name,
                    phone: phone
                )
            )
        }.resume()
    }.resume()
}
