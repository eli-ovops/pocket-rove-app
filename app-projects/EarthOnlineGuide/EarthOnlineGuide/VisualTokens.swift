import SwiftUI
import UIKit

// Primitive → semantic → component tokens. System fonts are the centralized, scalable fallback for this local test build.
enum EarthPalette {
    static let sun = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let sky = Color(red: 0.33, green: 0.82, blue: 0.88)
    static let mint = Color(red: 0.64, green: 0.93, blue: 0.79)
    static let ivory = Color(red: 1.0, green: 0.98, blue: 0.88)
    static let deepTeal = Color(red: 0.04, green: 0.30, blue: 0.34)
    static let teal = Color(red: 0.08, green: 0.57, blue: 0.61)
    static let core = Color(red: 0.18, green: 0.66, blue: 0.41)
    static let egg = Color(red: 0.92, green: 0.61, blue: 0.13)
}

enum EarthTheme {
    static let pageText = EarthPalette.deepTeal
    static let surface = EarthPalette.ivory
    static let outline = EarthPalette.deepTeal
    static let accent = EarthPalette.teal
    static let background = LinearGradient(colors: [EarthPalette.sky, EarthPalette.mint], startPoint: .top, endPoint: .bottom)
}

enum EarthComponent {
    static let cornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 14
    static let outlineWidth: CGFloat = 2
    static let shadow = Color.black.opacity(0.16)
    static let pagePadding: CGFloat = 18
    static let cardPadding: CGFloat = 16
}

enum FontToken {
    static let embeddedPixelFontName: String? = nil
    static let taskTitle: Font = .body.weight(.semibold)
    static let button: Font = .headline.weight(.bold)
    static let label: Font = .subheadline.weight(.semibold)
    static let dateTime: Font = .caption.monospacedDigit()
    static let pageTitle: Font = .title.weight(.heavy)
}

struct TravelWorldBackground: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        ZStack {
            EarthTheme.background.ignoresSafeArea()
            if !dynamicTypeSize.isAccessibilitySize {
                Circle().fill(EarthPalette.sun.opacity(0.9)).frame(width: 160, height: 160).offset(x: 125, y: -310)
                CloudShape().fill(.white.opacity(0.72)).frame(width: 114, height: 46).offset(x: -116, y: -255)
                CloudShape().fill(.white.opacity(0.5)).frame(width: 85, height: 34).offset(x: 110, y: -80)
                Image(systemName: "sparkles").font(.title2).foregroundStyle(.white.opacity(0.7)).offset(x: -130, y: 120)
            }
        }.accessibilityHidden(true)
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), cornerSize: CGSize(width: rect.height / 2, height: rect.height / 2))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.15, y: rect.minY, width: rect.width * 0.37, height: rect.height * 0.75))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.1, width: rect.width * 0.38, height: rect.height * 0.68))
        return path
    }
}

struct IvoryPanel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(EarthComponent.cardPadding).foregroundStyle(EarthTheme.pageText)
            .background {
                RoundedRectangle(cornerRadius: EarthComponent.cornerRadius, style: .continuous)
                    .fill(EarthTheme.surface.opacity(0.98))
                    .shadow(color: EarthComponent.shadow, radius: 0, x: 3, y: 4)
            }
            .overlay(RoundedRectangle(cornerRadius: EarthComponent.cornerRadius, style: .continuous).stroke(EarthTheme.outline, lineWidth: EarthComponent.outlineWidth))
    }
}

struct PixelTravelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(FontToken.button).foregroundStyle(EarthTheme.pageText).padding(.vertical, 13).frame(maxWidth: .infinity)
            .background(EarthPalette.sun, in: RoundedRectangle(cornerRadius: EarthComponent.compactCornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: EarthComponent.compactCornerRadius, style: .continuous).stroke(EarthTheme.outline, lineWidth: EarthComponent.outlineWidth))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct SectionStamp: View {
    let title: String; let subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(FontToken.pageTitle).foregroundStyle(EarthTheme.pageText); Text(subtitle).font(FontToken.label).foregroundStyle(EarthTheme.pageText.opacity(0.78)) }.accessibilityElement(children: .combine) }
}

enum GenericTaskIconKey {
    static let all = ["action", "organizing", "health", "observation", "record", "outdoors", "interaction", "easter-egg"]
    static func key(canonicalTaskID: String, type: String) -> String { if type == "egg" { return "easter-egg" }; let value = canonicalTaskID.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }; return Array(all.dropLast())[Int(value % UInt64(all.count - 1))] }
}

struct GenericTaskIconView: View {
    let iconKey: String; var size: CGFloat = 30
    private var index: Int { GenericTaskIconKey.all.firstIndex(of: iconKey) ?? 0 }
    var body: some View { SpriteIconImage(index: index).frame(width: size, height: size).accessibilityHidden(true) }
}

struct TaskTypeBadgeView: View {
    let type: String; var size: CGFloat = 22
    var body: some View { AssetImage(asset: type == "egg" ? .eggBadge : .coreBadge).frame(width: size, height: size).accessibilityHidden(true) }
}

enum VisualAsset: String {
    case earth = "earth-guide-mark-v2", airplane = "airplane-sticker-v2", camera = "camera-sticker-v2", suitcase = "suitcase-sticker-v2"
    case coreFrame = "core-task-card-frame-v2", eggFrame = "egg-task-card-frame-v2", icons = "generic-task-icons-v1", coreBadge = "core-task-type-badge-v1", eggBadge = "egg-task-type-badge-v1"
    // Alpha-bbox coordinates measured from the immutable source PNGs.
    var crop: CGRect { switch self {
    case .earth: return CGRect(x: 211/1254, y: 217/1254, width: 848/1254, height: 806/1254)
    case .airplane: return CGRect(x: 145/1239, y: 224/1270, width: 969/1239, height: 800/1270)
    case .camera: return CGRect(x: 197/1402, y: 155/1122, width: 961/1402, height: 734/1122)
    case .suitcase: return CGRect(x: 301/1254, y: 169/1254, width: 702/1254, height: 885/1254)
    case .coreBadge: return CGRect(x: 405/1254, y: 350/1254, width: 517/1254, height: 515/1254)
    case .eggBadge: return CGRect(x: 412/1254, y: 335/1254, width: 416/1254, height: 533/1254)
    default: return .zero
    } }
}

struct AssetImage: View {
    let asset: VisualAsset
    var body: some View {
        Group {
            if let image = load(asset) { Image(uiImage: image).resizable().scaledToFit() }
            else { Color.clear }
        }
    }
    private func load(_ asset: VisualAsset) -> UIImage? {
        guard let url = Bundle.main.url(forResource: asset.rawValue, withExtension: "png"), let source = UIImage(contentsOfFile: url.path), let cg = source.cgImage else {
#if DEBUG
            print("EARTH_GUIDE_ASSET_LOAD_FAILED \(asset.rawValue)")
#endif
            return nil
        }
        let rect = asset.crop == .zero ? CGRect(x: 0, y: 0, width: cg.width, height: cg.height) : CGRect(x: asset.crop.minX * CGFloat(cg.width), y: asset.crop.minY * CGFloat(cg.height), width: asset.crop.width * CGFloat(cg.width), height: asset.crop.height * CGFloat(cg.height)).integral
        guard let cropped = cg.cropping(to: rect) else { return source }
        return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
    }
}

struct SpriteIconImage: View {
    let index: Int
    var body: some View { Group { if let image = load() { Image(uiImage: image).resizable().interpolation(.none).scaledToFit() } else { Color.clear } } }
    private func load() -> UIImage? {
        guard let url = Bundle.main.url(forResource: VisualAsset.icons.rawValue, withExtension: "png"), let source = UIImage(contentsOfFile: url.path), let cg = source.cgImage else { return nil }
        let cellW = cg.width / 4, cellH = cg.height / 2
        let rect = CGRect(x: (index % 4) * cellW, y: (index / 4) * cellH, width: cellW, height: cellH)
        guard let cropped = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
    }
}
