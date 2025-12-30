//
//  Category.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import Foundation
import SwiftUI

enum ItemCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy & Eggs"
    case meat = "Meat & Seafood"
    case bakery = "Bakery"
    case beverages = "Beverages"
    case pantry = "Pantry & Dry Goods"
    case frozen = "Frozen Foods"
    case snacks = "Snacks & Candy"
    case household = "Household & Cleaning"
    case personalCare = "Personal Care"
    case health = "Health & Pharmacy"
    case baby = "Baby & Kids"
    case pet = "Pet Supplies"
    case deli = "Deli & Prepared Foods"
    case alcohol = "Alcohol & Wine"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "cube.fill"
        case .meat: return "scalemass.fill"
        case .bakery: return "birthday.cake.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .pantry: return "basket.fill"
        case .frozen: return "snowflake"
        case .snacks: return "gift.fill"
        case .household: return "house.fill"
        case .personalCare: return "face.smiling.fill"
        case .health: return "cross.case.fill"
        case .baby: return "figure.and.child.holdinghands"
        case .pet: return "pawprint.fill"
        case .deli: return "fork.knife"
        case .alcohol: return "wineglass.fill"
        case .other: return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .produce: return .green
        case .dairy: return .blue
        case .meat: return .red
        case .bakery: return .orange
        case .beverages: return .cyan
        case .pantry: return .brown
        case .frozen: return .indigo
        case .snacks: return .pink
        case .household: return .purple
        case .personalCare: return .mint
        case .health: return .red
        case .baby: return .yellow
        case .pet: return .orange
        case .deli: return .orange
        case .alcohol: return .purple
        case .other: return .gray
        }
    }
}
