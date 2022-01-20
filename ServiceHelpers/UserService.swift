import Foundation
import Firebase


class UserService {
    
    static let shared = UserService()
    
    static var currentUserProfile:User?
    
    static func observeUserProfile(_ uid:String, completion: @escaping ((_ UserProfile:User?)->())) {
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            completion(User(dictionary: data))
            
        }
    }
    
    func fetchUser(uid: String, completion: @escaping(User) -> Void) {

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let user = User(dictionary: data)
            completion(user)
        }
    }
    
    
   func fetchNewUser(uid: String, completion: @escaping(User) -> Void) {
       REF_USERS.child(uid).observeSingleEvent(of: .value) { snapshot in
           guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                       
           var user = User(dictionary: dictionary)
           
           self.fetchUserStats(uid: user.uid) { stats in
               user.stats = stats
               completion(user)
           }
       }
   }
    
    func fetchUserStats(uid: String, completion: @escaping(UserRelationStats) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        let followingRef = FOLLOWING_COLLECTIONS.document(currentUid).collection("user-following")
        let followerRef = FOLLOWERS_COLLECTIONS.document(uid).collection("user-followers")
        
        followerRef.getDocuments { snapshot, _ in
            guard let followersCount = snapshot?.documents.count else { return }
            
            followingRef.getDocuments { snapshot, _ in
                guard let followingCount = snapshot?.documents.count else { return }
                
                let stats = UserRelationStats(followers: followersCount, following: followingCount)
                completion(stats)
            }
        }
        
       }
    
    func fetchFollowing(uid: String, completion: @escaping(User) -> Void) {
        USER_FOLLOWING_REF.child(uid).observeSingleEvent(of: .childAdded) { snapshot in
            let following = snapshot.children
            print(following)
        }
    }
    
    func fetchUsers(completion: @escaping([User]) -> Void) {
        var users = [User]()
        REF_USERS.observe(.childAdded) { snapshot in
            let uid = snapshot.key
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            let user = User(dictionary: dictionary)
            users.append(user)
            completion(users)
        }
    }
    
    func fetchUsersCollections(completion: @escaping([User]) -> Void) {
        var users = [User]()
        USERS_COLLECTIONS.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            users = documents.map({ User(dictionary: $0.data()) })
        }

    }
    
    
    func fetchUserByUserName(withUsername username: String, completion: @escaping(User) -> Void) {
        REF_USER_USERNAMES.child(username).observeSingleEvent(of: .value) { snapshot in
            guard let uid = snapshot.value as? String else { return }
            self.fetchUser(uid: uid, completion: completion)
        }
    }
}
