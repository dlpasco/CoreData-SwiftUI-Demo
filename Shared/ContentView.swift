//
//  ContentView.swift
//  Shared
//
//  Created by Daniel Pasco on 7/7/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel:ViewModel

    init () {
        viewModel = ViewModel()
    }
    
    func addCounter() {
        print("Adding a counter")
        viewModel.addCounter()
    }

    func incrementCounts() {
        print("incrementing counts")
        viewModel.incrementCounts()
    }

    var body: some View {
        NavigationView {
            VStack {
                List(viewModel.counters, id: \.objectID) { (counter) in
                    CounterRow(counter: counter)
                }
                .navigationTitle("Counters")
                .toolbar {
                    Button("Add", action:addCounter)
                    Spacer()
                    Button("Increment counts", action:incrementCounts)
                }
            }
        }
    }
}

struct CounterRow: View {
    @ObservedObject var counter:Counter
    
    var body: some View {
        Text("\(counter.name!): \(counter.count)").padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
