//
//  Experiment.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

struct Experiment {
    let name : String?
    let id : String
    let description : String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case description
    }
}

extension Experiment: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
}
