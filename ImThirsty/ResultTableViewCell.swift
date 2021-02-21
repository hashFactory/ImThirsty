//
//  ResultTableViewCell.swift
//  ImThirsty
//
//  Created by Tristan Charpentier on 22/09/2019.
//  Copyright © 2019 Tristan Charpentier. All rights reserved.
//

import UIKit

class ResultTableViewCell: UITableViewCell {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceDirection: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
