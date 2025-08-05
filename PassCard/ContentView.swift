//
//  ContentView.swift
//  PassCard
//
//  Created by Seongwon Min on 8/5/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel
    @AppStorage("id") private var id = ""
    @AppStorage("pw") private var pw = ""
    var body: some View {
        if vm.logined {
            ExamsView()
        } else {
            LoginView()
                .onAppear {
                    GetSessionID { isSuccess, sess in
                        if isSuccess {
                            vm.sessionID = sess!;
                            Login(username: id, password: pw, vm: vm)
                            {
                                isSuccess,
                                credential in
                                if isSuccess {
                                    vm.userID = credential!.userID
                                    vm.classID = credential!.classID
                                    vm.name = credential!.name
                                    vm.phone = credential!.phone
                                    vm.logined = true
                                }
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
