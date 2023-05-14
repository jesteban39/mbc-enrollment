import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Timer "mo:base/Timer";
import Iter "mo:base/Iter";

import HTTP "Http";
import IC "ic";
import Type "Types";

actor class Verifier() {

  // STEP 1 - BEGIN
  type StudentProfile = Type.StudentProfile;

  stable var entries : [(Principal, StudentProfile)] = [];
  let natHash = func(n : Nat) : Hash.Hash = Text.hash(Nat.toText(n));
  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(0, Principal.equal, Principal.hash);

  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    for (it in Iter.fromArray(entries)) {
      studentProfileStore.put(it);
    };
    entries := [];
  };
  
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    studentProfileStore.put(caller, profile);
    return #ok();
  };

  public shared ({ caller }) func seeAProfile(principalId : Principal) : async Result.Result<StudentProfile, Text> {
    let student = studentProfileStore.get(principalId);
    switch (student) {
      case (null) return #err("El estudiante no es esta registrado");
      case (?student) return #ok(student);
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err("You must be Logged In");
    };

    let student = studentProfileStore.replace(caller, profile);
    switch (student) {
      case (null) return #err("El estudiante no es esta registrado");
      case (?student) return #ok();
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let student = studentProfileStore.remove(caller);
    switch (student) {
      case (null) return #err("El estudiante no es esta registrado");
      case (?student) return #ok();
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type CalculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {

    try {
      var value: Int = 0;
      let calculator = actor(Principal.toText(canisterId)): CalculatorInterface;

      value := await calculator.reset();
      if(value != 0) return #err(#UnexpectedValue("reset not fun"));
      value := await calculator.add(3);
      if(value != 3) return #err(#UnexpectedValue("add not fun"));
      value := await calculator.sub(1);
      if(value != 2) return #err(#UnexpectedValue("sub not fun"));
      value := await calculator.reset();
      if(value != 0) return #err(#UnexpectedValue("reset not fun"));
      
      return #ok();

    } catch (e) {
      return #err(#UnexpectedError(Error.message(e)));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, principalId : Principal) : async Result.Result<Bool, Text> {

    try {
      
      let controllers = await IC.getCanisterControllers(canisterId);

      var isOwner : ?Principal = Array.find<Principal>(controllers, func prin = prin == principalId);
      
      if (isOwner != null) return #ok(true);

      return #ok(false);
    } catch (e) {
      return #err(Error.message(e));
    }
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, principalId : Principal) : async Result.Result<Bool, Text> {
    
    try {

      if (Principal.isAnonymous(caller)) {
        return #err("You must be Logged In");
      };
      
      switch(await test(canisterId)) {
        case(#err(TextError)) return #err("The current work has no passed the tests");
        case(#ok()) {};
      };

      switch (await verifyOwnership(canisterId, principalId)) {
        case (#ok(true)) {};
        case (#ok(false)) return #err("The received work owner does not match with the received principal");
        case (_) return #err("Cannot verify the project");
      };

      let student = studentProfileStore.get(principalId);
      switch (student) {
        case (null) return #err("The received principal does not belongs to a registered student");
        case (?student) {
          let approved: StudentProfile = {
            name = student.name;
            team = student.team;
            graduate = true;
          };
          
          switch (studentProfileStore.replace(caller, approved)) {
            case (null) return #err("The received principal does not belongs to a registered student");
            case (?student) return #ok(true);
          };
        };
      };

      return #err("Cannot verify the project");

    } catch (e) {
      return #err(Error.message(e));
    };
  };
  // STEP 4 - END

  // STEP 5 - BEGIN
  public type HttpRequest = HTTP.HttpRequest;
  public type HttpResponse = HTTP.HttpResponse;

  // NOTE: Not possible to develop locally,
  // as Timer is not running on a local replica
  public func activateGraduation() : async () {
    return ();
  };

  public func deactivateGraduation() : async () {
    return ();
  };

  public query func http_request(request : HttpRequest) : async HttpResponse {
    return ({
      status_code = 200;
      headers = [];
      body = Text.encodeUtf8("");
      streaming_strategy = null;
    });
  };
  // STEP 5 - END
};
