//
//  Login.swift
//  PassCard
//
//  Created by Seongwon Min on 8/5/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var vm: ViewModel;
    @AppStorage("id") private var id: String = "";
    @AppStorage("pw") private var pw: String = "";
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var logining = false;
    @State private var incorrect = false;
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text("PassCard")
                            .bold()
                            .font(.largeTitle)
                        Text("Complete ClassCard Exams Instantly.\nNo Credit Card Required.")
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }
                    Spacer()
                }
            }
            Section("Login with ClassCard Account") {
                TextField("Username", text: $username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .disabled(logining)
                ZStack(alignment: .trailing) {
                    SecureField("Password", text: $password)
                        .onSubmit {
                            logining = true;
                            Login(username: username, password: password, vm: vm) {isSuccess, credential in
                                logining = false;
                                guard isSuccess == true else {
                                    password = "";
                                    incorrect = true;
                                    return;
                                }
                                guard credential != nil else {
                                    return;
                                }
                                id = username;
                                pw = password;
                                vm.userID = credential!.userID;
                                vm.classID = credential!.classID;
                                vm.name = credential!.name;
                                vm.phone = credential!.phone;
                                vm.logined = true;
                            }
                        }
                        .disabled(logining)
                    if (logining) {
                        ProgressView()
                    }
                }
            }
            Section {
                Button {
                    logining = true;
                    Login(username: username, password: password, vm: vm) {isSuccess, credential in
                        logining = false;
                        guard isSuccess == true else {
                            password = "";
                            incorrect = true;
                            return;
                        }
                        guard credential != nil else {
                            return;
                        }
                        id = username;
                        pw = password;
                        vm.userID = credential!.userID
                        vm.classID = credential!.classID
                        vm.name = credential!.name
                        vm.phone = credential!.phone
                        vm.logined = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Login")
                        Spacer()
                    }
                }
                .disabled(logining)
            }
        }
        .alert("Login Failed", isPresented: $incorrect) {
            Button("OK", role: .cancel) {};
        } message: {
            Text("Please check your ID and Password.")
        }
        
    }
}

#Preview {
    LoginView()
}
