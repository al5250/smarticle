//
//  FirstViewController.swift
//  smarticle
//
//  Created by Alexander Lin on 3/13/16.
//  Copyright © 2016 Alexander Lin. All rights reserved.
//

import UIKit

import Alamofire


class Sentence
{
    var words:String
    
    // initialize sentence with string
    init (newWords:String)
    {
        self.words = newWords
    }
    
    // splits sentence into individual words
    func splitArray() -> [String]
    {
        return self.words.lowercaseString.componentsSeparatedByCharactersInSet(.punctuationCharacterSet()).joinWithSeparator("").componentsSeparatedByString(" ").filter{!$0.isEmpty}
    }
    
    // calculates similarity of two sentences
    class func similarity(sen1:Sentence, sen2:Sentence) -> Float
    {
        var count = 0
        let words1 = Array(Set(sen1.splitArray())) // eliminates duplicates
        let words2 = Array(Set(sen2.splitArray()))
        for word in words1
        {
            if words2.contains(word)
            {
                count++
            }
        }
        return Float(count) / (log(Float(words1.count)) + log(Float(words2.count)))
    }
    
    // calculates matrix of similarities from arrays of sentences
    class func simMatrix (sens:[Sentence]) -> [[Float]]
    {
        var sim = Float(0.0)
        var matrix = [[Float]](count: sens.count, repeatedValue: [Float] (count: sens.count, repeatedValue: 0.0))
        for i in 0..<sens.count
        {
            for j in (i+1)..<sens.count
            {
                sim = Sentence.similarity(sens[i], sen2:sens[j])
                matrix[i][j] = sim
                matrix[j][i] = sim
            }
        }
        return matrix
    }
}

class SenGraph
{
    var vertices:[Sentence]
    var vertexWeights:[Float]
    var edgeWeights:[[Float]]
    var neighborWeights:[Float]
    
    // initializes graph based on array of sentences
    init (sens:[Sentence])
    {
        vertices = sens
        vertexWeights = [Float] (count:sens.count, repeatedValue: Float(1) / Float(sens.count))
        edgeWeights = Sentence.simMatrix(vertices)
        neighborWeights = [Float] (count:sens.count, repeatedValue: 0.0)
        for i in 0..<neighborWeights.count
        {
            neighborWeights[i] = edgeWeights[i].reduce(0, combine:+)
        }
    }
    
    // calculates the differences between two vectors to see if result is within a certain error
    class func imprecise(vect1:[Float], vect2:[Float], precision:Float) -> Bool
    {
        for i in 0..<vect1.count
        {
            if abs(vect1[i] - vect2[i]) > precision
            {
                return true
            }
        }
        return false
    }
    
    // repeatedly calculates vertex weights until there is convergence within a certain precision - similar to PageRank
    func iterRank(d:Float,precision:Float)
    {
        var tempCalc = self.vertexWeights
        var accumulator = Float(0.0)
        repeat
        {
            self.vertexWeights = tempCalc
            for i in 0..<self.vertices.count
            {
                accumulator = 0.0
                for j in 0..<self.vertices.count
                {
                    if i != j && neighborWeights[j] != 0
                    {
                        accumulator += edgeWeights[i][j] / neighborWeights[j] * vertexWeights[j]
                    }
                }
                tempCalc[i] = (1 - d) + d * accumulator
            }
        }
        while SenGraph.imprecise(tempCalc, vect2: self.vertexWeights, precision: precision)
        self.vertexWeights = tempCalc
    }
    
}



class FirstViewController: UIViewController {

    @IBOutlet weak var urlText: UITextField!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var summary: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.summary.text! = ""
      }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setURLText(text : String) {
        self.urlText.text = text
    }
    
    @IBAction func buttonTapped(sender: UIButton) {
        
        // get source text from API
            let url = self.urlText.text!.stringByReplacingOccurrencesOfString(" ", withString: "")
        Alamofire.request(.GET, "https://api.dandelion.eu/datatxt/nex/v1/?lang=en&url=" + url + "&$app_id=4df2a28a&$app_key=9d7bfcd75b40cf957441b278811de28a").responseJSON{
            (response) -> Void in
            
            if let JSON = response.result.value {
                
                if let source = JSON["text"] {
                
                if source != nil {
                    let text = source!.stringByReplacingOccurrencesOfString(".\n", withString: ". ")
                    let separator = text.rangeOfString("\n")
                    let title = text.substringToIndex(separator!.endIndex)
                    
                    // clean source text for processing
                    let article = text.substringFromIndex(separator!.endIndex).stringByReplacingOccurrencesOfString("\n", withString: ". ")
                    var r = [Range<String.Index>]()
                    let t = article.linguisticTagsInRange(
                        article.characters.indices, scheme: NSLinguisticTagSchemeLexicalClass,
                        tokenRanges: &r)
                    var result = [String]()
                    let ixs = t.enumerate().filter {
                        $0.1 == "SentenceTerminator"
                        }.map {r[$0.0].startIndex}
                    var prev = article.startIndex
                    for ix in ixs {
                        let r = prev...ix
                        result.append(
                            article[r].stringByTrimmingCharactersInSet(
                                NSCharacterSet.whitespaceCharacterSet()))
                        prev = ix.advancedBy(1)
                    }
                    
                    // runs machine learning algorithm
                    var arr = [Sentence]()
                    for thing in result
                    {
                        arr.append(Sentence(newWords:thing))
                    }
                    let alex = SenGraph(sens: arr)
                    alex.iterRank(0.85, precision: 0.001)
                    var marker = [Int]()
                    for i in 0..<alex.vertices.count
                    {
                        marker.append(i)
                    }
                    
                    // extract top four sentences
                    let combined = zip(alex.vertexWeights, marker).sort {$0.0 > $1.0}
                    let sortedtop : [Int]
                    if alex.vertices.count >= 4
                    {
                        let top = combined.map {$0.1}[0..<4]
                        sortedtop = top.sort()
                    }
                    else
                    {
                        let top = combined.map {$0.1}
                        sortedtop = top.sort()
                    }
                    
                    // edit text for display on app
                    let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(15)]
                    let boldTitle = NSMutableAttributedString(string:title, attributes:attrs)
                    var summaryString = ""
                    for i in 0..<sortedtop.count
                    {
                        summaryString += "\n- "
                        summaryString += alex.vertices[sortedtop[i]].words
                    }
                    boldTitle.appendAttributedString(NSMutableAttributedString(string: summaryString))
                    self.summary.attributedText = boldTitle
                }
                }
            }
        }

    }

}


