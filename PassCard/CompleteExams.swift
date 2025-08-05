//
//  SolveWS.swift
//  feduspring
//
//  Created by Seongwon Min on 10/26/24.
//

import Foundation

func CompleteExam(
    vm: ViewModel,
    exam: Exam,
    callback: @escaping (Bool) -> Void
) {
    var req = URLRequest(
        url: URL(
            string:
                "https://www.classcard.net/Memorize/\(exam.id)/6000/\(vm.classID)"
        )!
    )
    req.addValue(
        "application/x-www-form-urlencoded; charset=UTF-8",
        forHTTPHeaderField: "Content-Type"
    )
    req.addValue("ci_session=\(vm.sessionID)", forHTTPHeaderField: "Cookie")
    URLSession.shared.dataTask(with: req) { data, response, error in
        guard let data = data, let response = response as? HTTPURLResponse,
            error == nil
        else {
            callback(false)
            return
        }
        guard (200...299) ~= response.statusCode else {
            callback(false)
            return
        }
        let memorizationPage = String(data: data, encoding: .utf8)!
        let CSRFToken = String(
            (memorizationPage.firstMatch(of: /var xscdvf = "(.*)";/)?.output.1)!
        )
        var req2 = URLRequest(
            url: URL(
                string: "https://www.classcard.net/ViewSetAsync/resetAllLog"
            )!
        )
        req2.httpMethod = "POST"
        req2.addValue(
            "application/x-www-form-urlencoded; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        req2.addValue(
            "ci_session=\(vm.sessionID)",
            forHTTPHeaderField: "Cookie"
        )
        req2.httpBody =
            "set_idx=\(exam.id)&activity=1&user_idx=\(vm.userID)&view_cnt=\(exam.numCards)&class_idx=\(vm.classID)&score=1&csrf_token=\(CSRFToken)"
            .data(using: .utf8)
        URLSession.shared.dataTask(with: req2) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse,
                error == nil
            else {
                callback(false)
                return
            }
            guard (200...299) ~= response.statusCode else {
                callback(false)
                return
            }
            CompleteRealExam(vm: vm, exam: exam) { callback($0) }
        }
        .resume()
    }
    .resume()
}

func CompleteRealExam(
    vm: ViewModel,
    exam: Exam,
    callback: @escaping (Bool) -> Void
) {
    var req3 = URLRequest(
        url: URL(
            string: "https://www.classcard.net/ClassTest/checkOnTest"
        )!
    )
    req3.httpMethod = "POST"
    req3.addValue(
        "ci_session=\(vm.sessionID)",
        forHTTPHeaderField: "Cookie"
    )
    req3.addValue(
        "application/x-www-form-urlencoded; charset=UTF-8",
        forHTTPHeaderField: "Content-Type"
    )
    req3.httpBody =
        "class_idx=\(vm.classID)&set_idx=\(exam.id)&user_idx=\(vm.userID)"
        .data(using: .utf8)
    URLSession.shared.dataTask(with: req3) { data, response, error in
        guard let data = data,
            let response = response as? HTTPURLResponse, error == nil
        else {
            callback(false)
            return
        }
        guard (200...299) ~= response.statusCode else {
            callback(false)
            return
        }
        var req4 = URLRequest(
            url: URL(
                string:
                    "https://www.classcard.net/ClassTest/\(vm.classID)/\(exam.id)?p=1&ex=1"
            )!
        )
        req4.addValue(
            "ci_session=\(vm.sessionID); is_std_start=1; study_zoom=1",
            forHTTPHeaderField: "Cookie"
        )
        URLSession.shared.dataTask(with: req4) {
            data,
            response,
            error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                callback(false)
                return
            }
            guard (200...299) ~= response.statusCode else {
                callback(false)
                return
            }
            let testPage = String(data: data, encoding: .utf8)!
            let pCodes: [String] = testPage.matches(
                of:
                    /<input type="hidden" name="test_question\[\]" value="([0-9]+)" \/>/
            ).map { String($0.output.1) }
            let gptCorrectVals: [String] = testPage.matches(
                of:
                    /<input type="hidden" class="gpt_correct" name="gpt_correct\[\]" value="([0-9]+)" \/>/
            ).map { String($0.output.1) }
            let isSubjectiveList: [String] = testPage.matches(
                of:
                    /<input type="hidden" class="subjective_yn" name="subjective_yn\[\]" value="([0-9]+)" \/>/
            ).map { String($0.output.1) }
            let firstLtrYnVals: [String] = testPage.matches(
                of:
                    /<input type="hidden" class="first_letter_yn" name="first_letter_yn\[\]" value="([0-9]+)" \/>/
            ).map { String($0.output.1) }
            let answers: [String] = testPage.matches(
                of: /<div class="answer hidden">(.*)<\/div>/
            ).map { String($0.output.1) }
            let options: [MultiChoiceOptions] = testPage.matches(
                of:
                    /<input type="radio" name="input_radio_[0-9]+" id="radio_([0-9]+)_[0-9]+" value="([0-9]+)">\n[ ]+<label for="radio_[0-9]+_[0-9]+">\n[ ]+<div class="cc-table middle fill-parent"><div>(.*)<\/div><\/div>/
            ).map {
                MultiChoiceOptions(
                    problemCode: Int(String($0.output.1))!,
                    optionCode: Int(String($0.output.2))!,
                    content: String($0.output.3)
                )
            }
            let answerList = pCodes.enumerated().map { (idx, pCode) in
                isSubjectiveList[idx] == "1"
                    ? answers[idx].split(separator: ",")[0].split(
                        separator: ";"
                    )[0].trimmingCharacters(in: .whitespaces)
                    : String(
                        options.filter {
                            $0.problemCode == idx && $0.content == answers[idx]
                        }[0].optionCode
                    )
            }
            var req5 = URLRequest(
                url: URL(
                    string:
                        "https://www.classcard.net/ClassTest/submittest"
                )!
            )
            req5.httpMethod = "POST"
            let boundary = UUID().uuidString
            req5.setValue(
                "ci_session=\(vm.sessionID); study_zoom=1; a=1; s=1; u=1",
                forHTTPHeaderField: "Cookie"
            )
            req5.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"class_idx_2\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append("\(vm.classID)\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"set_idx_2\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append("\(exam.id)\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"p_case_sensitive_yn\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="p_case_sensitive_yn" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"test_type\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="test_type" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"user_idx\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append("\(vm.userID)\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"is_only_wrong\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="is_only_wrong" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"set_type\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="set_type" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"is_print\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="is_print" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"mode\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"test_q_type\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="test_q_type" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"test_q_cnt\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="test_q_cnt" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"test_q_cnt_bm\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="test_q_cnt_bm" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition:form-data; name=\"recall_condition_yn\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            body.append(
                "\(String(testPage.firstMatch(of: /name="recall_condition_yn" value="([0-9]+)"/)!.output.1))\r\n"
                    .data(using: .utf8)!
            )
            pCodes.enumerated().forEach { (idx, pCode) in
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition:form-data; name=\"test_question[]\"\r\n\r\n"
                        .data(using: .utf8)!
                )
                body.append("\(pCode)\r\n".data(using: .utf8)!)
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition:form-data; name=\"user_answer[]\"\r\n\r\n"
                        .data(using: .utf8)!
                )
                body.append("\(answerList[idx])\r\n".data(using: .utf8)!)
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition:form-data; name=\"gpt_correct[]\"\r\n\r\n"
                        .data(using: .utf8)!
                )
                body.append("\(gptCorrectVals[idx])\r\n".data(using: .utf8)!)
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition:form-data; name=\"subjective_yn[]\"\r\n\r\n"
                        .data(using: .utf8)!
                )
                body.append("\(isSubjectiveList[idx])\r\n".data(using: .utf8)!)
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition:form-data; name=\"first_letter_yn[]\"\r\n\r\n"
                        .data(using: .utf8)!
                )
                body.append("\(firstLtrYnVals[idx])\r\n".data(using: .utf8)!)
            }
            req5.httpBody = body
            URLSession.shared.dataTask(with: req5) {
                data,
                response,
                error in
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil
                else {
                    callback(false)
                    return
                }
                guard (200...299) ~= response.statusCode else {
                    callback(false)
                    return
                }
                callback(true)
            }.resume()
        }.resume()
    }.resume()
}

//func CompleteAllExams(
//    vm: ViewModel,
//    examIdxList: [String],
//    callback: @escaping ([Int]) -> Void
//) {
//    var result: [Int] = Array(repeating: 3, count: examIdxList.count)
//    examIdxList.forEach { examIdx in
//        if examIdx.starts(with: "solved_") {
//            result[examIdxList.firstIndex(of: examIdx)!] = 2
//        } else {
//            var req = URLRequest(
//                url: URL(string: "https://api2.eduspring.co.kr/ws/exam/set")!
//            )
//            req.httpMethod = "POST"
//            req.addValue(
//                "application/x-www-form-urlencoded; charset=UTF-8",
//                forHTTPHeaderField: "Content-Type"
//            )
//            req.addValue(vm.uuid, forHTTPHeaderField: "Uuid")
//            req.addValue(vm.token, forHTTPHeaderField: "Api_access_token")
//            req.httpBody =
//            "mem_Idx=\(vm.memIdx)&exam_Idx=\(examIdx)&exam_turn_idx=&paper_turn="
//                .data(using: .utf8)
//            URLSession.shared.dataTask(with: req) { data, response, error in
//                guard let data = data,
//                      let response = response as? HTTPURLResponse, error == nil
//                else {
//                    result[examIdxList.firstIndex(of: examIdx)!] = 0
//                    if result.filter { $0 < 3 }.count == examIdxList.count {
//                        callback(result)
//                    }
//                    return
//                }
//                guard (200...299) ~= response.statusCode else {
//                    result[examIdxList.firstIndex(of: examIdx)!] = 0
//                    if result.filter { $0 < 3 }.count == examIdxList.count {
//                        callback(result)
//                    }
//                    return
//                }
//                guard
//                    let output = try? JSONDecoder().decode(
//                        WSProblemSheet.self,
//                        from: data
//                    )
//                else {
//                    result[examIdxList.firstIndex(of: examIdx)!] = 0
//                    if result.filter { $0 < 3 }.count == examIdxList.count {
//                        callback(result)
//                    }
//                    return
//                }
//                let ans = WSAnswerList(
//                    problem1: output.problem1.flatMap { $0 }.map {
//                        WSAnswer(id: $0.id, stu_answer: $0.answer_real)
//                    },
//                    problem2: output.problem2.flatMap { $0 }.map {
//                        WSAnswer(id: $0.id, stu_answer: $0.answer_real)
//                    },
//                    problem3: output.problem3.flatMap { $0 }.map {
//                        WSAnswer(id: $0.id, stu_answer: $0.answer)
//                    },
//                    problem4: output.problem4.flatMap { $0 }.map {
//                        WSAnswer(id: $0.id, stu_answer: $0.answer_real)
//                    },
//                    problem5: output.problem5.flatMap { $0 }.map {
//                        WSAnswer(id: $0.id, stu_answer: $0.answer_real)
//                    }
//                )
//                var req2 = URLRequest(
//                    url: URL(
//                        string: "https://api2.eduspring.co.kr/ws/exam/submit"
//                    )!
//                )
//                req2.httpMethod = "POST"
//                req2.addValue(
//                    "application/x-www-form-urlencoded; charset=UTF-8",
//                    forHTTPHeaderField: "Content-Type"
//                )
//                req2.addValue(vm.uuid, forHTTPHeaderField: "Uuid")
//                req2.addValue(vm.token, forHTTPHeaderField: "Api_access_token")
//                req2.httpBody =
//                "examResult=\(String(data: try! JSONEncoder().encode(ans), encoding: .utf8)!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&turn_Idx=\(output.exam_turn_idx)&exam_Idx=\(examIdx)&mem_Idx=\(vm.memIdx)&exam_delay_sec=120"
//                    .data(using: .utf8)
//                URLSession.shared.dataTask(with: req2) {
//                    data,
//                    response,
//                    error in
//                    guard let data = data,
//                          let response = response as? HTTPURLResponse,
//                          error == nil
//                    else {
//                        result[examIdxList.firstIndex(of: examIdx)!] = 0
//                        if result.filter { $0 < 3 }.count == examIdxList.count {
//                            callback(result)
//                        }
//                        return
//                    }
//                    guard (200...299) ~= response.statusCode else {
//                        result[examIdxList.firstIndex(of: examIdx)!] = 0
//                        if result.filter { $0 < 3 }.count == examIdxList.count {
//                            callback(result)
//                        }
//                        return
//                    }
//                    result[examIdxList.firstIndex(of: examIdx)!] = 1
//                    if result.filter { $0 < 3 }.count == examIdxList.count {
//                        callback(result)
//                    }
//                    return
//                }
//                .resume()
//            }
//            .resume()
//        }
//    }
//}
