import Text "mo:base/Text";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

actor class Homework() {
  
  public type Homework = {
    title : Text;
    description : Text;
    dueDate : Time.Time;
    completed : Bool;
  };

  var homeworkDiary = Buffer.Buffer< Homework >(1);

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return homeworkDiary.size() -1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if(id >= homeworkDiary.size()) return #err("El homeworkId no es valido");
    return #ok(homeworkDiary.get(id));
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) return #err("El homeworkId no es valido");
    return #ok(homeworkDiary.put(id, homework));
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) return #err("El homeworkId no es valido");
    let hw: Homework = homeworkDiary.get(id);
    let homework: Homework = {
      title = hw.title;
      description = hw.description;
      dueDate = hw.dueDate;
      completed = true;
    };
    return #ok(homeworkDiary.put(id, homework));
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) return #err("El homeworkId no es valido");
    let h: Homework = homeworkDiary.remove(id);
    return #ok();
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    let pending = Buffer.mapFilter <Homework, Homework>(
      homeworkDiary, 
      func (homework: Homework) {
        if(homework.completed) return null;
        return ?homework;
      }
    );
    return Buffer.toArray(homeworkDiary);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let pending = Buffer.mapFilter <Homework, Homework>(
      homeworkDiary, 
      func (homework: Homework) {
        if(Text.contains(homework.title, #text searchTerm )) return ?homework;
        if(Text.contains(homework.description, #text searchTerm )) return ?homework;
        return null;
      }
    );
    return Buffer.toArray(homeworkDiary);
  };
};