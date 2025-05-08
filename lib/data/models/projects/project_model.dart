class Project {
  final String name;
  final String color;
  final int order;
  final bool isShared;
  final bool isFavorite;
  final bool isInboxProject;
  final bool isTeamInbox;
  final String viewStyle;
  final int id;
  final String? url;
  final int? userId;

  Project({
    required this.name,
    required this.color,
    required this.order,
    required this.isShared,
    required this.isFavorite,
    required this.isInboxProject,
    required this.isTeamInbox,
    required this.viewStyle,
    required this.id,
    this.url,
   this.userId,
  });

  factory Project.fromMap(Map<String, dynamic> json) {
    return Project(
      name: json['name'] as String,
      color: json['color'] as String,
      order: json['order'] as int,
      isShared: json['is_shared'] as bool,
      isFavorite: json['is_favorite'] as bool,
      isInboxProject: json['is_inbox_project'] as bool,
      isTeamInbox: json['is_team_inbox'] as bool,
      viewStyle: json['view_style'] as String,
      id: json['id'] as int,
      url: json['url'] as String?,
      userId: json['user_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'order': order,
      'is_shared': isShared,
      'is_favorite': isFavorite,
      'is_inbox_project': isInboxProject,
      'is_team_inbox': isTeamInbox,
      'view_style': viewStyle,
      'id': id,
      'url': url,
      'user_id': userId,
    };
  }

  Project copyWith({
    String? name,
    String? color,
    int? order,
    bool? isShared,
    bool? isFavorite,
    bool? isInboxProject,
    bool? isTeamInbox,
    String? viewStyle,
    int? id,
    String? url,
    int? userId,
  }) {
    return Project(
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
      isShared: isShared ?? this.isShared,
      isFavorite: isFavorite ?? this.isFavorite,
      isInboxProject: isInboxProject ?? this.isInboxProject,
      isTeamInbox: isTeamInbox ?? this.isTeamInbox,
      viewStyle: viewStyle ?? this.viewStyle,
      id: id ?? this.id,
      url: url ?? this.url,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    // TODO: implement toString
    return "Project('name': $name, 'id': $id)";
  }
}
