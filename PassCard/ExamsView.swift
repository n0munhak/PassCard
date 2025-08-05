//
//  ExamsView.swift
//  PassCard
//
//  Created by Seongwon Min on 8/55/25.
//

import SwiftUI

struct ExamsView: View {
    @EnvironmentObject var vm: ViewModel;
    @State private var exams: [Exam] = [];
    @State private var hasError = false;
    @State private var failedToComplete = false;
    @State private var failedToCompleteName = "";
    @State private var showAccountPage = false;
    var body: some View {
        if (hasError) {
            Text("Error...")
        } else {
                NavigationStack {
                    if (exams.count == 0) {
                        Text("There are no exams currently available.")
                            .navigationTitle("Available Exams")
//                            .toolbar {
//                                Button {
//                                    showAccountPage = true;
//                                } label: {
//                                    Image(systemName: "person.crop.circle")
//                                }
//                            }
                    } else {
                        List {
                            ForEach($exams, id: \.self) {$exam in
                                HStack {
                                    Text(exam.name)
                                    Spacer()
                                    switch exam.state {
                                    case 0:
                                        Button {
                                            exam.state = 1;
                                            CompleteExam(vm: vm, exam: exam) {isSuccess in
                                                if (isSuccess) {
                                                    exam.state = 2;
                                                } else {
                                                    exam.state = 0;
                                                    failedToCompleteName = exam.name;
                                                    failedToComplete = true;
                                                }
                                            }
                                        } label: {
                                            Text("Complete")
                                        }
                                    case 1:
                                        ProgressView()
                                    case 2:
                                        Image(systemName: "checkmark.circle")
                                            .imageScale(.large)
                                            .foregroundStyle(.blue)
                                    default:
                                        Divider()
                                    }
                                }
                                
                            }
                        }
                        .navigationTitle("Available Exams")
                        .toolbar {
                            Button {
                                showAccountPage = true;
                            } label: {
                                Image(systemName: "person.crop.circle")
                            }
                        }
                    }
                }
//                .toolbar {
//                    ToolbarItemGroup(placement: .bottomBar) {
//                        Button {
//                            $exams.filter { $0.state.wrappedValue == 0 }.forEach {$exam in
//                                exam.state = 1;
//                            }
//                            ComleteAllExams(vm: vm, examIdxList: exams.map { $0.state != 2 ? $0.id : "solved_\($0.id)" }) {isSuccessList in
//                                var cnt = 0;
//                                var hasError = false;
//                                isSuccessList.forEach {isSuccess in
//                                    if (exams[cnt].state == 1) {
//                                        if (isSuccess == 1) {
//                                            exams[cnt].state = 2;
//                                        } else if (isSuccess == 0) {
//                                            exams[cnt].state = 0;
//                                            hasError = true;
//                                        }
//                                    }
//                                    cnt += 1;
//                                }
//                                if (hasError) {
//                                    failedToCompleteName = "some exams";
//                                    failedToComplete = true;
//                                }
//                            }
//                        } label: {
//                            Text("Complete All")
//                        }
//                        .disabled(exams.count == 0 || !exams.contains { $0.state == 0 } || exams.contains { $0.state == 1 })
//                    }
//                }
                .alert("Failed To Complete", isPresented: $failedToComplete) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Failed to complete \(failedToCompleteName).")
                }
                .sheet(isPresented: $showAccountPage) {
                    MyInfo(showAccountPage: $showAccountPage);
                }
            .onAppear {
                var req = URLRequest(url: URL(string: "https://www.classcard.net/ClassMain/\(vm.classID)")!)
                req.addValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                req.addValue("ci_session=\(vm.sessionID)", forHTTPHeaderField: "Cookie");
                URLSession.shared.dataTask(with: req) {data, response, error in
                    guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                        hasError = true;
                        return;
                    }
                    guard (200 ... 299) ~= response.statusCode else {
                        hasError = true;
                        return;
                    }
                    let page = String(data: data, encoding: .utf8)!;
                    exams = page.matches(of: /<a class="anchor-underline set-name-a" data-idx="([0-9]+)">(.*)<span class="text-gray font-13 font-normal m-l">([0-9]+) 카드<\/span><\/a>/).map {match in
                        Exam(id: String(match.output.1), name: String(match.output.2), numCards: String(match.output.3), state: 0)
                    };
                }
                .resume();
            }
        }
    }
}
#Preview {
    ExamsView()
}
