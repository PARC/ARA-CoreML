//
//  CustomError.swift
//  ALTOAI-Detect
//
//  Created by Volodymyr Grek on 27.07.2021.
//

import Foundation
enum CustomError: String, Error {
    case authorize = "Unable to authenticate user. An error occurred during authorization, please check your connection and try again."
    case incorrectCredentials = "Unable to authenticate user. An error occurred during authorization, please check your credentials."
    case unavailableServer = "Server is unavailable"
    case cantGetProjects = "Can't get projects"
    case cantGetScenes = "Can't get scenes"
    case cantGetExperiments = "Can't get experiments"
    case cantGetExperimentRuns = "Can't get experiment runs"
    case cantGetModel = "Can't get model"
}
