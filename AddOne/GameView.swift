import SwiftUI
import CoreData

struct GameView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var gameData: GameData
    @State private var showingAlert = false
    @State private var showCorrect = false
    @State private var showIncorrect = false
    @State private var showNone = true
    @State private var gameOverTitle = ""
    
    func getHighScore() {
        let sortDescriptors = NSSortDescriptor(keyPath: \Game.score, ascending: false)
        let fetchRequest = NSFetchRequest<Game>(entityName: "Game")
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [sortDescriptors]
        
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            let highScore = result.first?.score ?? 0
            if self.gameData.score > highScore {
                self.gameOverTitle = "New High Score!"
            } else {
                self.gameOverTitle = "Game Over"
            }
        } catch let error as NSError {
            print("Error fetching: \(error), \(error.userInfo)")
        }
    }
    
    func handleInput() {
        guard gameData.inputValue.count == 4 else {
            return
        }
    
        if checkIsMatch() {
            self.gameData.score += 1
            self.showCorrect = true
            self.showIncorrect = false
        } else {
            self.gameData.score -= 1
            self.showIncorrect = true
            self.showCorrect = false
        }
        
        self.gameData.inputValue = ""
        
        updateNumberValue()
        
        if self.gameData.timer == nil {
            self.gameData.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { time in
                self.showNone = false
                if self.gameData.seconds == 0 {
                    self.resetGame()
                    self.getHighScore()
                    self.saveGame()
                    self.finishGame()
                } else if self.gameData.seconds <= 60 {
                    self.gameData.seconds -= 1
                }
            }
        }
    }
    
    func finishGame() {
        self.showingAlert = true
        resetGame()
    }
    
    func saveGame() {
        let newGame = Game(context: self.managedObjectContext)
        newGame.score = Int32(self.gameData.score)
        self.saveContext()
    }
    
    func resetGame() {
        self.gameData.seconds = 60
        self.gameData.timer?.invalidate()
        self.showCorrect = false
        self.showIncorrect = false
        self.showNone = true
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
                    
                    if showNone {
                        EmptyView()
                    }
                    if showCorrect {
                        Image("checkbox")
                    }
                    if showIncorrect {
                        Image("X")
                    }
                    
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

                    
                //Spacer()
                
                Text("Add 1 to each of the digits.\r\nSo, 1357 becomes 2468. \r\n(9 becomes 0)")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()


            }
        }.alert(isPresented: $showingAlert) {
            Alert(title: Text(self.gameOverTitle),
                  message: Text("You Scored \(self.gameData.score) Points!"),
                  dismissButton: .default(Text("Start New Game"), action: {
                    self.gameData.reset()
                }))
        }
    }
}


struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
        .environmentObject(GameData())
    }
}






