/// Id : "066d25e8-3a84-4c57-8f1c-a820da6f88d5"
/// user_blocked_id : "584bc428-0f77-4406-9a81-486e83ad8526"
/// user_id : "7f88bd16-db4b-4ac6-85fb-47910b15ee74"
class BlockUser {
   String id;
   String userBlockedId;
   String userId;

  BlockUser({
    required this.id,
    required this.userBlockedId,
    required this.userId,
  });

  BlockUser.fromJson(Map<String, dynamic> json)
      : id = json['Id'],
        userBlockedId = json['user_blocked_id'],
        userId = json['user_id'];

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'user_blocked_id': userBlockedId,
      'user_id': userId,
    };
  }
}

