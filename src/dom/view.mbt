///|
/// A `View` is anything that can be both rendered to DOM nodes
/// and serialized to HTML (for SSR / static generation).
pub trait View: Render + RenderHtml {}

///|
/// HtmlElement implements View when its children implement both Render and RenderHtml.
pub impl[T : ElementType, C : Render + RenderHtml] View for HtmlElement[T, C]

///|
/// Text nodes implement View.
pub impl View for TextNode

///|
/// Dynamic text nodes implement View.
pub impl View for DynTextNode

///|
/// ForNode (dynamic list) implements View.
pub impl[T, K : Hash + Eq] View for ForNode[T, K]

