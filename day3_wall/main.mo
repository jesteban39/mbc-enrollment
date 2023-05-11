import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Order "mo:base/Order";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;


  stable var messageId: Nat = 0;
  let natHash = func (n: Nat ): Hash.Hash = Text.hash(Nat.toText(n)) ;
  var wall = HashMap.HashMap<Nat, Message>(5, Nat.equal, natHash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let msg: Message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(messageId, msg);
    messageId += 1;
    return messageId -1;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let msg = wall.get(messageId);
    switch(msg) {
      case(null) return #err("El messageId "# Nat.toText(messageId) #" no es valido");
      case(?msg) return #ok(msg);
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let msg = wall.get(messageId);
    switch(msg) {
      case(null) return #err("El messageId "# Nat.toText(messageId) #" no es valido");
      case(?msg) {
        if(Principal.notEqual(caller, msg.creator)) return #err("Usuario no autorizado");
        let newMsg: Message = {
          content = c;
          vote = msg.vote;
          creator = msg.creator;
        };
        return #ok(wall.put(messageId, newMsg));
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let msg = wall.get(messageId);
    switch(msg) {
      case(null) return #err("El messageId "# Nat.toText(messageId) #" no es valido");
      case(?msg) {
        if(Principal.notEqual(caller, msg.creator)) return #err("Usuario no autorizado");
        return #ok(wall.delete(messageId));
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let msg = wall.get(messageId);
    switch(msg) {
      case(null) return #err("El messageId "# Nat.toText(messageId) #" no es valido");
      case(?msg) {
        let newMsg: Message = {
          content = msg.content;
          vote = msg.vote + 1;
          creator = msg.creator;
        };
        return #ok(wall.put(messageId, newMsg));
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let msg = wall.get(messageId);
    switch(msg) {
      case(null) return #err("El messageId "# Nat.toText(messageId) #" no es valido");
      case(?msg) {
        let newMsg: Message = {
          content = msg.content;
          vote = msg.vote - 1;
          creator = msg.creator;
        };
        return #ok(wall.put(messageId, newMsg));
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    var values = Buffer.Buffer< Message >(wall.size());
    for (value in wall.vals()) values.add(value);
    return Buffer.toArray(values);
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {    
    var values = Buffer.Buffer< Message >(wall.size());
    for (value in wall.vals()) values.add(value);
    let compare = func (m1: Message, m2: Message): Order.Order {
      if(m1.vote > m2.vote) return #less;
      if(m1.vote < m2.vote) return #greater;
      return #equal;
    };

    return Array.sort(Buffer.toArray(values), compare)
  };
};
