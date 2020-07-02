import SwiftUI

struct GameView: View {
    
    @FetchRequest(
        entity: Game.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Game.score, ascending: true)
    ]) var games: FetchedResults<Game>
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var gameData: GameData
    @State private var showingAlert = false
    
    func handleInput() {
        guard gameData.inputValue.count == 4 else {
            return
        }
        
        if checkIsMatch() {
            self.gameData.score += 1
        } else {
            self.gameData.score -= 1
        }
        
        self.gameData.inputValue = ""
        
        updateNumberValue()
        
        if self.gameData.timer == nil {
            self.gameData.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { time in
                if self.gameData.seconds == 0 {
                    self.gameData.seconds = 60
                    self.saveContext()
                    self.finishGame()
                } else if self.gameData.seconds <= 60 {
                    self.gameData.seconds -= 1
                }
            }
        }
    }
    
    func finishGame() {
        
        let newGame = Game(context: managedObjectContext)
        
        newGame.score = Int32(self.gameData.score)
        
        showAlert()
    }
    
    func showAlert() {
        self.showingAlert = true
    }
    
    func resetGame() {
        self.gameData.seconds = 0
    }
    
    func checkIsMatch() -> Bool {
        let inputArray = Array(self.gameData.inputValue)
        let numArray = Array(self.gameData.numberValue)
        
        for (index, char) in inputArray.enumerated() {
            var inputValue = char.wholeNumberValue ?? 0
            let numValue = numArray[index].wholeNumberValue ?? 0
            
            if inputValue == 0 {
                inputValue = 10
            }
            
            if  inputValue - 1 != numValue {
                return false
            }
        }
        return true
    }
    
    func updateNumberValue() {
        self.gameData.numberValue = String.randomNumber(length: 4)
    }
    
    func saveContext() {
      do {
        try managedObjectContext.save()
      } catch {
        print("Error saving managed object context: \(error)")
      }
    }
    
    var body: some View {
        
        let textInputBinding = Binding<String>(get: {
            self.gameData.inputValue
        }, set: {
            self.gameData.inputValue = $0
            self.handleInput()
        })
        
        return ZStack {
            Image("background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Image("score")
                        .padding()
                        .overlay(Text(String(self.gameData.score))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .font(.system(size: 20)).multilineTextAlignment(.leading)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)))
                    Spacer()
                    Image("time")
                        .padding()
                        .overlay(Text(":\(self.gameData.seconds)")
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .font(.system(size: 20)).multilineTextAlignment(.leading)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30)))
                }
                Image("number")
                    .padding()
                    .overlay(Text(self.gameData.numberValue)
                        .foregroundColor(Color(0x874F21))
                        .font(.system(size: 60, weight: .heavy)).multilineTextAlignment(.leading))
                
                Image("input")
                    .overlay(TextField("", text: textInputBinding)
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                        .font(.system(size: 60, weight: .heavy, design: .default))
                        .multilineTextAlignment(.center)).keyboardType(.numberPad)

                    
                Spacer()
            }
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text("Game Over"),
                  message: Text("You Scored \(self.gameData.score) Points!"),
                  dismissButton: .default(Text("Start New Game"), action: {

                    self.gameData.reset()
                }))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
        .environmentObject(GameData())
    }
}

extension Color {
    init(_ hex: UInt32, opacity:Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension String {
    static func randomNumber(length: Int) -> String {
        var result = ""

        for _ in 0..<length {
            let digit = Int.random(in: 0...9)
            result += "\(digit)"
        }

        return result
    }
}



