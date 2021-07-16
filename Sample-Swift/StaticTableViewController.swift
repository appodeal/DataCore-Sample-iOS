//
//  StaticTableViewController.swift
//  Sample-Swift
//
//  Created by Stas Kochkin on 01.06.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation
import UIKit


struct Section {
    var header: String
    var rows: [Row]
}


struct Row {
    var cell: (IndexPath) -> UITableViewCell
    var select: (() -> ())?
    
    init(
        cell: @escaping (IndexPath) -> UITableViewCell,
        select: (() -> ())? = nil
    ) {
        self.cell = cell
        self.select = select
    }
}


class StaticTableViewController: UITableViewController {
    var sections: [Section] = []

    init() {
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].rows[indexPath.row].cell(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].select?()
    }
}
