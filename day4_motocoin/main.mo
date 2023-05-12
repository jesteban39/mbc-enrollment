
import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Blob "mo:base/Blob";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var sum = 0;
    for (val in ledger.vals()) sum += val;
    return sum;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    let value = ledger.get(account);
    return Option.get(value, 0);
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let fromV = ledger.get(from);
    if (fromV == null) return #err("That account doesn't exist");
    let fromVR = Option.get(fromV, 0);
    if (fromVR < amount) return #err("Not enough Tokens");
    let toV = ledger.get(to);
    if (toV == null) return #err("That account doesn't exist");
    let toVR = Option.get(toV, 0);

    let resF = ledger.replace(from, fromVR - amount);
    let resT = ledger.replace(to, toVR + amount);

    if (Option.isSome(resF) and Option.isSome(resT)) return #ok();

    return #err("Internal error");
  };

  let invoiceCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
  };
  
  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {

    let allStudents = await invoiceCanister.getAllStudentsPrincipal();

    if (allStudents.size() <= 0) return #err("No Students");

    let saveAccount = func(student : Principal) : Nat {
      let account = {
        owner = student;
        subaccount = null;
      };
      let value = ledger.get(account);
      ledger.put(account, Option.get(value, 0) + 100);
      return 0;
    };

    let as = Array.map(allStudents, saveAccount);

    return #ok();
  };
};