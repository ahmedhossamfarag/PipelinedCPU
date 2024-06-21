class Signal : CustomStringConvertible {
    let read: () -> Int

    var description: String { return "\(read())" }

    init(read: @escaping() -> Int){
        self.read = read
    }

    subscript(start: Int, end: Int) -> Signal {
      get {
        func getRange(_ start: Int, _ end: Int) -> Int {
            let data = self.read()
            let select = (1 << (end - start + 1)) - 1
            return (data >> start) & select
        }
        return Signal(read: {return getRange(start, end)})
      }
   }

   subscript(indx: Int) -> Signal{
    get{
        func getAt(_ indx: Int) -> Int{
            let data = self.read()
            return (data >> indx) & 1
        }
        return Signal(read: {return getAt(indx)})
    }
   }

}

func connect(_ sig1: Signal?, _ sig2: inout Signal?) {
    sig2 = sig1
}

func connect(_ sig1: Int, _ sig2: inout Signal?) {
    sig2 = Signal(read: {return sig1})
}



protocol CLK_Listener {
    func update()
    func propagate()  
}

class CLK{
    private var listeners: [CLK_Listener] = []

    func addListener(listener: CLK_Listener){
        listeners.append(listener)
    }

    func performUpdate(){
        for item in listeners {
            item.update()
        }
    }

    func performPropagate(){
        for item in listeners {
            item.propagate()
        }
    }

    func performCycle(){
        performUpdate()
        performPropagate()
    }
}
