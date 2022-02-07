import Foundation

public final class LocalFeedLoader {

    public typealias SaveResult = Error?
    public typealias SaveCompletion = (SaveResult) -> Void
    public typealias LoadResult = LoadFeedResult

    let store: FeedStore
    let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping SaveCompletion) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }

    public func load(completion: @escaping (LoadResult?) -> Void) {
        store.retrieve { result in
            switch result {
            case .empty:
                completion(.success([]))
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, _):
                completion(.success(feed.toModels()))
            }
        }
    }

    private func cache(_ feed: [FeedImage], with completion: @escaping SaveCompletion) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
 
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
