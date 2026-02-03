//
//  NavigationBarModifier.swift
//  Bangdari-SwiftUI
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

// MARK: - Navigation Bar Style Modifier

extension View {
    /// 앱 전체 네비게이션 바 스타일 통일
    /// - Parameters:
    ///   - title: 네비게이션 타이틀 (optional)
    ///   - displayMode: 타이틀 표시 모드 (기본값: .inline)
    /// - Returns: 스타일이 적용된 View
    func standardNavigationBar(
        title: String? = nil,
        displayMode: NavigationBarItem.TitleDisplayMode = .inline
    ) -> some View {
        self.modifier(StandardNavigationBarModifier(title: title, displayMode: displayMode))
    }
}

private struct StandardNavigationBarModifier: ViewModifier {
    let title: String?
    let displayMode: NavigationBarItem.TitleDisplayMode

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            // iOS 26 Liquid Glass와 충돌하므로 제거
            // .toolbarColorScheme(.light, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(uiColor: UIColor(named: "gray90") ?? .label))
                    }
                }
            }
    }
}
