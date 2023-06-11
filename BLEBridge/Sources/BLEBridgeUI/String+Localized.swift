
extension String {

    func localized() -> String {
        String.init(localized: .init(self), bundle: .module)
    }
}
