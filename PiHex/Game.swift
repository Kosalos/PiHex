import UIKit

var level:Int = 0
var boardSize = Position(0,0)

let NONE:Int = -1
var SX:CGFloat = 0
var SY:CGFloat = 0
let CELLSIZE:CGFloat = 32
let GAP:CGFloat = 3
let SIZE:CGFloat = CELLSIZE + GAP

var lowScore:UIImage! = nil
var highScore:UIImage! = nil
var okayScore:UIImage! = nil

let gCount:[Int] = [ 4,6,8,12 ]  // # playing pieces
let bdSize:[Position] = [ Position(8,8),Position(10,11),Position(12,14),Position(14,18)]    // size of board

struct Position {
    var x = Int()
    var y = Int()
    
    init() { x = 0; y = 0 }
    init(_ nx:Int, _ ny:Int) { x = nx; y = ny }
    mutating func offset(_ dx:Int, _ dy:Int) { x += dx; y += dy }
    
    static func += ( lhs: inout Position, rhs: Position) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
    static func -= ( lhs: inout Position, rhs: Position) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
    static func == ( lhs: inout Position, rhs: Position) -> Bool {
        return lhs.x == rhs.x &&  lhs.y == rhs.y
    }
}

func screenCoordinate(_ x:Int, _ y:Int) -> CGPoint { return CGPoint(x:SX + CGFloat(x) * SIZE, y:SY + CGFloat(y) * SIZE) }

func cellRect(_ x:Int, _ y:Int) -> CGRect {
    var rect = CGRect()
    rect.origin = screenCoordinate(x,y)
    rect.size = CGSize(width:CELLSIZE, height:CELLSIZE)
    return rect
}

func isOnBoardPosition(_ x:Int, _ y:Int) -> Bool { return x >= 0 && x < boardSize.x && y >= 0 && y < boardSize.y }

func calcLogicalPosition(_ pt:CGPoint) -> Position {
    var ans = Position()
    ans.x = Int(pt.x - SX) / Int(SIZE)
    ans.y = Int(pt.y - SY) / Int(SIZE)
    return ans
}

//MARK:-

let gg:CGFloat = 0.7

let playingPieceColor:[UIColor] = [
    UIColor(red:0, green:gg/2, blue:gg, alpha:1),
    UIColor(red:0, green:gg, blue:0, alpha:1),
    UIColor(red:0, green:gg, blue:gg, alpha:1),
    UIColor(red:gg, green:gg/2, blue:0, alpha:1),
    UIColor(red:gg, green:0, blue:gg, alpha:1),
]

struct Group {
    var pos = Position(0,0)
    var size = Position(0,0)
    var value = Int()
    
    init(_ npos:Position, _ nsize:Position, _ nvalue:Int) { pos = npos;  size = nsize;  value = nvalue  }
    func lowerRightCorner() -> Position { return Position(pos.x + size.x, pos.y + size.y) }
    
    func center() -> CGPoint {
        var pt = screenCoordinate(pos.x,pos.y)
        pt.x += CGFloat(size.x) * CELLSIZE/2
        pt.y += CGFloat(size.y) * CELLSIZE/2
        return pt
    }
    
    func draw() {
        var rect = CGRect()
        rect.origin = screenCoordinate(pos.x,pos.y)
        rect.size = CGSize(width:SIZE * CGFloat(size.x) - GAP, height:SIZE * CGFloat(size.y) - GAP)
        drawBevelledRect(rect,playingPieceColor[value-1])
        
        drawCenteredText(center(),.black,20,value.description)
    }
    
    mutating func move(_ dx:Int, _ dy:Int) {
        pos.offset(dx,dy)
        let pos2 = lowerRightCorner()
        if pos.x < 0 { pos.x = 0 } else if pos2.x >= boardSize.x { pos.x = boardSize.x - size.x }
        if pos.y < 0 { pos.y = 0 } else if pos2.y >= boardSize.y { pos.y = boardSize.y - size.y }
    }
    
    func includes(_ tx:Int, _ ty:Int) -> Bool {
        let pos2 = lowerRightCorner()
        return tx >= pos.x && tx < pos2.x && ty >= pos.y && ty < pos2.y
    }
    
    mutating func touched(_ pt:CGPoint) -> Bool {
        let npos = calcLogicalPosition(pt)
        return includes(npos.x,npos.y)
    }
    
    mutating func overlapsOtherIfMoved(_ other:Group, _ dx:Int, _ dy:Int) -> Bool {
        let oldPos = pos
        var overlap = false
        
        move(dx,dy)
        
        for x in 0 ..< size.x {
            for y in 0 ..< size.y {
                if other.includes(pos.x + x, pos.y + y) {
                    overlap = true
                    break
                }
            }
        }
        
        pos = oldPos
        return overlap
    }
}

//MARK:-

struct Board {
    var group:[Group] = []
    var xScore = Array(repeating:Int(), count:20)
    var yScore = Array(repeating:Int(), count:20)
    
    func randomIndex(_ max:Int) -> Int { return Int(arc4random()) % max }
    
    mutating func newGame() {
        func randomGroup() {
            let sz = Position(1 + randomIndex(4),1 + randomIndex(4))
            let value = 1 + randomIndex(5)
            group.append(Group(Position(0,0),sz,value))
            let index = group.count - 1
            var attempts:Int =  0
            
            while(true) {
                group[index].pos.x = randomIndex(boardSize.x - group[index].size.x + 1)
                group[index].pos.y = randomIndex(boardSize.y - group[index].size.y + 1)
                
                var overlap = false
                for i in 0 ..< group.count {
                    if i == index { continue }
                    if group[index].overlapsOtherIfMoved(group[i],0,0) {
                        overlap = true
                        break
                    }
                }
                
                if !overlap { break }
                
                attempts += 1
                if attempts > 1000 {
                    group.remove(at: index)
                    break
                }
            }
        }
        
        group.removeAll()
        for _ in 0 ..< gCount[level] { randomGroup() }
        updateScores()
    }
    
    mutating func scrambleGroupPositions() {
        for _ in 0 ..< 1000 {
            let index = randomIndex(group.count)
            let oldPos = group[index].pos
            
            group[index].pos.offset(randomIndex(3) - 1, randomIndex(3) - 1)
            if !isOnBoardPosition(group[index].pos.x,group[index].pos.y) ||
                !isOnBoardPosition(group[index].pos.x + group[index].size.x - 1, group[index].pos.y + group[index].size.y - 1) {
                group[index].pos = oldPos
                continue
            }
            
            var overlap = false
            for i in 0 ..< group.count {
                if i == index { continue }
                if group[index].overlapsOtherIfMoved(group[i],0,0) {
                    overlap = true
                    break
                }
            }
            
            if overlap { group[index].pos = oldPos }
        }
        
        updateScores()
    }
    
    mutating func moveAllToURCorner() {
        let index = randomIndex(group.count)
        let oldPos = group[index].pos
        
        func move(_ dx:Int, _ dy:Int) {
            let index = randomIndex(group.count)
            let oldPos = group[index].pos
            
            group[index].pos.offset(dx,dy)
            
            if !isOnBoardPosition(group[index].pos.x,group[index].pos.y) ||
                !isOnBoardPosition(group[index].pos.x + group[index].size.x - 1, group[index].pos.y + group[index].size.y - 1) {
                group[index].pos = oldPos
                return
            }
            
            for i in 0 ..< group.count {
                if i == index { continue }
                if group[index].overlapsOtherIfMoved(group[i],0,0) {
                    group[index].pos = oldPos
                    return
                }
            }
        }
        
        for _ in 0 ..< 1000 {
            move(1,0)
            move(0,-1)
        }
        
        updateScores()
    }
    
    mutating func updateScores() {
        for x in 0 ..< boardSize.x {
            xScore[x] = 0
            var y = 0
            while(true) {
                for g in group {
                    if g.includes(x,y) { xScore[x] += g.value }
                }
                
                y += 1
                if !isOnBoardPosition(x,y) { break }
            }
        }
        
        for y in 0 ..< boardSize.y {
            yScore[y] = 0
            var x = 0
            while(true) {
                for g in group {
                    if g.includes(x,y) { yScore[y] += g.value }
                }
                
                x += 1
                if !isOnBoardPosition(x,y) { break }
            }
        }
    }
    
    func drawScores() {
        func drawScoreIcon(_ pt:CGPoint, _ diff:Int) {
            var rect = CGRect()
            let inset:CGFloat = 5
            rect.origin = pt
            rect.origin.x += inset/2
            rect.size = CGSize(width:SIZE-inset, height:SIZE-inset)
            
            if diff == 0 { okayScore.draw(in:rect) } else
                if diff < 0 { lowScore.draw(in:rect) } else
                { highScore.draw(in:rect) }
        }
        
        for x in 0 ..< boardSize.x {
            let diff = xScore[x] - targetBoard.xScore[x]
            var pt = screenCoordinate(x,0)
            pt.offset(0,-(CELLSIZE + 10))
            drawScoreIcon(pt,diff)
            
            if diff != 0 {
                pt.offset(CELLSIZE/2,-18)
                drawCenteredText(pt,.white,16,diff.description)
            }
        }
        
        for y in 0 ..< boardSize.y {
            let diff = yScore[y] - targetBoard.yScore[y]
            var pt = screenCoordinate(0,y)
            pt.offset(-(CELLSIZE + 10),0)
            drawScoreIcon(pt,diff)
            
            if diff != 0 {
                pt.offset(-18,12)
                drawCenteredText(pt,.white,16,diff.description)
            }
        }
    }
    
    func draw() {
        for g in group { g.draw() }
        drawScores()
    }
    
    //MARK:- Touch
    
    var index:Int = NONE
    var pt = CGPoint()
    var touchOffset = Position()
    
    mutating func touchBegan(_ npt:CGPoint) {
        index = NONE
        for i in 0 ..< group.count {
            if group[i].touched(npt) {
                index = i
                pt = npt
                touchOffset = group[i].pos
                touchOffset -= calcLogicalPosition(npt)
                break
            }
        }
    }
    
    mutating func touchMoved(_ npt:CGPoint) {
        if index == NONE { return }
        
        var npos = calcLogicalPosition(npt)
        npos += touchOffset
        
        let dx = npos.x - group[index].pos.x
        let dy = npos.y - group[index].pos.y
        if dx == 0 && dy == 0 { return }
        
        for i in 0 ..< group.count {
            if i == index { continue }
            if group[index].overlapsOtherIfMoved(group[i],dx,dy) { return }
        }
        
        group[index].move(dx,dy)
        pt = npt
        updateScores()
        
        vc.gameView.setNeedsDisplay()
    }
}

//MARK:-

var board = Board()
var targetBoard = Board()

class Game {
    init() {
        newGame()
        lowScore = UIImage(named: "lowScore.png")!
        highScore = UIImage(named: "highScore.png")!
        okayScore = UIImage(named: "okayScore.png")!
    }
    
    func levelChange(_ nLevel:Int) {
        level = nLevel
        newGame()
    }
    
    func newGame() {
        boardSize = bdSize[level]
        SX = (vc.gameView.bounds.width - CGFloat(boardSize.x) * SIZE) / 2
        SY = (vc.gameView.bounds.height - CGFloat(boardSize.y) * SIZE) / 2
        
        targetBoard.newGame()
        board = targetBoard
        board.scrambleGroupPositions()
        
        board.moveAllToURCorner()
        
        vc.gameView.setNeedsDisplay()
    }
    
    func showAnswer() {
        board = targetBoard
        board.updateScores()
        
        vc.gameView.setNeedsDisplay()
    }
    
    func draw() {
        UIColor(red:0.15, green:0.15, blue:0.15, alpha:1).set()
        UIBezierPath(rect:vc.gameView.bounds).fill()
        
        UIColor.gray.setFill()
        for x in 0 ..< boardSize.x {
            for y in 0 ..< boardSize.y {
                UIBezierPath(rect:cellRect(x,y)).fill()
            }
        }
        
        board.draw()
    }
    
    func touchBegan(_ pt:CGPoint) { board.touchBegan(pt) }
    func touchMoved(_ pt:CGPoint) { board.touchMoved(pt) }
}

//MARK:-

func drawBevelledRect(_ rect:CGRect, _ color:UIColor) {
    struct CGF {
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        
        init(_ rr:CGFloat, _ gg:CGFloat, _ bb:CGFloat) { r = rr; g = gg; b = bb }
        init(_ color:UIColor) {  color.getRed(&r, green: &g, blue: &b, alpha: &a) }
        
        func color() -> UIColor { return  UIColor(red:r, green:g, blue:b, alpha:1) }
        
        mutating func adjust(_ amt:CGFloat) {
            if r != 0 { r += amt }
            if g != 0 { g += amt }
            if b != 0 { b += amt }
        }
    }
    
    var x1 = rect.origin.x
    var y1 = rect.origin.y
    var x2 = x1 + rect.size.width
    var y2 = y1 + rect.size.height
    var e1 = CGF(color)
    var e2 = CGF(color)
    let path = UIBezierPath()
    let width:Int = 12
    let adjustAmt = CGFloat(0.05)
    let totalAdjust = CGFloat(width) * adjustAmt
    
    e1.adjust(+totalAdjust)
    e2.adjust(-totalAdjust)
    
    color.set()
    UIBezierPath(rect:rect).fill()
    
    for _ in 0 ..< width {
        e1.adjust(-adjustAmt)
        e2.adjust(+adjustAmt)
        
        e1.color().set()
        path.removeAllPoints()
        path.move(to: CGPoint(x:x1, y:y2))
        path.addLine(to: CGPoint(x:x1, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y1))
        path.stroke()
        
        e2.color().set()
        path.removeAllPoints()
        path.move(to: CGPoint(x:x2, y:y1))
        path.addLine(to: CGPoint(x:x2, y:y2))
        path.addLine(to: CGPoint(x:x1, y:y2))
        path.stroke()
        
        x1 += 1
        x2 -= 1
        y1 += 1
        y2 -= 1
    }
}


