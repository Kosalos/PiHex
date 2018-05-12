import UIKit

class GameView: UIView {

    override func draw(_ rect: CGRect) {
        game.draw()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchBegan(touch.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchMoved(touch.location(in: self))
        }
    }
}

//MARK:-

extension String {
    func drawSize(_ font: UIFont) -> CGSize { return (self as NSString).size(withAttributes: [NSAttributedStringKey.font: font]) }
}

extension CGPoint {
    mutating func offset(_ dx:CGFloat, _ dy:CGFloat) {
        x += dx
        y += dy
    }
}

func drawCenteredText(_ x:CGFloat, _ y:CGFloat, _ color:UIColor, _ sz:CGFloat, _ str:String) {
    let font = UIFont.init(name: "Helvetica", size:sz)
    let textFontAttributes = [
        NSAttributedStringKey.font:font,
        NSAttributedStringKey.foregroundColor: color,
    ]

    let sz = str.drawSize(font!)
    let px = x - sz.width/2
    let py = y - sz.height/2
    
    str.draw(in: CGRect(x:px, y:py, width:800, height:100), withAttributes: textFontAttributes as Any as? [NSAttributedStringKey : Any])
}

func drawCenteredText(_ pt:CGPoint, _ color:UIColor, _ sz:CGFloat, _ str:String) { drawCenteredText(pt.x,pt.y,color,sz,str) }


