//
//  ContentView.swift
//  RefreshScrollView
//
//  Created by kang on 2023/1/30.
//

import SwiftUI

struct ContentView: View {
    
    let colors: [Color] = [.red, .yellow, .blue, .orange, .green]
        
    var body: some View {
        VStack(spacing: 0) {
            Text("支持刷新的ScrollView")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)
                .frame(height: 30)
                .padding()
        }
        
        RefreshScrollView {
            ForEach(1..<20, id: \.self) { i in
                colors[i%5].frame(height: 100)
            }
        } onHeaderRefresh: { completion in
            Task {
                try await asycTask()
                completion()
                print("下拉请求结束")
            }
        } onFooterRefresh: { completion in
            Task {
                try await asycTask()
                completion()
                print("上拉请求结束")
            }
        }
    }
    
    func asycTask() async throws{
        try await Task.sleep(nanoseconds: 2 * 1000 * 1000 * 1000)
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

