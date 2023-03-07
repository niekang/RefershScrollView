//
//  RefreshModel.swift
//  SwiftUIDemo
//
//  Created by kang on 2023/3/7.
//

import SwiftUI
import Combine

enum RefreshState {
    case normal
    case pullUp
    case pullDown
    case refreshHeader
    case refreshFooter
}

class RefreshModel: ObservableObject {
    let progressViewHeight: CGFloat = 40
    var normalOffset: CGFloat = 0
    
    var scrollViewHeight: CGFloat = 0
    var scrollViewContentHeight: CGFloat = 0
    
    @Published var refreshFooterCurHeight: CGFloat = 0
    
    @Published var curOffsetY: CGFloat = 0
    @Published var refreshHeaderCurHeight: CGFloat = 0
    @Published var state: RefreshState = .normal
    
    private var cancellable: Set<AnyCancellable> = []
    
    private var progressViewHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.CombineLatest($curOffsetY, $state)
            .map { curOffsetY, state in
                var progViewH = curOffsetY - self.normalOffset
                if state == .refreshHeader {
                    if progViewH < self.refreshHeaderCurHeight {
                        progViewH = self.refreshHeaderCurHeight
                    }
                }
                if progViewH < 0 {
                    progViewH = 0
                }
                return progViewH
            }
            .eraseToAnyPublisher()
    }
    
    private var canRefreshPublisher: AnyPublisher<Bool, Never> {
        
        Publishers.CombineLatest($curOffsetY, $state)
            .map { curOffsetY, state in
                if curOffsetY - self.normalOffset <= self.refreshHeaderCurHeight && state == .pullDown {
                    return true
                }else {
                    return false
                }
        }.eraseToAnyPublisher()
    }
    
    init() {
        progressViewHeightPublisher
            .dropFirst()
            .removeDuplicates()
            .sink { height in
                DispatchQueue.main.async {
                    if self.state == .pullDown {
                        self.refreshHeaderCurHeight = height
                    }else {
                        withAnimation {
                            self.refreshHeaderCurHeight = height
                        }
                    }
                }
            }
            .store(in: &cancellable)
        
        canRefreshPublisher
            .dropFirst()
            .removeDuplicates()
            .sink { canRefresh in
                if canRefresh {
                    self.state = .refreshHeader
                    
                }
            }
            .store(in: &cancellable)
    }
}
