import SwiftUI
import UIKit

struct StoriesView: View {
    @State private var selectedStory: BibleStory?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Storybook Library")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)

                        Text("Tap a book cover, then swipe to turn pages.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 16)

                    ForEach(Array(BibleStory.library.enumerated()), id: \.element.id) { index, story in
                        StoryBookCover(
                            story: story,
                            palette: StoryCoverPalette.all[index % StoryCoverPalette.all.count]
                        ) {
                            selectedStory = story
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedStory) { story in
            StoryReaderView(story: story)
        }
    }
}

private struct StoryBookCover: View {
    let story: BibleStory
    let palette: StoryCoverPalette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.primary, palette.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 10)

                HStack(spacing: 14) {
                    Text(story.icon)
                        .font(.system(size: 34))
                        .frame(width: 54, height: 54)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(story.title)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(story.referenceRange)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)

                        Text("Tap to open")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 138)
        }
        .buttonStyle(StoryCoverPressStyle())
    }
}

private struct StoryCoverPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct StoryReaderView: View {
    let story: BibleStory
    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex: Int = 0

    private var pages: [StoryPage] {
        if story.isDavidStory {
            return [
                StoryPage(
                    title: story.title,
                    body: "",
                    icon: nil,
                    reference: story.referenceRange,
                    imageName: "davidOne",
                    isImageOnly: true
                ),
                StoryPage(
                    title: story.title,
                    body: "",
                    icon: nil,
                    reference: story.referenceRange,
                    imageName: "davidTwo",
                    isImageOnly: true
                )
            ]
        }

        var bookPages: [StoryPage] = [
            StoryPage(
                title: story.title,
                body: "A true Bible story from \(story.referenceRange).",
                icon: story.icon,
                reference: story.referenceRange
            )
        ]

        bookPages.append(
            StoryPage(
                title: "Meet the People",
                body: story.people,
                icon: "👥",
                reference: story.referenceRange
            )
        )

        for scene in story.scenes {
            bookPages.append(
                StoryPage(
                    title: scene.title,
                    body: scene.body,
                    icon: nil,
                    reference: story.referenceRange
                )
            )
        }

        bookPages.append(
            StoryPage(
                title: "Verse to Remember",
                body: "\"\(story.verseQuote)\"",
                icon: "📜",
                reference: story.verseReference
            )
        )

        bookPages.append(
            StoryPage(
                title: "What We Learn",
                body: story.lesson,
                icon: "💡",
                reference: story.referenceRange
            )
        )

        bookPages.append(
            StoryPage(
                title: "The End",
                body: "Go back to the library and open another story.",
                icon: "📖",
                reference: story.referenceRange
            )
        )

        return bookPages
    }

    var body: some View {
        ZStack {
            StoryReaderBackdrop(story: story)

            PageCurlReader(pages: pages, currentIndex: $pageIndex) { index, page in
                StoryReaderPageView(
                    story: story,
                    page: page,
                    pageNumber: index + 1,
                    pageCount: pages.count
                )
            }
            .ignoresSafeArea()

            StoryReaderOverlay(
                title: story.title,
                currentPage: pageIndex + 1,
                totalPages: pages.count,
                showsTitle: !story.isDavidStory,
                canGoNext: pageIndex < pages.count - 1,
                onBack: { dismiss() },
                onNext: goToNextPage
            )
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .modifier(StoryReaderLandscapeModifier())
    }

    private func goToNextPage() {
        guard pageIndex < pages.count - 1 else { return }
        pageIndex += 1
    }
}

private struct StoryReaderBackdrop: View {
    let story: BibleStory

    var body: some View {
        ZStack {
            LinearGradient(
                colors: story.isDavidStory
                    ? [Color.black, Color(hex: "#091E34"), Color.black]
                    : [story.palette.primary.opacity(0.95), story.palette.secondary.opacity(0.88), Color(hex: "#0F2238")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(story.isDavidStory ? 0.08 : 0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 32)
                .offset(x: 180, y: -220)

            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 420, height: 420)
                .blur(radius: 40)
                .offset(x: -200, y: 260)
        }
    }
}

private struct StoryReaderOverlay: View {
    let title: String
    let currentPage: Int
    let totalPages: Int
    let showsTitle: Bool
    let canGoNext: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onBack) {
                    GlassChromeButton(systemName: "chevron.left")
                }

                Spacer(minLength: 0)

                if showsTitle {
                    StoryHUDPill(text: title)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 16) {
                StoryHUDPill(text: "\(currentPage) / \(totalPages)")

                Spacer(minLength: 0)

                if canGoNext {
                    Button(action: onNext) {
                        GlassChromeButton(systemName: "arrow.right", size: 64)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
    }
}

private struct StoryHUDPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.26), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(.white.opacity(0.34), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

private struct GlassChromeButton: View {
    let systemName: String
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.32), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(3)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )

            Image(systemName: systemName)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 10)
    }
}

private struct StoryReaderPageView: View {
    let story: BibleStory
    let page: StoryPage
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        Group {
            if page.isImageOnly, let imageName = page.imageName {
                StoryImagePageView(imageName: imageName)
            } else {
                StoryTextPageView(
                    story: story,
                    page: page,
                    pageNumber: pageNumber,
                    pageCount: pageCount
                )
            }
        }
    }
}

private struct StoryImagePageView: View {
    let imageName: String

    var body: some View {
        GeometryReader { proxy in
            Group {
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "#1B2F47"), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .overlay(
                        Text(imageName)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.12), .clear, .black.opacity(0.24)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .background(Color.black)
    }
}

private struct StoryTextPageView: View {
    let story: BibleStory
    let page: StoryPage
    let pageNumber: Int
    let pageCount: Int

    private var backgroundColors: [Color] {
        [
            story.palette.primary.opacity(0.96),
            story.palette.secondary.opacity(0.9),
            Color(hex: "#10253B")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            let horizontalPadding = max(28, proxy.size.width * 0.05)
            let verticalPadding = max(24, proxy.size.height * 0.07)

            ZStack {
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: proxy.size.width * 0.42)
                    .blur(radius: 14)
                    .offset(x: proxy.size.width * 0.24, y: -proxy.size.height * 0.18)

                Circle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: proxy.size.width * 0.55)
                    .blur(radius: 28)
                    .offset(x: -proxy.size.width * 0.22, y: proxy.size.height * 0.24)

                if isWide {
                    HStack(alignment: .center, spacing: 28) {
                        storySidebar(proxy: proxy)
                        storyCard(proxy: proxy)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        storySidebar(proxy: proxy)
                        storyCard(proxy: proxy)
                    }
                    .padding(24)
                }
            }
        }
    }

    @ViewBuilder
    private func storySidebar(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(page.icon ?? story.icon)
                .font(.system(size: min(proxy.size.height * 0.18, 92)))

            Text(story.title)
                .font(.system(size: min(max(proxy.size.height * 0.052, 20), 32), weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(3)

            StoryHUDPill(text: page.reference ?? story.referenceRange)

            Spacer(minLength: 8)

            Text("Page \(pageNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .textCase(.uppercase)
        }
        .frame(maxWidth: min(max(proxy.size.width * 0.26, 220), 300), alignment: .leading)
    }

    @ViewBuilder
    private func storyCard(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(page.title)
                .font(.system(size: min(max(proxy.size.height * 0.07, 28), 40), weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            ScrollView(showsIndicators: false) {
                Text(page.body)
                    .font(.system(size: min(max(proxy.size.height * 0.042, 18), 24), weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                StoryHUDPill(text: "\(pageNumber) / \(pageCount)")

                Text("Swipe to turn the page")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.34), lineWidth: 1.2)
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
    }
}

private struct PageCurlReader<PageContent: View>: UIViewControllerRepresentable {
    let pages: [StoryPage]
    @Binding var currentIndex: Int
    let pageView: (Int, StoryPage) -> PageContent

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.isDoubleSided = false
        controller.view.backgroundColor = .clear

        context.coordinator.controllers = makeControllers()

        if let initial = context.coordinator.controllers[safe: currentIndex] ?? context.coordinator.controllers.first {
            controller.setViewControllers([initial], direction: .forward, animated: false)
        }

        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.controllers.count != pages.count {
            context.coordinator.controllers = makeControllers()
        }

        guard
            let visibleController = controller.viewControllers?.first,
            let visibleIndex = context.coordinator.index(of: visibleController),
            visibleIndex != currentIndex,
            let targetController = context.coordinator.controllers[safe: currentIndex]
        else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = currentIndex > visibleIndex ? .forward : .reverse
        controller.setViewControllers([targetController], direction: direction, animated: true)
    }

    private func makeControllers() -> [UIViewController] {
        pages.enumerated().map { index, page in
            let host = UIHostingController(rootView: pageView(index, page).ignoresSafeArea())
            host.view.backgroundColor = .clear
            return host
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlReader
        var controllers: [UIViewController] = []

        init(parent: PageCurlReader) {
            self.parent = parent
        }

        func index(of controller: UIViewController) -> Int? {
            controllers.firstIndex(where: { $0 === controller })
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController), index > 0 else { return nil }
            return controllers[index - 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController), index < controllers.count - 1 else { return nil }
            return controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard
                completed,
                let visibleController = pageViewController.viewControllers?.first,
                let index = index(of: visibleController),
                parent.currentIndex != index
            else {
                return
            }

            DispatchQueue.main.async {
                self.parent.currentIndex = index
            }
        }
    }
}

private struct StoryReaderLandscapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async {
                    lockReaderOrientation()
                }
            }
            .onDisappear {
                DispatchQueue.main.async {
                    unlockReaderOrientation()
                }
            }
    }

    private func lockReaderOrientation() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            AppDelegate.orientationLock = .landscape
            updateOrientation(.landscape)
        }
    }

    private func unlockReaderOrientation() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            AppDelegate.orientationLock = .allButUpsideDown
            updateOrientation(.portrait)
        }
    }

    private func updateOrientation(_ mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) else {
            return
        }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
        scene.windows.first(where: \.isKeyWindow)?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

private struct BibleStory: Identifiable, Hashable {
    let id: Int
    let icon: String
    let title: String
    let referenceRange: String
    let scenes: [StoryScene]
    let people: String
    let lesson: String
    let verseReference: String
    let verseQuote: String

    static let library: [BibleStory] = [
        BibleStory(
            id: 1,
            icon: "🌍",
            title: "The World's Beautiful Beginning",
            referenceRange: "Genesis 1:1-2:25",
            scenes: [
                StoryScene(title: "In the Beginning", body: "Before anything else existed, God was there. The earth was empty and dark, and deep waters covered everything. Then God began His good work of creation."),
                StoryScene(title: "Day One", body: "God said, \"Let there be light,\" and light appeared immediately. He separated light from darkness and called them day and night."),
                StoryScene(title: "Day Two", body: "God made the wide sky above the waters. It stretched over the earth like a great space where clouds would move."),
                StoryScene(title: "Day Three", body: "God gathered the waters so dry land appeared. He called the dry land earth and filled it with grass, plants, and fruit trees."),
                StoryScene(title: "Day Four", body: "God placed lights in the sky: the sun for the day, the moon for the night, and the stars. They would mark days, seasons, and years."),
                StoryScene(title: "Day Five", body: "God filled the seas with fish and every swimming creature. He filled the sky with birds and blessed them to multiply."),
                StoryScene(title: "Day Six Animals", body: "God made animals of every kind: livestock, wild animals, and small creatures that move on the ground. Creation was full of life."),
                StoryScene(title: "Day Six People", body: "Then God made people in His own image, male and female. He blessed them and gave them the task of caring for the earth."),
                StoryScene(title: "A Good Home", body: "God planted a beautiful garden and gave people food, purpose, and fellowship with Him. Everything they needed came from His generous care."),
                StoryScene(title: "Day Seven Rest", body: "After six days of creating, God rested on the seventh day. He blessed that day and made it holy as a gift of peace and worship.")
            ],
            people: "God, Adam, Eve, and all creation.",
            lesson: "God made everything with purpose and goodness, and people are made in His image to care for creation.",
            verseReference: "Genesis 1:31",
            verseQuote: "God saw everything that he had made, and, behold, it was very good."
        ),
        BibleStory(
            id: 2,
            icon: "🛶",
            title: "Noah and the Big Boat",
            referenceRange: "Genesis 6:9-9:17",
            scenes: [
                StoryScene(title: "A Faithful Man", body: "The world had become filled with violence and evil. But Noah walked with God and listened to Him."),
                StoryScene(title: "God's Warning", body: "God told Noah that a great flood was coming. He also gave Noah a plan to save his family and many animals."),
                StoryScene(title: "Build the Ark", body: "Noah built a huge ark, exactly as God commanded. It had many rooms and was covered to keep water out."),
                StoryScene(title: "Animals Arrive", body: "At God's command, animals came to Noah. Pairs of creatures entered the ark, and Noah's family came inside too."),
                StoryScene(title: "The Rain Begins", body: "Rain fell for forty days and forty nights. The waters rose higher and higher across the earth."),
                StoryScene(title: "Safe in the Ark", body: "The ark floated above the floodwaters. Even when the storm was fierce, God kept Noah and everyone with him safe."),
                StoryScene(title: "God Remembered Noah", body: "After many days, God sent a wind over the earth, and the waters began to go down."),
                StoryScene(title: "Dry Ground Appears", body: "Noah sent out birds to check the land. At last, the earth dried, and God told Noah it was time to come out."),
                StoryScene(title: "Noah Worships", body: "When Noah stepped out, he thanked God in worship. God was pleased with Noah's faithful heart."),
                StoryScene(title: "The Rainbow Promise", body: "God made a covenant and set a rainbow in the clouds. It would remind every generation of His promise.")
            ],
            people: "Noah, Noah's family, many animals, and God.",
            lesson: "Obedience and trust matter, and God's promises bring hope.",
            verseReference: "Genesis 9:13",
            verseQuote: "I set my rainbow in the cloud, and it will be a sign of a covenant between me and the earth."
        ),
        BibleStory(
            id: 3,
            icon: "🧒",
            title: "Baby Moses and the Basket",
            referenceRange: "Exodus 2:1-10",
            scenes: [
                StoryScene(title: "A Hard Time in Egypt", body: "The Israelites were living under harsh slavery in Egypt. Pharaoh gave cruel commands against Hebrew baby boys."),
                StoryScene(title: "A Baby Is Born", body: "A Levite family welcomed a beautiful baby boy. His mother saw how precious he was and hid him as long as she could."),
                StoryScene(title: "A Loving Plan", body: "When hiding him became too dangerous, she prepared a basket and placed the baby inside to keep him safe."),
                StoryScene(title: "Among the Reeds", body: "She set the basket among the reeds by the Nile River. The baby's sister watched nearby to see what would happen."),
                StoryScene(title: "The Princess Finds Him", body: "Pharaoh's daughter came to the river and saw the basket. When she opened it, she heard the baby crying."),
                StoryScene(title: "Compassion in a Palace", body: "The princess felt compassion for the child. She knew he was a Hebrew baby, but she chose mercy."),
                StoryScene(title: "A Sister Speaks Up", body: "Moses' sister bravely asked if she should find a Hebrew woman to nurse the child. The princess said yes."),
                StoryScene(title: "Mother and Son Together", body: "Moses' own mother was brought to care for him. God gave her time to love and raise him while he was small."),
                StoryScene(title: "Given a Name", body: "When the boy grew older, he was brought to Pharaoh's daughter, and she named him Moses."),
                StoryScene(title: "God's Hidden Work", body: "Even in dangerous times, God protected this child. Moses would later help lead God's people to freedom.")
            ],
            people: "Baby Moses, his mother, his sister, and Pharaoh's daughter.",
            lesson: "God protects His people and can use surprising people and places for His plan.",
            verseReference: "Exodus 2:10",
            verseQuote: "She named him Moses, and said, \"Because I drew him out of the water.\""
        ),
        BibleStory(
            id: 4,
            icon: "🌊",
            title: "Moses Parts the Red Sea",
            referenceRange: "Exodus 13:17-14:31",
            scenes: [
                StoryScene(title: "Freedom Begins", body: "After years of slavery, the Israelites left Egypt. God led them in a pillar of cloud by day and fire by night."),
                StoryScene(title: "Pharaoh Changes His Mind", body: "Pharaoh regretted letting the people go. He gathered his chariots and chased after Israel."),
                StoryScene(title: "Trapped by the Sea", body: "Israel camped near the Red Sea and saw the Egyptian army coming. The people were afraid and cried out."),
                StoryScene(title: "Moses Speaks Courage", body: "Moses told the people not to fear. He reminded them that the Lord would fight for them."),
                StoryScene(title: "God Makes a Way", body: "The angel of God and the cloud moved between Israel and Egypt. Darkness covered one side while light guided the other."),
                StoryScene(title: "Stretch Out Your Hand", body: "God told Moses to stretch out his hand over the sea. A strong east wind blew through the night."),
                StoryScene(title: "Dry Ground Through Water", body: "The waters divided, and the people walked through on dry ground. Water stood like walls on each side."),
                StoryScene(title: "The Army Follows", body: "The Egyptians followed into the sea. God confused them, and their chariot wheels struggled in the mud."),
                StoryScene(title: "Waters Return", body: "God told Moses to stretch out his hand again. The sea returned, and Israel was saved from Pharaoh's army."),
                StoryScene(title: "A Song of Praise", body: "On the other side, God's people celebrated. They praised the Lord for His mighty rescue.")
            ],
            people: "Moses, the Israelites, Pharaoh, and the Egyptian army.",
            lesson: "When we feel trapped, God is still powerful to rescue and lead us.",
            verseReference: "Exodus 14:14",
            verseQuote: "Yahweh will fight for you, and you shall be still."
        ),
        BibleStory(
            id: 5,
            icon: "🐑",
            title: "David and the Giant",
            referenceRange: "1 Samuel 17",
            scenes: [
                StoryScene(title: "Two Armies Waiting", body: "Israel and the Philistines faced each other in the Valley of Elah. Day after day, no one stepped forward."),
                StoryScene(title: "Goliath's Challenge", body: "A giant warrior named Goliath mocked Israel for forty days. His size and armor made everyone tremble."),
                StoryScene(title: "David Arrives", body: "David came from Bethlehem to bring food to his brothers. He heard Goliath's words and was shocked."),
                StoryScene(title: "A Different Kind of Courage", body: "While others focused on Goliath's strength, David focused on God's power. He could not bear to hear God dishonored."),
                StoryScene(title: "Before King Saul", body: "David told Saul he would fight. He explained how God had helped him rescue sheep from lions and bears."),
                StoryScene(title: "No Heavy Armor", body: "Saul tried to put armor on David, but it did not fit. David chose his sling and five smooth stones instead."),
                StoryScene(title: "In the Name of the Lord", body: "Goliath laughed at David, but David answered with faith. He said the battle belonged to the Lord."),
                StoryScene(title: "One Stone", body: "David ran quickly toward Goliath, placed a stone in his sling, and released it. The stone struck the giant's forehead."),
                StoryScene(title: "Goliath Falls", body: "Goliath fell to the ground, and the Philistine army fled. Israel saw that God had given victory."),
                StoryScene(title: "Faith Over Fear", body: "God used a young shepherd who trusted Him. David's courage pointed everyone back to the Lord.")
            ],
            people: "David, Goliath, King Saul, and the armies of Israel and Philistia.",
            lesson: "Faith in God is greater than size, strength, or fear.",
            verseReference: "1 Samuel 17:47",
            verseQuote: "Yahweh doesn't save with sword and spear; for the battle is Yahweh's."
        ),
        BibleStory(
            id: 6,
            icon: "🦁",
            title: "Daniel and the Lions",
            referenceRange: "Daniel 6",
            scenes: [
                StoryScene(title: "A Trusted Servant", body: "Daniel served King Darius with wisdom and honesty. The king trusted him above many other leaders."),
                StoryScene(title: "Jealous Leaders", body: "Some officials became jealous of Daniel. They searched for fault in him, but could find none."),
                StoryScene(title: "A Tricky Law", body: "They persuaded the king to sign a law: for thirty days, no one could pray to any god except the king."),
                StoryScene(title: "Daniel Keeps Praying", body: "When Daniel heard the law, he still prayed to God three times each day, as he always had."),
                StoryScene(title: "Thrown to the Lions", body: "The officials reported Daniel, and the king was forced to follow the law. Daniel was thrown into the lions' den."),
                StoryScene(title: "A Sleepless Night", body: "King Darius could not sleep. He cared about Daniel and hoped Daniel's God would rescue him."),
                StoryScene(title: "Morning at the Den", body: "At dawn, the king hurried to the den and called out with a worried voice. Daniel answered from inside."),
                StoryScene(title: "God Shut Their Mouths", body: "Daniel said God had sent His angel and shut the lions' mouths. Daniel was not harmed."),
                StoryScene(title: "Taken Out Safely", body: "Daniel was lifted out, and no wound was found on him. He had trusted in his God."),
                StoryScene(title: "A Kingdom Hears", body: "King Darius honored the God of Daniel. Daniel's faith became a witness to many people.")
            ],
            people: "Daniel, King Darius, jealous officials, and the lions.",
            lesson: "Stay faithful to God even under pressure; God is with His people.",
            verseReference: "Daniel 6:22",
            verseQuote: "My God has sent his angel, and has shut the lions' mouths, and they have not hurt me."
        ),
        BibleStory(
            id: 7,
            icon: "🐳",
            title: "Jonah and the Big Fish",
            referenceRange: "Jonah 1-4",
            scenes: [
                StoryScene(title: "God's First Call", body: "God told Jonah to go to Nineveh and warn the city. Jonah did not want to go."),
                StoryScene(title: "Running Away", body: "Instead of obeying, Jonah boarded a ship going the opposite direction. He tried to run from God's call."),
                StoryScene(title: "A Great Storm", body: "God sent a powerful storm, and the sailors were terrified. They threw cargo overboard to lighten the ship."),
                StoryScene(title: "Jonah Speaks Truth", body: "Jonah admitted he was running from the Lord. He told the sailors the storm was because of him."),
                StoryScene(title: "Into the Sea", body: "When Jonah was thrown into the sea, the storm became calm. The sailors saw God's power and feared the Lord."),
                StoryScene(title: "Inside the Fish", body: "God appointed a great fish to swallow Jonah. For three days and nights, Jonah prayed from inside it."),
                StoryScene(title: "A Prayer of Thanks", body: "Jonah cried out to God and promised to obey. He learned that salvation belongs to the Lord."),
                StoryScene(title: "A Second Chance", body: "God spoke to Jonah a second time and told him to go to Nineveh. This time Jonah obeyed."),
                StoryScene(title: "Nineveh Repents", body: "Jonah preached God's warning, and the people of Nineveh repented. From the king to the people, they turned from evil."),
                StoryScene(title: "God's Compassion", body: "God showed mercy to Nineveh, teaching Jonah that His compassion reaches people everywhere.")
            ],
            people: "Jonah, sailors, the people of Nineveh, and God.",
            lesson: "God is merciful, and He gives second chances when we turn back to Him.",
            verseReference: "Jonah 3:2",
            verseQuote: "Arise, go to Nineveh, that great city, and preach to it the message that I give you."
        ),
        BibleStory(
            id: 8,
            icon: "🌟",
            title: "The Birth of Jesus",
            referenceRange: "Luke 2:1-20; Matthew 1:18-25",
            scenes: [
                StoryScene(title: "A Promise from God", body: "God promised to send a Savior. In God's perfect time, Mary and Joseph were chosen for this holy assignment."),
                StoryScene(title: "Joseph's Dream", body: "Joseph learned in a dream that Mary's child was from the Holy Spirit. He trusted God and cared for Mary."),
                StoryScene(title: "Journey to Bethlehem", body: "A decree from Caesar made them travel to Bethlehem, the city of David. The journey was long and difficult."),
                StoryScene(title: "No Room in the Guest Room", body: "When they arrived, there was no room for them in the guest space. They stayed where animals were kept."),
                StoryScene(title: "Jesus Is Born", body: "Mary gave birth to Jesus, wrapped Him in cloths, and laid Him in a manger. The promised Savior had come."),
                StoryScene(title: "Shepherds at Night", body: "Nearby shepherds were watching their flocks in the fields. Suddenly, an angel appeared and God's glory shone around them."),
                StoryScene(title: "Good News of Great Joy", body: "The angel said, \"Do not be afraid,\" and announced that a Savior had been born in David's city."),
                StoryScene(title: "Heavenly Praise", body: "A great multitude of angels praised God, saying, \"Glory to God in the highest, and on earth peace.\""),
                StoryScene(title: "The Shepherds Hurry", body: "The shepherds hurried to Bethlehem and found Mary, Joseph, and baby Jesus exactly as the angel said."),
                StoryScene(title: "News Shared Everywhere", body: "The shepherds told others what they had seen and heard. Mary treasured these things in her heart.")
            ],
            people: "Mary, Joseph, baby Jesus, angels, and shepherds.",
            lesson: "Jesus is God's promised Savior, and His coming is good news for everyone.",
            verseReference: "Luke 2:11",
            verseQuote: "For there is born to you today, in David's city, a Savior, who is Christ the Lord."
        ),
        BibleStory(
            id: 9,
            icon: "🌊",
            title: "Jesus Calms the Storm",
            referenceRange: "Mark 4:35-41",
            scenes: [
                StoryScene(title: "After a Long Day", body: "Jesus had spent the day teaching large crowds by the sea. When evening came, He told His disciples to cross to the other side."),
                StoryScene(title: "Setting Sail", body: "The disciples took Jesus in the boat just as He was. Other small boats followed nearby."),
                StoryScene(title: "A Violent Storm", body: "A fierce windstorm suddenly rose. Waves crashed into the boat until it began filling with water."),
                StoryScene(title: "Fear in the Boat", body: "The disciples worked hard but could not control the storm. Their fear grew as the wind roared."),
                StoryScene(title: "Jesus Is Asleep", body: "Jesus was in the stern, asleep on a cushion. Even in the storm, He was at peace."),
                StoryScene(title: "A Cry for Help", body: "The disciples woke Him and cried, \"Teacher, do you not care that we are dying?\""),
                StoryScene(title: "Peace! Be Still!", body: "Jesus stood and rebuked the wind. He said to the sea, \"Peace! Be still!\""),
                StoryScene(title: "Great Calm", body: "At once the wind stopped, and the sea became calm. The danger that frightened them disappeared."),
                StoryScene(title: "A Question of Faith", body: "Jesus asked, \"Why are you so afraid? How is it that you have no faith?\""),
                StoryScene(title: "Who Is This?", body: "The disciples were filled with awe. They asked one another who Jesus is, because even wind and waves obey Him.")
            ],
            people: "Jesus and His disciples.",
            lesson: "Jesus has power over creation, and we can trust Him in fear.",
            verseReference: "Mark 4:39",
            verseQuote: "He said to the sea, \"Peace! Be still!\" The wind ceased, and there was a great calm."
        ),
        BibleStory(
            id: 10,
            icon: "✝️",
            title: "The Good Samaritan",
            referenceRange: "Luke 10:25-37",
            scenes: [
                StoryScene(title: "A Big Question", body: "A law expert asked Jesus what he must do to inherit eternal life. Jesus asked what the Law says."),
                StoryScene(title: "Love God and Neighbor", body: "The man answered: love God with all your heart, soul, strength, and mind, and love your neighbor as yourself."),
                StoryScene(title: "Who Is My Neighbor?", body: "Wanting to justify himself, the man asked Jesus, \"Who is my neighbor?\" Jesus answered with a story."),
                StoryScene(title: "A Dangerous Road", body: "A man was traveling from Jerusalem to Jericho. Robbers attacked him, took his things, beat him, and left him half dead."),
                StoryScene(title: "A Priest Passes By", body: "A priest came along that road and saw the injured man. He passed by on the other side."),
                StoryScene(title: "A Levite Passes By", body: "A Levite also came, looked, and kept going. The injured man was still alone and hurting."),
                StoryScene(title: "A Samaritan Stops", body: "Then a Samaritan came by and felt compassion. He did not ignore the wounded man."),
                StoryScene(title: "Mercy in Action", body: "The Samaritan cleaned and bandaged the man's wounds with oil and wine. He lifted him onto his own animal."),
                StoryScene(title: "Care at the Inn", body: "He brought the man to an inn and cared for him. The next day he paid for the man's needs and promised to return."),
                StoryScene(title: "Go and Do Likewise", body: "Jesus asked who was a true neighbor. The answer was clear: the one who showed mercy.")
            ],
            people: "Jesus, a wounded traveler, a priest, a Levite, a Samaritan, and an innkeeper.",
            lesson: "Love your neighbor with action, even when helping is costly or inconvenient.",
            verseReference: "Luke 10:37",
            verseQuote: "Go and do likewise."
        )
    ]
}

private struct StoryScene: Hashable {
    let title: String
    let body: String
}

private struct StoryPage: Hashable {
    let title: String
    let body: String
    let icon: String?
    let reference: String?
    let imageName: String?
    let isImageOnly: Bool

    init(title: String,
         body: String,
         icon: String?,
         reference: String?,
         imageName: String? = nil,
         isImageOnly: Bool = false) {
        self.title = title
        self.body = body
        self.icon = icon
        self.reference = reference
        self.imageName = imageName
        self.isImageOnly = isImageOnly
    }
}

private struct StoryCoverPalette {
    let primary: Color
    let secondary: Color

    static let all: [StoryCoverPalette] = [
        StoryCoverPalette(primary: Color(hex: "#2C7CF6"), secondary: Color(hex: "#66A7FF")),
        StoryCoverPalette(primary: Color(hex: "#8C63E6"), secondary: Color(hex: "#B088FF")),
        StoryCoverPalette(primary: Color(hex: "#22A060"), secondary: Color(hex: "#54C989")),
        StoryCoverPalette(primary: Color(hex: "#FF8A3C"), secondary: Color(hex: "#FFB36B")),
        StoryCoverPalette(primary: Color(hex: "#4C78D5"), secondary: Color(hex: "#7AA2F4"))
    ]
}

private extension BibleStory {
    var isDavidStory: Bool {
        id == 5
    }

    var palette: StoryCoverPalette {
        StoryCoverPalette.all[(id - 1) % StoryCoverPalette.all.count]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
