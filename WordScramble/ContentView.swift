//
//  ContentView.swift
//  WordScramble
//
//  Created by PBB on 2019/10/23.
//  Copyright © 2019 PBB. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter your word", text: $newWord, onCommit: addNewWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()
                
                GeometryReader { largeGeo in
                    List(self.usedWords, id: \.self) { word in
                        GeometryReader { geo in
                            HStack {
                                Image(systemName: "\(word.count).circle")
                                    .foregroundColor(self.calculateColor(listGeo: largeGeo, itemGeo: geo))
                                Text(word)
                                Spacer()
                            }
                            .offset(x: geo.frame(in: .global).minY < 600 ? 0 : (geo.frame(in: .global).minY - 600) * 3, y: 0.0)
                            .accessibilityElement(children: .ignore)
                            .accessibility(label: Text("\(word), \(word.count) letters"))
                            .animation(.default)
                        }
                    }
                }
                
                
                Text("Score for root word \"\(rootWord)\": \(score)")
            }
            .navigationBarTitle(rootWord)
            .navigationBarItems(leading: Button("New Game", action: startGame))
            .onAppear(perform: startGame)
            .alert(isPresented: $showingError) {
                Alert(title: Text(errorTitle), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func calculateColor(listGeo: GeometryProxy, itemGeo: GeometryProxy) -> Color {
        let startPosition = listGeo.frame(in: .global).minY
        let endPosition = listGeo.frame(in: .global).maxY
        let itemPosition = itemGeo.frame(in: .global).minY
        
        let hue = (itemPosition - startPosition) / (endPosition - startPosition)
        
        let color = Color(hue: Double(hue), saturation: 0.7, brightness: 0.8)
        
        return color
    }
    
    func startGame() {
        score = 0
        usedWords = [String]()
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        
        fatalError("Could not load start.txt from bundle.")
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard answer.count > 0 else {
            return
        }
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        guard notRootWord(word: answer) else {
            wordError(title: "Word the same as root word", message: "Come up with other words")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        guard isReal(word: answer) else {
            wordError(title: "Word not possible", message: "That isn't a real word")
            return
        }

        
        usedWords.insert(answer, at: 0)
        score += answer.count
        newWord = ""
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        if word.count < 3 {
            return false
        }
        
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func notRootWord(word: String) -> Bool {
        return word != rootWord
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
