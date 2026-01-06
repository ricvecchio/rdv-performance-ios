import SwiftUI
import SpriteKit

struct SpriteDemoView: View {
    var scene: SKScene {
        let s = GameScene(size: CGSize(width: 375, height: 600))
        s.scaleMode = .resizeFill
        return s
    }

    var body: some View {
        SpriteView(scene: scene)
            .frame(height: 400)
            .navigationTitle("SpriteKit")
    }
}

struct SpriteDemoView_Previews: PreviewProvider {
    static var previews: some View {
        SpriteDemoView()
    }
}
