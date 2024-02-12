//
//  ContentView.swift
//  MyNewSchoolBimba
//
//  Created by Giacomo on 05/02/24.
//

import SwiftUI
import AVFAudio

struct VerticalAccessoryGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            configuration.maximumValueLabel
            GeometryReader { proxy in
                Capsule()
                    .fill(.tint)
                    .rotationEffect(.degrees(180))
                Circle()
                    .stroke(.background, style: StrokeStyle(lineWidth: 3))
                    .position(x: 12, y: proxy.size.height * (1 - configuration.value))
            }
            .frame(width: 24)
            .clipped()
            configuration.minimumValueLabel
        }
    }
}

struct ContentView: View {
    @StateObject var session: MultiPeerAdvertiser
    @State private var puntiAttuali = 0
    @State private var audioPlayer: AVAudioPlayer!
    let puntiLeggenda = 1_000_000
    let path = URL.documentsDirectory.appending(component: "MyNewSchoolBimba")
    
    var body: some View {
        VStack {
            Text(session.paired ? "CONNESSO" : "NON CONNESSO")
                .onChange(of: session.paired) {
                    if session.paired {
                        session.sendData(data: String(puntiAttuali))
                    }
                }
            Image("mg464295")
                .resizable()
                .scaledToFit()
            
            Spacer()
            
            Text("Vuoi entrare anche tu nel Wall of Celebrities?")
                .font(.largeTitle)
                .padding(.bottom)
                .multilineTextAlignment(.center)
            
            HStack {
                Gauge(value: Double(puntiAttuali + session.receivedPoints), in: Double(-puntiLeggenda)...Double(puntiLeggenda)) {
                } currentValueLabel: {
                } minimumValueLabel: {
                    Text("-\(puntiLeggenda)")
                } maximumValueLabel: {
                    Text("\(puntiLeggenda)")
                }
                .gaugeStyle(VerticalAccessoryGaugeStyle())
                .tint(Gradient(colors: [.red, .green]))
                .font(.title2)
                
                Text("Hai \(puntiAttuali + session.receivedPoints) punti...\n\nTi mancano ancora \(puntiLeggenda - puntiAttuali - session.receivedPoints) punti!")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .onAppear {
                        puntiAttuali = loadData()
                    }
                    .onChange(of: puntiAttuali + session.receivedPoints) {
                        saveData(value: puntiAttuali + session.receivedPoints)
                        session.sendData(data: String(puntiAttuali + session.receivedPoints))
                    }
            }
        }
        .padding()
        .alert("Hai ricevuto una nuova sfida!", isPresented: $session.recvdInvite) {
            Button("👍 Accetta!") {
                if (session.invitationHandler != nil) {
                    session.invitationHandler!(true, session.session)
                }
            }
            Button("👎 Rifiuta!") {
                if (session.invitationHandler != nil) {
                    session.invitationHandler!(false, nil)
                }
            }
        }
    }
    
    func loadData() -> Int {
        guard let data = try? Data(contentsOf: path) else { return 0 }
        do {
            let value = try JSONDecoder().decode(Int.self, from: data)
            return value
        } catch {
            print("🤬 ERROR: Could not load data \(error.localizedDescription)")
            return 0
        }
    }
    
    func saveData(value: Int) {
        let data = try? JSONEncoder().encode(value) // try? significa che se c'è un errore data = nil
        do {
            try data?.write(to: path)
        } catch {
            print("🤬 ERROR: Could not save data \(error.localizedDescription)")
        }
    }
    
    func playSound(soundName: String) {
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("* Could not read file named \(soundName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("ERROR: \(error.localizedDescription) creating AudioPlayer.")
        }
    }
}

#Preview {
    ContentView(session: MultiPeerAdvertiser())
}
