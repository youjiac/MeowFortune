import SwiftUI

/// 貓咪圖庫：網路圖片（cataas.com 免費貓咪圖片 API），下拉換一批
struct GalleryView: View {
    @State private var batch = 0
    @State private var selected: Photo?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var photoURLs: [URL] {
        (1...10).compactMap { URL(string: "https://cataas.com/cat?width=400&height=400&n=\(batch)-\($0)") }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photoURLs, id: \.self) { url in
                        Button { selected = Photo(url: url) } label: {
                            CatPhoto(url: url)
                                .frame(height: 170)
                                .frame(maxWidth: .infinity)
                                .clipShape(.rect(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("貓咪照片")
                    }
                }
                .padding()
                Text("照片來源：cataas.com · 下拉換一批")
                    .font(.huninn(13))
                    .foregroundStyle(.secondary)
            }
            .background(Color.creamBG)
            .navigationTitle("貓咪圖庫")
            .refreshable { batch += 1 }
            .sheet(item: $selected) { photo in
                CatPhoto(url: photo.url)
                    .scaledToFit()
                    .padding()
                    .presentationDetents([.medium])
            }
        }
    }
}

/// 被點開的照片
struct Photo: Identifiable {
    let url: URL
    var id: URL { url }
}

struct CatPhoto: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ink.opacity(0.08))
    }
}

#Preview {
    GalleryView()
}
