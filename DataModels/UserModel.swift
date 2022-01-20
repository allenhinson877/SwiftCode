import Foundation
import Firebase

class User {
    
    var fullname: String
    var username: String
    var artistBand: String
    var profileImageURL: String!
    var headerImageURL: String!
    var bio: String!
    let uid: String
    var isFollowed = false
    var stats: UserRelationStats?
    var isVerified: String
    var genre : String
    var location : String
    var igInfo: String
    var unreadNotifications: Int
    var twitterInfo : String
    var spotifyInfo : String
    var soundcloudInfo : String
    var epkURL: String
    var epkPDF: String


    
    var isCurrentUser: Bool { return Auth.auth().currentUser?.uid == uid}
    
    
    init(dictionary:[String:Any]) {
        self.uid = dictionary["uid"] as? String ?? ""
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.artistBand = dictionary["What do you consider yourself?"] as? String ?? "Artist"
        self.isVerified = dictionary["verified"] as? String ?? ""
        self.igInfo = dictionary["igInfo"] as? String ?? ""
        self.twitterInfo = dictionary["twitterInfo"] as? String ?? ""
        self.spotifyInfo = dictionary["spotifyInfo"] as? String ?? ""
        self.soundcloudInfo = dictionary["soundcloudInfo"] as? String ?? ""
        self.epkURL = dictionary["EPKurl"] as? String ?? ""
        self.epkPDF = dictionary["EPKpdf"] as? String ?? ""
        self.unreadNotifications = dictionary["unreadNotifications"] as? Int ?? 0
        if let profileImageURL = dictionary["photoURL"] as? String {
            self.profileImageURL = profileImageURL
        }
        if let headerImageURL = dictionary["headerURL"] as? String {
            self.headerImageURL = headerImageURL
        }
        
        if let bio = dictionary["bio"] as? String {
                   self.bio = bio
        }
        self.genre = dictionary["genre"] as? String ??  "No genre added"
        self.location = dictionary["location"] as? String ?? ""

    }
}

struct UserRelationStats {
    var followers: Int
    var following: Int
}
