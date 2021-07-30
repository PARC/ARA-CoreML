//
//  ExperimentRun.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 29.07.2021.
//

import Foundation

struct ExperimentRun {
    let id : String
    let status : String
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
    }
}

extension ExperimentRun: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(String.self, forKey: .status)
    }
}
