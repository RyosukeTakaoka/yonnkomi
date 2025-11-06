import SwiftUI
import PencilKit
//漫画を描いて編集できる画面
// MARK: - SwiftUI版 CanvasView
struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var isEditable: Bool
    
    let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .white
        canvasView.drawing = drawing
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 30)
        if #available(iOS 14.0, *) {
            canvasView.drawingPolicy = .anyInput
        }
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
        uiView.isUserInteractionEnabled = isEditable
        
        if isEditable {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        init(_ parent: CanvasView) { self.parent = parent }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - CreateView
struct CreateView: View {
    @State private var drawings: [PKDrawing] = Array(repeating: PKDrawing(), count: 4)
    @State private var pageIndex = 0
    @State private var isEditingMode = false
    @State private var capturedImages: [UIImage] = []
    @State private var canvasSize: CGSize = .zero
    @State private var shouldResetCanvas = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                CanvasView(drawing: $drawings[pageIndex], isEditable: isEditingMode)
                    .id(pageIndex)
                    .background(Color.white)
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { canvasSize = $0 }
            }
            
            HStack {
                // ページ切替用ボタンや他のUIもここに
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button("＜ 前へ") {
                    pageIndex = (pageIndex == 0) ? drawings.count - 1 : pageIndex - 1
                }
                Button("次へ ＞") {
                    pageIndex = (pageIndex == drawings.count - 1) ? 0 : pageIndex + 1
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(isEditingMode ? "完了" : "編集") { isEditingMode.toggle() }
                NavigationLink {
                    PostView(
                        canvasImages: drawings.map { $0.toImage(canvasSize: canvasSize) },
                        shouldResetCanvas: $shouldResetCanvas
                    )
                } label: {
                    Text("投稿")
                }
            }
        }
        .navigationTitle("\(pageIndex + 1)/4")
        .navigationBarTitleDisplayMode(.inline)
    }
}
