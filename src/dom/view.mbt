///|
/// A `View` is anything that can be both rendered to DOM nodes
/// and serialized to HTML (for SSR / static generation).
pub trait View: Render + RenderHtml {
  fn style(Self, s : &IntoStyle) -> &View
}

///|
/// HtmlElement implements View when its children implement both Render and RenderHtml.
pub impl[T : ElementType, C : Render + RenderHtml] View for HtmlElement[T, C] with fn style(
  self,
  s : &IntoStyle,
) -> &View {
  self.style(s)
}

///|
/// Text nodes implement View.
pub impl View for TextNode with fn style(self, _i) -> &View {
  self
}

///|
/// Dynamic text nodes implement View.
pub impl View for DynTextNode with fn style(self, _i) -> &View {
  self
}

///|
/// ForNode (dynamic list) implements View.
pub impl[T, K : Hash + Eq] View for ForNode[T, K] with fn style(self, _s) -> &View {
  self
}

///|
pub impl View for Unit with fn style(_self, _i) -> &View {
  ()
}
