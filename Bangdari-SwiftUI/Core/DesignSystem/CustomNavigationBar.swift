//
//  CustomNavigationBar.swift
//  Bangdari-SwiftUI
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

// MARK: - Custom Navigation Bar

/// 앱 전체에서 사용하는 커스텀 네비게이션 바 컴포넌트
///
/// 공통 스타일(높이 56, 배경 gray0)을 유지하면서
/// Leading, Center, Trailing 영역을 ViewBuilder로 자유롭게 커스터마이징 가능
///
/// **기본 사용 (Back 버튼 자동):**
/// ```swift
/// CustomNavigationBar(onBack: { dismiss() }) {
///     Text("제목")
/// } trailing: {
///     Button("저장") { }
/// }
/// ```
///
/// **고급 사용 (Leading 커스텀):**
/// ```swift
/// CustomNavigationBar(showDefaultBackButton: false) {
///     Button("취소") { dismiss() }
/// } center: {
///     Text("제목")
/// } trailing: {
///     Button("완료") { save() }
/// }
/// ```

// MARK: - Usage Guidelines

/// ## 네비게이션 바 아이콘 크기 가이드
///
/// 모든 네비게이션 바 아이콘은 `DesignSystem.Layout.IconSize` 상수를 사용합니다:
/// - **보조 아이콘** (위치 등): `IconSize.small` (16pt)
/// - **주요 버튼** (검색, 리스트, 지도): `IconSize.medium` (20pt)
/// - **강조 버튼** (찜하기): `IconSize.large` (24pt)
/// - **뱃지**: `IconSize.xsmall` (14pt)
///
/// ## 네비게이션 바 텍스트 크기 가이드
///
/// - **네비게이션 바 제목/주요 텍스트**: `.pretendardBody1Bold` (16pt bold)
/// - **보조 텍스트/위치**: `.pretendardBody2Bold` (14pt semibold)
///
/// ## 예시
/// ```swift
/// // 위치 + 텍스트
/// HStack(spacing: 6) {
///     DSIconView(.location, size: DesignSystem.Layout.IconSize.small, renderingMode: .template)
///         .foregroundColor(.deepWood)
///     Text("서울 강남구")
///         .font(.pretendardBody1Bold)
///         .foregroundColor(.gray90)
/// }
///
/// // 검색 버튼
/// Button {
///     // action
/// } label: {
///     DSIconView(.search, size: DesignSystem.Layout.IconSize.medium, renderingMode: .template)
///         .foregroundColor(.gray90)
/// }
///
/// // 찜하기 버튼
/// DSIconView(.likeFill, size: DesignSystem.Layout.IconSize.large, renderingMode: .template)
///     .foregroundColor(.red)
/// ```
struct CustomNavigationBar<Leading: View, Center: View, Trailing: View>: View {
    private let showDefaultBackButton: Bool
    private let onBack: (() -> Void)?
    private let leadingContent: () -> Leading
    private let centerContent: () -> Center
    private let trailingContent: () -> Trailing

    /// 기본 초기화 (Back 버튼 자동 포함)
    /// - Parameters:
    ///   - onBack: Back 버튼 탭 액션
    ///   - center: 중앙 영역 (ViewBuilder)
    ///   - trailing: 우측 영역 (ViewBuilder, 기본값: EmptyView)
    init(
        onBack: @escaping () -> Void,
        @ViewBuilder center: @escaping () -> Center,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) where Leading == EmptyView {
        self.showDefaultBackButton = true
        self.onBack = onBack
        self.leadingContent = { EmptyView() }
        self.centerContent = center
        self.trailingContent = trailing
    }

    /// 확장 초기화 (Leading 커스터마이징 가능)
    /// - Parameters:
    ///   - showDefaultBackButton: 기본 Back 버튼 표시 여부 (기본값: true)
    ///   - onBack: Back 버튼 탭 액션 (showDefaultBackButton이 true일 때 필수)
    ///   - leading: 좌측 영역 (ViewBuilder)
    ///   - center: 중앙 영역 (ViewBuilder)
    ///   - trailing: 우측 영역 (ViewBuilder, 기본값: EmptyView)
    init(
        showDefaultBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder center: @escaping () -> Center,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.showDefaultBackButton = showDefaultBackButton
        self.onBack = onBack
        self.leadingContent = leading
        self.centerContent = center
        self.trailingContent = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            // Leading 영역
            if showDefaultBackButton {
                // 기본 Back 버튼
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray90)
                }
            } else {
                // 커스텀 Leading
                leadingContent()
            }

            // Center 영역
            centerContent()

            Spacer()

            // Trailing 영역
            trailingContent()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.gray0)
    }
}

// MARK: - Convenience Extensions

extension CustomNavigationBar where Leading == EmptyView, Trailing == EmptyView {
    /// 제목만 있는 간단한 네비게이션 바
    init(
        onBack: @escaping () -> Void,
        title: String
    ) where Center == Text {
        self.init(onBack: onBack) {
            Text(title)
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)
        }
    }
}

// MARK: - Preview

#Preview("기본 제목") {
    CustomNavigationBar(onBack: {}, title: "화면 제목")
}

#Preview("위치 + 지도 버튼") {
    CustomNavigationBar(onBack: {}) {
        HStack(spacing: 6) {
            DSIconView(.location, size: DesignSystem.Layout.IconSize.small, renderingMode: .template)
                .foregroundColor(.deepWood)

            Text("서울 강남구")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)
        }
    } trailing: {
        Button {} label: {
            DSIconView(.map, size: DesignSystem.Layout.IconSize.medium, renderingMode: .template)
                .foregroundColor(.gray90)
        }
    }
}

#Preview("찜하기 버튼") {
    CustomNavigationBar(onBack: {}) {
        Text("매물 상세")
            .font(.pretendardBody1Bold)
            .foregroundColor(.gray90)
    } trailing: {
        Button {} label: {
            DSIconView(.likeFill, size: 24, renderingMode: .template)
                .foregroundColor(.red)
        }
    }
}

#Preview("커스텀 Leading (취소/완료)") {
    CustomNavigationBar(showDefaultBackButton: false) {
        Button("취소") {}
            .foregroundColor(.gray75)
    } center: {
        Text("글 작성")
            .font(.pretendardBody1Bold)
            .foregroundColor(.gray90)
    } trailing: {
        Button("완료") {}
            .font(.pretendardBody2Bold)
            .foregroundColor(.deepWood)
    }
}
