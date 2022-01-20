import Foundation
import Firebase

class Post {
    var postID:String
    var user:User
    var text:String
    var picture:String
    var songID: String
    var createdAt:Date!
    var video:String
    var likes: Int!
    var didLike = false
    var didComment = false
    var isVerified = false
    var comments: Int!
    var postURL: String
    
    
    init(postID:String, user:User, dictionary:[String:Any]) {
        self.postID = dictionary["postID"] as? String ?? ""
        self.user = user
        
        self.text = dictionary["text"] as? String ?? ""
        self.likes = dictionary["likes"] as? Int ?? 0
        self.comments = dictionary["comments"] as? Int ?? 0
        self.picture = dictionary["picture"] as? String ?? ""
        self.video = dictionary["video"] as? String ?? ""
        self.songID = dictionary["audio"] as? String ?? ""
        self.postURL = dictionary["url"] as? String ?? ""

        if let createdAt = dictionary["timestampt"] as? Double {
                self.createdAt = Date(timeIntervalSince1970: createdAt)
        }
    }
}
