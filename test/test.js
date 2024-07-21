const { assert } = require("chai");

const Decentragram = artifacts.require("./Decentragram.sol");

require("chai")
  .use(require("chai-as-promised"))
  .should();

contract("Decentragram", ([deployer, owner, tipper]) => {
  let decentragram;

  before(async () => {
    decentragram = await Decentragram.deployed();
  });

  describe("deployment", async () => {
    it("deploys successfully", async () => {
      const address = await decentragram.address;
      assert.notEqual(address, 0x0);
      assert.notEqual(address, "");
      assert.notEqual(address, null);
      assert.notEqual(address, undefined);
    });

    it("has a name", async () => {
      const name = await decentragram.contractName();
      assert.equal(name, "Decentragram");
    });
  });

  describe("createAccount", () => {
    let result, userID, profile;
    let username = "test_username";
    let biography = "This is a test biography";
    let profilePictureURL =
      "https://fuchsia-recent-squirrel-434.mypinata.cloud/ipfs/QmRSZrGXfsu7dsboestCcf1mFy7FS3owbSoxZn81HCNiw8";
    before(async () => {
      result = await decentragram.createAccount(
        username,
        biography,
        profilePictureURL,
        { from: owner }
      );
      userID = await decentragram._userID();
      profile = await decentragram.profiles(owner).owner;
    });
    it("creates a new account", async () => {
      // Success
      assert.equal(userID, 1);
      assert.equal(profile, null, "profile not exists yet");
      const event = result.logs[0].args;
      assert.equal(event.owner, owner, "owner is correct");
      assert.equal(event.username, username, "username is correct");
      assert.equal(event.biography, biography, "biography is correct");
      assert.equal(
        event.profilePictureURL,
        profilePictureURL,
        "profilePictureURL is correct"
      );
      // Test it should not allow to create an account without username
      await decentragram.createAccount("", biography, profilePictureURL, {
        from: owner,
      }).should.be.rejected;
    });
  });

  describe("updateProfile", () => {
    let result, profile;
    let updatedUsername = "updated_username";
    let updatedBiography = "This is an updated biography";
    let updatedProfilePictureURL =
      "https://fuchsia-recent-squirrel-434.mypinata.cloud/ipfs/QmRSZrGXfsu7dsboestCcf1mFy7FS3owbSoxZn81HCNiw8";
    before(async () => {
      result = await decentragram.editProfile(
        owner,
        updatedUsername,
        updatedBiography,
        updatedProfilePictureURL,
        { from: owner }
      );
      profile = await decentragram.profiles(owner);
    });
    it("updates a user profile", async () => {
      // Success
      assert.notEqual(profile, null, "user profile exists");
      const event = result.logs[0].args;
      assert.equal(event.owner, owner, "owner is correct");
      assert.equal(
        event.username,
        updatedUsername,
        "updated username is correct"
      );
      assert.equal(
        event.biography,
        updatedBiography,
        "updated biography is correct"
      );
      assert.equal(
        event.profilePictureURL,
        updatedProfilePictureURL,
        "updated profilePictureURL is correct"
      );
      // Test it should not allow to update an account without username
      await decentragram.createAccount(
        owner,
        "",
        updatedBiography,
        updatedProfilePictureURL,
        {
          from: owner,
        }
      ).should.be.rejected;
    });
  });

  describe("createPost", () => {
    let result, postID, profile;
    let postDescription = "test_post_description";
    let postType = "Image";
    let postURL =
      "https://fuchsia-recent-squirrel-434.mypinata.cloud/ipfs/QmRSZrGXfsu7dsboestCcf1mFy7FS3owbSoxZn81HCNiw8";
    before(async () => {
      result = await decentragram.createPost(
        postDescription,
        postURL,
        postType,
        {
          from: owner,
        }
      );
      postID = await decentragram._postID();
      profile = await decentragram.profiles(owner);
    });
    it("user has a profile", async () => {
      assert.notEqual(profile, null, "user profile exists");
    });
    it("creates a new post", async () => {
      // Success
      assert.equal(postID, 1);
      const event = result.logs[0].args;
      assert.equal(event.author, owner, "owner is correct");
      assert.equal(
        event.postDescription,
        postDescription,
        "post description is correct"
      );
      assert.equal(event.postURL, postURL, "post URL is correct");
      assert.equal(event.postType, postType, "post type is correct");

      // Test it should not allow to create a post without post description
      await decentragram.createPost("", postURL, postType, {
        from: owner,
      }).should.be.rejected;
    });
  });

  describe("likePost", () => {
    let result, postID, profile;
    before(async () => {
      postID = await decentragram._postID();
      result = await decentragram.likePost(postID, {
        from: owner,
      });
      profile = await decentragram.profiles(owner);
    });
    it("user has a profile", async () => {
      assert.notEqual(profile, null, "user profile exists");
    });
    it("likes a post", async () => {
      const event = result.logs[0].args;
      assert.equal(
        event.userWhoLike,
        owner,
        "user address who likes the post is correct"
      );
      assert.equal(
        event.postID,
        1,
        "id of post that has been liked is correct"
      );
      assert.equal(event.likeCount, 1, "like count increment is correct");
    });
  });

  describe("unlikePost", () => {
    let result, postID, profile;
    before(async () => {
      postID = await decentragram._postID();
      result = await decentragram.unlikePost(postID, {
        from: owner,
      });
      profile = await decentragram.profiles(owner);
    });
    it("user has a profile", async () => {
      assert.notEqual(profile, null, "user profile exists");
    });
    it("post that the user removes a like has been previously liked", async () => {
      assert.equal(postID, 2, "post has been previously liked");
    });
    it("unlikes a post", async () => {
      const event = result.logs[0].args;
      assert.equal(
        event.userWhoLike,
        owner,
        "user address who unlikes the post is correct"
      );
      assert.equal(
        event.postID,
        1,
        "id of post that has been removed a like is correct"
      );
      assert.equal(event.likeCount, 0, "like count decrement is correct");
    });
  });

  describe("dislikePost", () => {
    let result, postID, profile;
    before(async () => {
      postID = await decentragram._postID();
      result = await decentragram.dislikePost(postID, {
        from: owner,
      });
      profile = await decentragram.profiles(owner);
    });
    it("user has a profile", async () => {
      assert.notEqual(profile, null, "user profile exists");
    });
    it("dislikes a post", async () => {
      const event = result.logs[0].args;
      assert.equal(
        event.userWhoDislike,
        owner,
        "user address who dislikes the post is correct"
      );
      assert.equal(
        event.postID,
        1,
        "id of post that has been disliked is correct"
      );
      assert.equal(event.dislikeCount, 1, "dislike count increment is correct");
    });
  });

  describe("undislikePost", () => {
    let result, postID, profile;
    before(async () => {
      postID = await decentragram._postID();
      result = await decentragram.undislikePost(postID, {
        from: owner,
      });
      profile = await decentragram.profiles(owner);
    });
    it("user has a profile", async () => {
      assert.notEqual(profile, null, "user profile exists");
    });
    it("post that the user removes a dislike has been previously disliked", async () => {
      assert.equal(postID, 1, "post has been previously disliked");
    });
    it("undislikes a post", async () => {
      const event = result.logs[0].args;
      assert.equal(
        event.userWhoDislike,
        owner,
        "user address who undislikes the post is correct"
      );
      assert.equal(
        event.postID,
        1,
        "id of post that has been removed a dislike is correct"
      );
      assert.equal(event.dislikeCount, 0, "dislike count decrement is correct");
    });
  });
});
