/*
 * Copyright © 2017 Teclib. All rights reserved.
 *
 * InventoryController.swift is part of FlyveMDMInventoryAgent
 *
 * FlyveMDMInventoryAgent is a subproject of Flyve MDM. Flyve MDM is a mobile
 * device management software.
 *
 * FlyveMDMInventoryAgent is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or (at your option) any later version.
 *
 * FlyveMDMInventoryAgent is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * ------------------------------------------------------------------------------
 * @author    Hector Rondon
 * @date      04/10/17
 * @copyright Copyright © 2017 Teclib. All rights reserved.
 * @license   LGPLv3 https://www.gnu.org/licenses/lgpl-3.0.html
 * @link      https://github.com/flyve-mdm/flyve-mdm-ios-inventory-agent.git
 * @link      https://flyve-mdm.com
 * ------------------------------------------------------------------------------
 */

import UIKit
import FlyveMDMInventory

class InventoryController: UIViewController {
    
    // MARK: Properties
    
    let cellId = "InventoryCell"
    var inventory = [AnyObject]()
    
    /// This property contains the configurations for the table view
    lazy var inventoryTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView()
        table.backgroundColor = UIColor.init(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        table.isScrollEnabled = true
        table.rowHeight = UITableViewAutomaticDimension
        table.estimatedRowHeight = 100
        table.register(UITableViewCell.self, forCellReuseIdentifier: self.cellId)
        return table
    }()
    
    // MARK: Methods
    
    /// Load the customized view that the controller manages
    override func loadView() {
        super.loadView()
        
        setupViews()
        addConstraints()
        
        loadInventory { error in
            if error == nil {
                self.inventoryTableView.reloadData()
            }
        }
    }
    
    /// Set up the views of the controller
    func setupViews() {
        view.backgroundColor = .white
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo"))
        view.addSubview(inventoryTableView)
    }
    
    /// Add the constraints to the views of the controller
    func addConstraints() {
        inventoryTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        inventoryTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        inventoryTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        inventoryTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func loadInventory(completion: @escaping (Error?) -> Void) {
        
        let queue = DispatchQueue(label: "loadInventory")

        // submit a task to the queue for background execution
        queue.async {
            let inventoryTask = InventoryTask()
            inventoryTask.execute("FusionInventory-Agent-iOS_v1.0", json: true) { result in
                
                if let data = result.data(using: .utf8) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] ?? [String: AnyObject]()
                        
                        if let dictionary: [String: AnyObject] = json["request"]?["content"] as? [String : AnyObject] {
                            
                            for item in dictionary {
                                for object in (item.value as? [AnyObject] ?? [AnyObject]()) {
                                    
                                    var dictionarySection = [String: AnyObject]()
                                    dictionarySection[item.key] = object
                                    self.inventory.insert(dictionarySection as AnyObject, at: self.inventory.count)
                                }
                            }
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            completion(error)
                        }
                    }
                }
            }
        }
    }
}

extension InventoryController: UITableViewDataSource {
    
    /**
     override `numberOfSections` from super class, get number of sections
     
     - return: number of sections
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return inventory.count
    }
    
    /**
     override `numberOfRowsInSection` from super class, get number of row in sections
     
     - return: number of row in sections
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let dic = inventory[section] as? [String: AnyObject] ?? [String: AnyObject]()
        let key = Array(dic.keys)[0]
        let object = dic[key] as? [String: String] ?? [String: String]()

        return object.count
    }
    
    /**
     override `cellForRowAt` from super class, Asks the data source for a cell to insert in a particular location of the table view
     
     - return: `UITableViewCell`
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellId)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        let dic = inventory[indexPath.section] as? [String: AnyObject] ?? [String: AnyObject]()
        let index = Array(dic.keys)[0]
        let object = dic[index] as? [String: String] ?? [String: String]()
        let key = Array(object.keys)[indexPath.row]
        let value = Array(object.values)[indexPath.row]

        cell.textLabel?.text = key.lowercased()
        cell.detailTextLabel?.text = value
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .darkGray
        
        return cell
    }
    
    /**
     override `cellForRowAt` from super class, Asks the data source for a cell to insert in a particular location of the table view
     
     - return: `UITableViewCell`
     */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dic = inventory[section] as? [String: AnyObject] ?? [String: AnyObject]()
        let key = Array(dic.keys)[0]
        return key.uppercased()
    }
}

extension InventoryController: UITableViewDelegate {
    /**
     override `willDisplayHeaderView` from super class
     */
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let headerView = view as? UITableViewHeaderFooterView, let textLabel = headerView.textLabel {
            headerView.backgroundView?.backgroundColor = UIColor.init(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
            textLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.bold)
            textLabel.textColor = UIColor.gray
        }
    }
}