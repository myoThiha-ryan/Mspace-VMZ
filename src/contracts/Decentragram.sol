pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Decentragram {
    string public contractName;
    address public admin;
    address[] internal addresses;
    mapping(string => address) internal names;

    //Generating ID
    uint256 public _postID;
    uint256 public _userID;

    // Profile
    struct Profile {
        address owner;
        string username;
        string biography;
        string profilePictureURL;
        uint timeCreated;
        uint id;
        uint postCount;
        uint followerCount;
        uint followingCount;
        address[] followers;
        address[] following;
    }

    struct Post {
        uint postId;
        address payable author;
        string username;
        string profilePictureURL;
        string postType;
        string postURL;
        string postDescription;
        uint timeCreated;
        uint tipAmount;
        uint likes;
        uint dislikes;
    }

    struct AllUserStruct {
        address owner;
        string username;
        string biography;
        string profilePictureURL;
        uint timeCreated;
        uint id;
        uint postCount;
        uint followerCount;
        uint followingCount;
    }

    // to map from the user account address to related profile struct
    mapping(address => Profile) public profiles;
    // to map from the user's account address to the array of related posts created
    mapping(address => Post[]) internal posts;
    // to map from the user's account address to the array of post ids that the user liked
    mapping(address => uint[]) internal likedPosts;
    // to map from the user's account address to the array of post ids that the user disliked
    mapping(address => uint[]) internal dislikedPosts;
    // array to store all the registered users
    AllUserStruct[] getAllUsers;
    // array to store all the created posts by users
    Post[] allPosts;

    // Events

    event AccountCreated(
        address owner,
        string username,
        string biography,
        string profilePictureURL
    );

    event PostCreated(
        address payable author,
        string postDescription,
        string postType,
        string postURL
    );

    event PostLiked(address userWhoLike, uint256 postID, uint256 likeCount);

    event PostDisliked(
        address userWhoDislike,
        uint256 postID,
        uint256 dislikeCount
    );

    // Check if message sender has a created profile
    modifier senderHasProfile() {
        require(
            profiles[msg.sender].owner != address(0x0),
            "ERROR: <Must create a profile to perform this action>"
        );
        _;
    }

    // Check if a specified address has created a profile
    modifier profileExists(address _address) {
        require(
            profiles[_address].owner != address(0x0),
            "ERROR: <Profile does not exist>"
        );
        _;
    }

    constructor() public {
        contractName = "Decentragram";
        admin = msg.sender;
    }

    // Create a new user account
    function createAccount(
        string memory _username,
        string memory _biography,
        string memory _profilePictureURL
    ) public {
        // Checks that the current account address did not already make a user account
        require(
            profiles[msg.sender].owner == address(0x0),
            "ERROR: <You have already created an account>"
        );
        // Checks that the current account address did not choose a taken username
        require(names[_username] == address(0x0), "ERROR: <Username taken>");
        //Increment User ID
        _userID++;
        uint256 userID = _userID;

        // Updates username list
        names[_username] = msg.sender;

        // Create the new profile object and add it to "profiles" mapping
        profiles[msg.sender] = Profile({
            owner: msg.sender,
            username: _username,
            biography: _biography,
            profilePictureURL: _profilePictureURL,
            timeCreated: block.timestamp,
            id: userID,
            postCount: 0,
            followerCount: 0,
            followingCount: 0,
            followers: new address[](0x0),
            following: new address[](0x0)
        });

        // Add address to list of global addresses
        addresses.push(msg.sender);

        getAllUsers.push(
            AllUserStruct(
                msg.sender,
                _username,
                _biography,
                _profilePictureURL,
                block.timestamp,
                userID,
                0,
                0,
                0
            )
        );
        emit AccountCreated(
            msg.sender,
            _username,
            _biography,
            _profilePictureURL
        );
    }

    function editProfile(
        address _address,
        string memory _username,
        string memory _biography,
        string memory _profilePictureURL
    ) public {
        for (uint i = 0; i < getAllUsers.length; i++) {
            if (getAllUsers[i].owner == _address) {
                getAllUsers[i].username = _username;
                getAllUsers[i].biography = _biography;
                profiles[_address].username = _username;
                profiles[_address].biography = _biography;
                if (bytes(_profilePictureURL).length > 0) {
                    getAllUsers[i].profilePictureURL = _profilePictureURL;
                    profiles[_address].profilePictureURL = _profilePictureURL;
                }
                break;
            }
        }
        emit AccountCreated(
            msg.sender,
            _username,
            _biography,
            _profilePictureURL
        );
    }

    //Create a Post
    function createPost(
        string memory _postDescription,
        string memory _postURL,
        string memory _postType
    ) public senderHasProfile {
        _postID++;
        uint256 postID = _postID;

        Post memory newPost = Post({
            postId: postID,
            author: msg.sender,
            username: profiles[msg.sender].username,
            profilePictureURL: profiles[msg.sender].profilePictureURL,
            postType: _postType,
            postURL: _postURL,
            postDescription: _postDescription,
            timeCreated: block.timestamp,
            tipAmount: 0,
            likes: 0,
            dislikes: 0
        });

        // Add entry to "posts" mappings
        posts[newPost.author].push(newPost);

        // Increment "postCount" in Profile object
        profiles[newPost.author].postCount++;
        // Increment "postCount" in All User object
        for (uint256 i = 0; i < getAllUsers.length; i++) {
            if (getAllUsers[i].owner == newPost.author) {
                getAllUsers[i].postCount++;
            }
        }

        emit PostCreated(msg.sender, _postDescription, _postType, _postURL);
    }

    // like post
    function likePost(uint256 _postId) external senderHasProfile {
        for (uint i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < posts[addresses[i]].length; j++) {
                if (posts[addresses[i]][j].postId == _postId) {
                    posts[addresses[i]][j].likes++;
                    likedPosts[msg.sender].push(_postId);
                    emit PostLiked(
                        msg.sender,
                        posts[addresses[i]][j].postId,
                        posts[addresses[i]][j].likes
                    );
                    break;
                }
            }
        }
    }
    // Unlike post
    function unlikePost(uint256 _postId) external senderHasProfile {
        for (uint i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < posts[addresses[i]].length; j++) {
                if (posts[addresses[i]][j].postId == _postId) {
                    posts[addresses[i]][j].likes--;
                    break;
                }
            }
        }
        for (uint i = 0; i < likedPosts[msg.sender].length; i++) {
            if (_postId == likedPosts[msg.sender][i]) {
                likedPosts[msg.sender][i] = likedPosts[msg.sender][
                    likedPosts[msg.sender].length - 1
                ];
                likedPosts[msg.sender].pop();
                break;
            }
        }
    }

    // dislike post
    function dislikePost(uint256 _postId) external senderHasProfile {
        for (uint i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < posts[addresses[i]].length; j++) {
                if (posts[addresses[i]][j].postId == _postId) {
                    posts[addresses[i]][j].dislikes++;
                    dislikedPosts[msg.sender].push(_postId);
                    break;
                }
            }
        }
    }

    // undislike post
    function undislikePost(uint256 _postId) external senderHasProfile {
        for (uint i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < posts[addresses[i]].length; j++) {
                if (posts[addresses[i]][j].postId == _postId) {
                    posts[addresses[i]][j].dislikes--;
                    break;
                }
            }
        }
        for (uint i = 0; i < dislikedPosts[msg.sender].length; i++) {
            if (_postId == dislikedPosts[msg.sender][i]) {
                dislikedPosts[msg.sender][i] = dislikedPosts[msg.sender][
                    dislikedPosts[msg.sender].length - 1
                ];
                dislikedPosts[msg.sender].pop();
                break;
            }
        }
    }

    // Return all registered users
    function getAllAppUser() public view returns (AllUserStruct[] memory) {
        return getAllUsers;
    }

    // Returns all posts from a given address
    function getPosts(
        address _address
    ) external view profileExists(_address) returns (Post[] memory) {
        return posts[_address];
    }

    function getLikedPostIDs(
        address _address
    ) external view returns (uint[] memory) {
        return likedPosts[_address];
    }

    function getDislikedPostIDs(
        address _address
    ) external view returns (uint[] memory) {
        return dislikedPosts[_address];
    }

    // Returns total user count
    function getUserCount() external view returns (uint) {
        return addresses.length;
    }

    // Returns all registered addresses
    function getAddresses() external view returns (address[] memory) {
        return addresses;
    }

    // Get all followers of a specific address
    function getFollowers(
        address _address
    ) external view profileExists(_address) returns (address[] memory) {
        return profiles[_address].followers;
    }

    // Get all followed accounts of a specific address
    function getFollowing(
        address _address
    ) external view returns (address[] memory) {
        return profiles[_address].following;
    }

    function getAllPosts() public view returns (Post[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            itemCount += posts[addresses[i]].length;
        }

        Post[] memory items = new Post[](itemCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint j = 0; j < posts[addresses[i]].length; j++) {
                items[currentIndex] = posts[addresses[i]][j];
                currentIndex += 1;
            }
        }
        return items;
    }
}
