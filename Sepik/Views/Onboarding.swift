//
//  Onboarding.swift
//  Sepik
//
//  Created by Asad on 12/06/25.
//

import SwiftUI

struct Onboarding: View {
    @Binding var navigationPath: NavigationPath
    @State var index = 0
    let images = ["onboardingImage", "onboardingImage", "onboardingImage"]
    let headings = [
        ["Elevate", "your public speaking performance"],
        ["Elevate", "your public speaking performance"],
        ["Elevate", "your public speaking performance"]
    ]
    
    let texts = [
        "Observe the detailed analysis of your public speaking performance.",
        "Observe the detailed analysis of your public speaking performance.",
        "Observe the detailed analysis of your public speaking performance."
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack{
                // Background
                VStack{
                    Color("AccentPrimary").frame(width: .infinity, height: .infinity)
                    Color("AccentPrimary").frame(width: .infinity, height: 5)
                    Color("AccentColor").frame(width: .infinity, height: 20)
                    Color("AccentColor")
                }.ignoresSafeArea(.all)
                
                // Foreground
                VStack{
                    TabView(selection: $index) {
                        ForEach(0..<images.count) { i in
                            VStack{
                                
                                Image(self.images[i])
                                Group{
                                    Text(self.headings[i][0] + " ")
                                        .font(.system(size: 34, weight: .semibold, design: .default))
                                        .foregroundColor(Color("AccentSecondary"))
                                    +
                                    Text(self.headings[i][1])
                                        .font(.system(size: 34, weight: .semibold, design: .default))
                                        .foregroundColor(Color("AccentPrimary"))
                                }
                                .padding(.vertical, 8)
                                Text(self.texts[i])
                            }
                        }
                    }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    Button(action: {
                        
                    }) {
                        Text("Get Started!")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color("AccentPrimary"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 80)
            }
        }
    }
}
