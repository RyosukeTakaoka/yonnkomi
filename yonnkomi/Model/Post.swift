struct Post: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let userId: String
    let postImages: [String]
    let thumbnailPost: String
    let createdAt: String
    var isLiked: Bool
}
