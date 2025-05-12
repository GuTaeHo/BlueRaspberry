//
//  FormatUtil.swift
//  BlueRaspberry
//
//  Created by 구태호 on 5/12/25.
//

import Foundation
import Yams

struct FormatUtil {
    static func loadYAML(path: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: path)
        let yamlString = try String(contentsOf: url, encoding: .utf8)
        
        if let yaml = try Yams.load(yaml: yamlString) as? [String: Any] {
            return yaml
        }
        
        return [:]
    }
    
    static func loadYAMLFromBundle(filename: String) throws -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "yaml") else {
            print("파일을 찾을 수 없습니다.")
            return nil
        }

        let yamlString = try String(contentsOf: url, encoding: .utf8)
        if let yaml = try Yams.load(yaml: yamlString) as? [String: Any] {
            return yaml
        }
        return nil
    }
}
