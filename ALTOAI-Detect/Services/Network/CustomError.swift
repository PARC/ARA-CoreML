//
//  CustomError.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 27.07.2021.
//

import Foundation
enum CustomError: String, Error {
    case authorize = "Unable to authenticate user. An error occurred during authorization, please check your connection and try again."
    case unavailableServer = "Server is unavailable"
    case cantGetProjects = "Can't get projects"
}
