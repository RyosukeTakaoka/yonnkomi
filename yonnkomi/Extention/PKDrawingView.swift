import UIKit
import PencilKit

extension PKDrawing {
    /// SwiftUIのキャンバス全体サイズで画像化（白背景）
    func toImage(
        canvasSize: CGSize,
        scale: CGFloat = UIScreen.main.scale,
        backgroundColor: UIColor = .white
    ) -> UIImage {
        let rect = CGRect(origin: .zero, size: canvasSize)

        // PencilKitの正規APIでビットマップ化
        let strokesImage = self.image(from: rect, scale: scale)

        // 白背景に合成（投稿先で透過が嫌な場合に有効）
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)

        return renderer.image { _ in
            backgroundColor.setFill()
            UIRectFill(rect)
            strokesImage.draw(in: rect)
        }
    }
}
