//
//  RefreshScrollView.swift
//  RefreshScrollView
//
//  Created by kang on 2023/1/30.
//

import SwiftUI

typealias RefreshCompletion = () -> Void

typealias OnRefresh = (@escaping RefreshCompletion) -> Void

struct RefreshScrollView<Content: View>: View {
    
    let content: () -> Content
    
    let onHeaderRefresh: OnRefresh
    let onFooterRefresh: OnRefresh

    @StateObject private var refreshModel = RefreshModel()

    var body: some View {
        ScrollView(.vertical) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    GeometryReader { proxy -> AnyView in
                        offsetViewProxyHandle(proxy)
                        return AnyView(Color.clear)
                    }.frame(height: 0)
                    
                    VStack(spacing: 0){
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            if refreshModel.state  == .refreshHeader {
                                ProgressView()
                                    .frame(height: refreshModel.progressViewHeight)
                            }else {
                                Image(systemName: "arrow.down")
                                    .frame(height: refreshModel.progressViewHeight)
                                    .rotationEffect(.init(degrees: refreshModel.state == .normal ? 0 : 180))
                                    .opacity(refreshModel.refreshHeaderCurHeight == 0 ? 0 : 1)
                            }
                        }
                        .frame(height: refreshModel.refreshHeaderCurHeight)
                        .clipped()
                        content()
                    }.overlay {
                        GeometryReader { proxy -> AnyView in
                            let height = proxy.frame(in: .global).height
                            DispatchQueue.main.async {
                                if refreshModel.scrollViewContentHeight != height {
                                    refreshModel.scrollViewContentHeight  = height
                                }
                            }
                            return AnyView(Color.clear)
                        }
                    }
                }
                .offset(y: refreshModel.state == .refreshFooter ? -refreshModel.progressViewHeight : 0)
                
                VStack {
                    Spacer(minLength: 0)
                    if refreshModel.state  == .refreshFooter {
                        ProgressView()
                            .frame(height: refreshModel.progressViewHeight)
                    }else {
                        Image(systemName: "arrow.down")
                            .frame(height: refreshModel.progressViewHeight)
                            .rotationEffect(.init(degrees: refreshModel.state == .normal ? 0 : 180))
                            .opacity(refreshModel.refreshFooterCurHeight == 0 ? 0 : 1)
                    }
                }
                .frame(height: refreshModel.state == .refreshFooter ? refreshModel.progressViewHeight : refreshModel.refreshFooterCurHeight)
                .frame(maxWidth: .infinity)
                .clipped()
                .offset(y: refreshModel.state == .refreshFooter ? 0 : refreshModel.refreshFooterCurHeight)
                .zIndex(1)
            }
        }
//        .modifier(SizeModifier(height: $refreshModel.scrollViewHeight))
        .overlay(content: {
            GeometryReader { proxy -> AnyView in
                let height = proxy.frame(in: .global).height
                DispatchQueue.main.async {
                    if refreshModel.scrollViewHeight != height {
                        refreshModel.scrollViewHeight = height
                    }
                }
                return AnyView(Color.clear)
            }
        })
        .onChange(of: refreshModel.state) { newValue in
            print(newValue)
            if newValue == .refreshHeader {
                onHeaderRefresh {
                    DispatchQueue.main.async {
                        withAnimation {
                            refreshModel.state = .normal
                        }
                    }
                }
            }
            
            if newValue == .refreshFooter {
                onFooterRefresh {
                    DispatchQueue.main.async {
                        withAnimation {
                            refreshModel.state = .normal
                        }
                    }
                }
            }
        }
    }
    
    init(@ViewBuilder content: @escaping () -> Content, onHeaderRefresh: @escaping OnRefresh, onFooterRefresh: @escaping OnRefresh) {
        self.content = content
        self.onHeaderRefresh = onHeaderRefresh
        self.onFooterRefresh = onFooterRefresh
    }
    
    func offsetViewProxyHandle(_ proxy: GeometryProxy) {
        
        let minY = proxy.frame(in: .global).minY
        if refreshModel.normalOffset == 0 {
            refreshModel.normalOffset = minY
        }
        
        DispatchQueue.main.async {
            if (refreshModel.curOffsetY != minY) {
                refreshModel.curOffsetY = minY
            }
            if minY > 0 {
                if refreshModel.curOffsetY - refreshModel.normalOffset > refreshModel.progressViewHeight && refreshModel.state == .normal {
                    withAnimation {
                        refreshModel.state = .pullDown
                    }
                }
            }else {
                if refreshModel.scrollViewHeight > refreshModel.scrollViewContentHeight || refreshModel.scrollViewHeight == 0 || refreshModel.scrollViewContentHeight == 0 {
                    refreshModel.refreshFooterCurHeight = 0
                }else {
                    let refreshFooterCurH = refreshModel.normalOffset - minY + refreshModel.scrollViewHeight - refreshModel.scrollViewContentHeight
                    if refreshFooterCurH > 0 && refreshModel.state != .refreshFooter {
                        refreshModel.refreshFooterCurHeight = refreshFooterCurH
                    }
                                                
                    if refreshFooterCurH > refreshModel.progressViewHeight && refreshModel.state == .normal {
                        withAnimation {
                            refreshModel.state = .pullUp
                        }
                    }else if refreshFooterCurH > refreshModel.progressViewHeight && refreshModel.state == .pullUp {
                        withAnimation {
                            refreshModel.state = .refreshFooter
                        }
                    }
                }
            }
                        
        }
    }
}

struct SizeModifier: ViewModifier {
    
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy -> AnyView in
                if height != proxy.size.height {
                    height = proxy.size.height
                }
                return AnyView(Color.clear)
            }
        )
    }
}
