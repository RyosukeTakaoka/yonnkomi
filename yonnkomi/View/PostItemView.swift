import SwiftUI

struct PostItemView: View {
    var post: Post
    let spacer: CGFloat
    var onLikeTapped: () -> Void
    var onTap: () -> Void

    var body: some View {
        let imageSize = UIScreen.main.bounds.width / 2 - spacer * 3

        VStack {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: post.thumbnailPost)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipped()
                } placeholder: {
                    Color.gray
                        .frame(width: imageSize, height: imageSize)
                }

                // 投稿者のプロフィール画像を表示
                if let profileImageUrl = post.userProfileImageUrl, !profileImageUrl.isEmpty {
                    AsyncImage(url: URL(string: profileImageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: imageSize * 0.2, height: imageSize * 0.2)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize * 0.2, height: imageSize * 0.2)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 2)
                        case .failure(_):
                            Circle()
                                .fill(Color.orange)
                                .frame(width: imageSize * 0.2, height: imageSize * 0.2)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: imageSize * 0.08))
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 2)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .offset(x: -spacer, y: -spacer)
                } else {
                    // プロフィール画像がない場合はデフォルトアイコン
                    Circle()
                        .fill(Color.orange)
                        .frame(width: imageSize * 0.2, height: imageSize * 0.2)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: imageSize * 0.08))
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 2)
                        .offset(x: -spacer, y: -spacer)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(post.createdAt.timeAgo())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onLikeTapped) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(post.isLiked ? .red : .gray)
                        .padding(12)
                        .background(Color.white.opacity(0.001))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 4)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
