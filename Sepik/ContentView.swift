//
//  ContentView.swift
//  Sepik
//
//  Created by Asad on 12/06/25.
//

import SwiftUI

struct ContentView: View {
    @State var navigationPath = NavigationPath()
    
    var body: some View {
       Onboarding(navigationPath: $navigationPath)
    }
}

#Preview {
    ContentView()
}
