//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Shape.swift
//
//  Created by Josh Holtz on 9/30/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ShapeModifier: ViewModifier {

    struct BorderInfo {

        let color: Color
        let width: CGFloat

        init(color: Color, width: Double) {
            self.color = color
            self.width = width
        }

    }

    enum Shape {

        case rectangle(RadiusInfo?)
        case pill
        case concave
        case convex

    }

    struct RadiusInfo {

        let topLeft: CGFloat?
        let topRight: CGFloat?
        let bottomLeft: CGFloat?
        let bottomRight: CGFloat?

        init(topLeft: Double? = nil, topRight: Double? = nil, bottomLeft: Double? = nil, bottomRight: Double? = nil) {
            self.topLeft = topLeft.flatMap { CGFloat($0) }
            self.topRight = topRight.flatMap { CGFloat($0) }
            self.bottomLeft = bottomLeft.flatMap { CGFloat($0) }
            self.bottomRight = bottomRight.flatMap { CGFloat($0) }
        }

    }

    var border: BorderInfo?
    var shape: Shape

    init(border: BorderInfo? = nil, shape: Shape?) {
        self.border = border
        self.shape = shape ?? .rectangle(nil)
    }

    func body(content: Content) -> some View {
        switch self.shape {
        case .rectangle(let radiuses):
            content
                .conditionalClipShape(topLeft: radiuses?.topLeft,
                                      topRight: radiuses?.topRight,
                                      bottomLeft: radiuses?.bottomLeft,
                                      bottomRight: radiuses?.bottomRight)
                .conditionalOverlay(color: self.border?.color,
                                    width: self.border?.width,
                                    topLeft: radiuses?.topLeft,
                                    topRight: radiuses?.topRight,
                                    bottomLeft: radiuses?.bottomLeft,
                                    bottomRight: radiuses?.bottomRight)
        case .pill:
            content
                .clipShape(Capsule())
                .applyIfLet(self.border, apply: { view, border in
                    view.overlay(
                        Capsule()
                            .stroke(border.color, lineWidth: border.width)
                    )
                })
        case .concave:
            // WIP: Need to implement
            content
        case .convex:
            // WIP: Need to implement
            content
        }
    }
}

// Helper extensions to conditionally apply clipShape and overlay without AnyView

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func conditionalClipShape(
        topLeft: CGFloat?,
        topRight: CGFloat?,
        bottomLeft: CGFloat?,
        bottomRight: CGFloat?
    ) -> some View {
        Group {
            if let topLeft = topLeft,
                let topRight = topRight,
                let bottomLeft = bottomLeft,
                let bottomRight = bottomRight,
                topLeft > 0 || topRight > 0 || bottomLeft > 0 || bottomRight > 0 {
                    self
                        .applyIf(topLeft > 0) {
                            $0.clipShape(SingleRoundedCornerShape(radius: topLeft, corners: [.topLeft]))
                        }
                        .applyIf(topRight > 0) {
                            $0.clipShape(SingleRoundedCornerShape(radius: topLeft, corners: [.topRight]))
                        }
                        .applyIf(bottomLeft > 0) {
                            $0.clipShape(SingleRoundedCornerShape(radius: topLeft, corners: [.bottomLeft]))
                        }
                        .applyIf(bottomRight > 0) {
                            $0.clipShape(SingleRoundedCornerShape(radius: topLeft, corners: [.bottomRight]))
                        }
            } else {
                self
            }
        }
    }

    // swiftlint:disable:next function_parameter_count
    func conditionalOverlay(
        color: Color?,
        width: CGFloat?,
        topLeft: CGFloat?,
        topRight: CGFloat?,
        bottomLeft: CGFloat?,
        bottomRight: CGFloat?
    ) -> some View {
        Group {
            if let color = color, let width = width, width > 0 {
                if let topLeft = topLeft,
                    let topRight = topRight,
                    let bottomLeft = bottomLeft,
                    let bottomRight = bottomRight,
                    topLeft > 0 || topRight > 0 || bottomLeft > 0 || bottomRight > 0 {
                        self.overlay(
                            BorderRoundedCornerShape(
                                topLeft: topLeft,
                                topRight: topRight,
                                bottomLeft: bottomLeft,
                                bottomRight: bottomRight
                            )
                            .stroke(color, lineWidth: width)
                        )
                } else {
                    self
                        .border(color, width: width)
                }
            } else {
                self
            }
        }
    }

}

private struct SingleRoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private struct BorderRoundedCornerShape: Shape {
    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start from the top-left corner
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))

        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                          control: CGPoint(x: rect.maxX, y: rect.minY))

        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))

        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                          control: CGPoint(x: rect.minX, y: rect.maxY))

        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addQuadCurve(to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func shape(
        border: ShapeModifier.BorderInfo?,
        shape: ShapeModifier.Shape?
    ) -> some View {
        self.modifier(
            ShapeModifier(
                border: border,
                shape: shape
            )
        )
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CornerBorder_Previews: PreviewProvider {

    static var previews: some View {
        // Equal Radius - No Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: nil,
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 8,
                                            bottomLeft: 8,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Equal Radius - No Border")

        // No - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 4),
                    shape: nil)
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("No Right - Blue Border")

        // Top Left and Bottom Right Radius - No Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: nil,
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 0,
                                            bottomLeft: 0,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Top Left and Bottom Right Radius - No Border")

        // Equal Radius - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 6),
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 8,
                                            bottomLeft: 8,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Equal Radius - Blue Border")

        // Top Left and Bottom Right Radius - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 6),
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 0,
                                            bottomLeft: 0,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Top Left and Bottom Right - Blue Border")
    }
}

#endif

#endif
