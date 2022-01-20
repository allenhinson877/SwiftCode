import Firebase

typealias DatabaseCompletion = ((Error?, DatabaseReference) -> Void)

struct Service {
    static let shared = Service()
    
    var postCell : UpdatedPostCollectionCell?
    
    func fetchUserPost(forUser user: User, completion: @escaping([Post]) -> Void) {
        var posts = [Post]()
        
        print("FETCHING USER POST")
        
        USERS_COLLECTIONS.document(user.uid).collection("user-posts").getDocuments { snapshot, _ in
            let documents = snapshot!.documents
            
            for document in documents {
                let postID = document.documentID
                self.fetchPost(withPostID: postID) { post in
                    posts.append(post)
                    completion(posts)
                }
            }
        }
    }
    
    func FetchPosts(completion: @escaping([Post]) -> Void) {
        var posts = [Post]()
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        FOLLOWING_COLLECTIONS.document(currentUid).collection("user-following").getDocuments { snapshot, _ in
            guard let document = snapshot?.documents else { return }
            for document in snapshot!.documents {
                print("Document id is \(document.documentID)")
                
                USERS_COLLECTIONS.document(document.documentID).collection("user-posts").getDocuments { snapshot, _ in
                    guard let document = snapshot?.documents else { return }
                    for document in snapshot!.documents {
                        self.fetchPost(withPostID: document.documentID) { post in
                            posts.append(post)
                            completion(posts)
                        }
                    }
                }
            }
        }
        
        USERS_COLLECTIONS.document(currentUid).collection("user-posts").getDocuments { snapshot, _ in
            guard let document = snapshot?.documents else { return }
            for document in snapshot!.documents {
                self.fetchPost(withPostID: document.documentID) { post in
                    posts.append(post)
                    completion(posts)
                }
            }
        }
    }
    
    func fetchPost(withPostID postID: String, completion: @escaping(Post) -> Void) {
        
        POSTS_COLLECTIONS.document(postID).getDocument { snapshot, _ in
            print(snapshot)
            guard let data = snapshot?.data() else { return }
            guard let uid = data["uid"] as? String else { return }
            
            UserService.shared.fetchUser(uid: uid) { user in
                let post = Post(postID: postID, user: user, dictionary: data)
                completion(post)
            }
        }
    }
        
    func fetchLikes(forUser user: User, completion: @escaping([Post]) -> Void) {
        var posts = [Post]()
                
        USERS_COLLECTIONS.document(user.uid).collection("user-likes").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                let postID = document.documentID
                
                self.fetchPost(withPostID: postID) { likedPost in
                    var post = likedPost
                    post.didLike = true
                    posts.append(post)
                    completion(posts)
                }
            }
        }
    }
    
    func followUser(uid: String, completion:  @escaping () -> Void ) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let followingRef = FOLLOWING_COLLECTIONS.document(currentUid).collection("user-following")
        let followerRef = FOLLOWERS_COLLECTIONS.document(uid).collection("user-followers")
        print("FOLLOWING USER")
        followingRef.document(uid).setData([:]) { _ in
            followerRef.document(currentUid).setData([:]) { _ in
            }
        }
    }
    
    func unfollowUser(uid: String, completion:  @escaping () -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let followingRef = FOLLOWING_COLLECTIONS.document(currentUid).collection("user-following")
        let followerRef = FOLLOWERS_COLLECTIONS.document(uid).collection("user-followers")
        followingRef.document(uid).delete { _ in
            followerRef.document(currentUid).delete { _ in
                print("SUCCESSFULLLY UNFOLLOWED USER")
            }
        }
    }
    
    func checkIfUserIsFollowed(uid: String, completion: @escaping(Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let followingRef = FOLLOWING_COLLECTIONS.document(currentUid).collection("user-following")
        followingRef.document(uid).getDocument { snapshot, _ in
            completion(snapshot!.exists)
            print("Following user\(snapshot?.documentID)")
        }
    }
    
    func fetchUserStats(uid: String, completion: @escaping(UserRelationStats) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let followingRef = FOLLOWING_COLLECTIONS.document(uid).collection("user-following")
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
    
    func fetchComments(forPost post: Post, completion: @escaping([Post]) -> Void) {
        var posts = [Post]()

        POSTS_COLLECTIONS.document(post.postID).collection("post-comments").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            documents.forEach { document in
                print("Document data is \(document.data())")
                let data = document.data()
                guard let uid = data["uid"] as? String else { return }
                
                UserService.shared.fetchUser(uid: uid) { user in
                    let post = Post(postID: document.documentID, user: user, dictionary: data)
                    posts.append(post)
                    completion(posts)
                }
            }
        }
    }
    
    func fetchGigs(completion: @escaping([Gigs]) -> Void) {
        var gigs = [Gigs]()

        GIGS_REF.observe(.childAdded) { snapshot in
            guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
            guard let uid = dictionary["uid"] as? String else { return }
            let gigID = snapshot.key
            
            UserService.shared.fetchUser(uid: uid) { user in
                let gig = Gigs(GigId: gigID, user: user, dictionary: dictionary)
                gigs.append(gig)
                completion(gigs)
            }
        }
        
    }
    
    func fetchGig(forGig gigID: String, completion: @escaping(Gigs) -> Void) {

        GIGS_REF.child(gigID).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
            guard let uid = dictionary["uid"] as? String else { return }
            
            UserService.shared.fetchUser(uid: uid) { user in
                let gig = Gigs(GigId: gigID, user: user, dictionary: dictionary)
                completion(gig)
            }
        }
    }
    
    
    
    
    func likePost(post: Post, completion: @escaping () -> Void ) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let postLikesRef = POSTS_COLLECTIONS.document(post.postID).collection("post-likes")
        let userlikesRef = USERS_COLLECTIONS.document(uid).collection("user-likes")
        let likes = post.didLike ? post.likes - 1 : post.likes + 1
//        POSTS_REF.child(post.postID).child("likes").setValue(likes)
        POSTS_COLLECTIONS.document(post.postID).updateData(["likes": likes])
        
        if post.didLike {
            //unlike post
            postLikesRef.document(uid).delete { _ in
                userlikesRef.document(post.postID).delete()
            }
        } else {
            //like post
            postLikesRef.document(uid).setData([:]) { _ in
                userlikesRef.document(post.postID).setData([:])
            }
        }
        
        completion()
    }
    
 

    
    func applyToGig(gig: Gigs, completion: @escaping(DatabaseCompletion)) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let applications = gig.didApply ? gig.applications + 0 :  gig.applications + 1
        GIGS_REF.child(gig.GigId).child("applications").setValue(applications)
        
        if gig.didApply {
            //unlike post
            print("nothing")
        } else {
            USER_APPLICATION_REF.child(uid).updateChildValues([gig.GigId: 1]) { (err, ref) in
                GIG_APPLICATIONS_REF.child(gig.GigId).updateChildValues([uid: 1], withCompletionBlock: completion)
            }
        }
    }

    

    func checkIfUserLikedPost(_ post: Post, completion: @escaping(Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userlikesRef = USERS_COLLECTIONS.document(uid).collection("user-likes").document(post.postID)
        userlikesRef.getDocument { snapshot, _ in
            completion(snapshot!.exists)
        }
    }
    
    func signOut(completion: @escaping(Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch let error {
            print(error)
            completion(false)
        }
    }

    
    func uploadPost(caption: String, completion: @escaping() -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = POSTS_COLLECTIONS.document()
            let userPostRef = USER_POST_COLLECTIONS.document(uid)
            let userPost = USERS_COLLECTIONS.document(uid).collection("user-posts")
            let postID = docRef.documentID
            let values = ["uid": uid,
                          "timestampt": Int(NSDate().timeIntervalSince1970),
                          "likes": 0,
                          "text": caption,
                          "postID": docRef.documentID] as [String:Any]
    
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
        
        userPost.document(postID).setData([:])
        
      
    }
    
    func uploadPostWithURL(caption: String, url: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = POSTS_COLLECTIONS.document()

        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "url": url,
                      "text": caption,
                      "postID": docRef.documentID] as [String:Any]
        
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
    }

            
    func uploadPostWithImage(caption: String, postImage: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = POSTS_COLLECTIONS.document()

        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "text": caption,
                      "picture": postImage,
                      "postID": docRef.documentID] as [String:Any]
        
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
    }
    
    func uploadPostWithVideo(caption: String, postvideo: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = POSTS_COLLECTIONS.document()

        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "text": caption,
                      "video": postvideo,
                      "postID": docRef.documentID] as [String:Any]
        
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
    }
    
    func uploadImageOnly( postImage: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = POSTS_COLLECTIONS.document()

        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "picture": postImage] as [String:Any]
        
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
    }
    
    func uploadVideoOnly( postVideo: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = POSTS_COLLECTIONS.document()

        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "video": postVideo,
                      "postID": docRef.documentID] as [String:Any]
        
        docRef.setData(values) { _ in
            print("SUCCESSFULLY UPLOADED POST")
        }
    }
    
    func uploadRepost(caption: String, post: String, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["uid": uid,
                      "timestampt": Int(NSDate().timeIntervalSince1970),
                      "likes": 0,
                      "text": caption] as [String:Any]
        
        let ref = POSTS_REF.childByAutoId()
        ref.updateChildValues(values) { (err, ref) in
            guard let postID = ref.key else { return }
            USER_POSTS.child(uid).updateChildValues([postID: 1], withCompletionBlock: completion)
        }
    }
}
