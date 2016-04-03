//
//  SecondViewController.swift
//  smarticle
//
//  Created by Alexander Lin on 3/13/16.
//  Copyright © 2016 Alexander Lin. All rights reserved.
//

import UIKit

import Alamofire

class SecondViewController: UIViewController {
    
    @IBOutlet weak var query: UITextField!
    @IBOutlet weak var searchButton: UIButton!

    var buttons = [UIButton]()
    var urls = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func querySearch(sender: UIButton) {
        
        // clear previous buttons
        for button in buttons
        {
            button.removeFromSuperview()
        }
        urls.removeAll()
       
        let searchTerm = self.query.text!.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "+")
        
        // get articles from API
        Alamofire.request(.GET, "https://access.alchemyapi.com/calls/data/GetNews?apikey=7a8f85783221b5bbf85481d3c11e8e587d15d104&return=enriched.url.title,enriched.url.url&start=1458000000&end=1458687600&q.enriched.url.cleanedTitle=" + searchTerm + "&count=8&outputMode=json").responseJSON{
            (response) -> Void in
        
            if let JSON = response.result.value {
                
                if let data = JSON["result"]!!["docs"]
                {
                    if data != nil {
                        let x :CGFloat = 20.0
                        var y :CGFloat = 100.0
                        var button : UIButton
                        for i in 0..<8
                        {
                            // display link as button
                            if data![i] != nil {
                                button = UIButton(type: UIButtonType.System) as UIButton
                                button.frame = CGRectMake(x, y, UIScreen.mainScreen().bounds.width - 40.0, 50.0)
                                button.setTitle(String(data![i]["source"]!!["enriched"]!!["url"]!!["title"]!!), forState: UIControlState.Normal)
                                button.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchUpInside)
                                button.titleLabel!.lineBreakMode = NSLineBreakMode.ByTruncatingTail
                                button.tag = i
                                self.view.addSubview(button)
                                self.buttons.append(button)
                                self.urls.append(String(data![i]["source"]!!["enriched"]!!["url"]!!["url"]!!))
                                y = y + 50
                            }
                        }
                        
                    }
                    else {
                        // invalid query search
                        let alert = UIAlertController(title: "Cannot Find Articles", message: "Please enter in a different search term.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }

                    
                }
            
                
            }
    

        
        
        }
    }
    
    func buttonAction(sender:UIButton!)
    {
        // go to first tab and render appropriate URL
        let firstTab = tabBarController?.viewControllers?[0] as? FirstViewController
        firstTab!.setURLText(urls[sender.tag])
        tabBarController?.selectedIndex = 0
        
    }


}

