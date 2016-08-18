//
//  ViewController.swift
//  url_jpg
//
//  Created by Joohan Oh on 2016-07-17.
//  Copyright © 2016 Joohan Oh. All rights reserved.
//

import UIKit
import SDWebImage

class ViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var myCollectionView: UICollectionView!
    // List of image URLS
    var images:[String] = []
    var manager: SDWebImageManager = SDWebImageManager.sharedManager()
    let myActivityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        inputText.delegate = self
        
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .Gray
        self.view.addSubview(myActivityIndicator)
        myActivityIndicator.startAnimating()
    }
    
    //Load images everytime your view is about to appear 
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(textField: UITextField) {
        inputText.text = textField.text
    }
    
    // MARK: ButtonGoPressed, will send the URL to backend if a valid URL, a pop-up window otherwise
    @IBAction func buttonGoPressed(sender: UIButton) {
        if !(canOpenURL(inputText.text)) {
            let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("sbPopUpID") as! PopUpViewController
            self.addChildViewController(popOverVC)
            popOverVC.view.frame = self.view.frame
            self.view.addSubview(popOverVC.view)
            popOverVC.didMoveToParentViewController(self)
        }
        else {
            loadImages()
            self.myActivityIndicator.stopAnimating()
        }
    }
    
    // MARK: helper function for buttonGoPressed, determines if a input URL is valid or not
    func canOpenURL(string: String?) -> Bool {
        print("canOpenURL called")
        guard let urlString = string else {return false}
        guard let url = NSURL(string: urlString) else {return false}
        if !UIApplication.sharedApplication().canOpenURL(url) {return false}
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return predicate.evaluateWithObject(string)
    }
    
    //MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let myCell:MyCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("myCell", forIndexPath: indexPath) as! MyCollectionViewCell
        
        let remoteImageUrlString = images[indexPath.row]
        let imageUrl = NSURL(string:remoteImageUrlString)
        
        print(indexPath.row)
        
        manager.downloadImageWithURL(imageUrl, options: [], progress: {(receivedSize: Int, expectedSize: Int) -> Void in
            // progression tracking code
            }, completed: {(image: UIImage!, error: NSError!, cacheType: SDImageCacheType, finished: Bool, imageURL: NSURL!) -> Void in
                if image != nil {
                    // do something with image
                    let myBlock: SDWebImageCompletionBlock! = {(image:UIImage!, error: NSError!, cacheType: SDImageCacheType!, imageURL: NSURL!) -> Void in
                        print("Image with url \(imageURL.absoluteString) is loaded")
                    }
                    myCell.imageView.sd_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "placeHolder"), options: SDWebImageOptions.ProgressiveDownload, completed: myBlock)
                }
                else {
                    myCell.imageView.image = UIImage(named: "sorry-image-not-available")
                }
        })
        return myCell
    }
    
    enum Error : ErrorType {
        case NoImagesError
    }
    
    func divide() throws {
        if images.isEmpty {
            throw Error.NoImagesError
        }
        return
    }
    // MARK: Responsible for loading images from the server side
    func loadImages() {
        let myURL = NSURL(string: "http://localhost:8888/convertUrlToJson.php")
        let request = NSMutableURLRequest(URL: myURL!)
        request.HTTPMethod = "POST"
        let postString = "data=" + inputText.text!
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            if error != nil {
                let myAlert = UIAlertController(title:"Alert", message:error.debugDescription, preferredStyle:UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction (title:"Ok", style: UIAlertActionStyle.Default, handler:  nil)
                myAlert.addAction(okAction)
                self.presentViewController(myAlert, animated: true, completion: nil)
                print("error=\(error)")
                return
            }
            // You can print out response object
            print("response = \(response)")
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString=\(responseString)")
            //Let's convert response sent from a server side script to a NSArray
            do {
                let myJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSArray
                if let parseJSON = myJSON {
                    self.images = parseJSON as! [String]
                }
                do {
                    _ = try self.divide()
                } catch {
                    self.alert()
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.myCollectionView.reloadData()
                });
            }
            catch {
                print(error)
            }
        }
        task.resume()
    }

    func alert() {
        let myAlert = UIAlertController(title:"Alert", message: "No Images Available at this site", preferredStyle:UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction (title:"Ok", style: UIAlertActionStyle.Default, handler:  nil)
        myAlert.addAction(okAction)
        self.presentViewController(myAlert, animated: true, completion: nil)
    }
}