//
//  MyInfo.swift
//  PassCard
//
//  Created by Seongwon Min on 8/5/25.
//

import SwiftUI

struct MyInfo: View {
    @EnvironmentObject var vm: ViewModel;
    @AppStorage("id") private var id: String = "";
    @AppStorage("pw") private var pw: String = "";
    @Binding var showAccountPage: Bool;
    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(vm.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Phone Number")
                    Spacer()
                    Text(vm.phone)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(id)
            .toolbar {
                Button {
                    showAccountPage = false;
                } label: {
                    Text("Done");
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack(spacing: 0) {
                        Spacer()
                        Button(role: .destructive) {
                            id = "";
                            pw = "";
                            vm.logined = false;
                        } label: {
                            Text("Logout")
                        }
                        .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    let vm = ViewModel();
    vm.name = "홍길동";
    vm.phone = "01012345678";
    return MyInfo(showAccountPage: .constant(true))
        .environmentObject(vm)
}
