///|
/// A `View` is anything that can be both rendered to DOM nodes
/// and serialized to HTML (for SSR / static generation).
pub trait View: Render + RenderHtml {
  fn style(Self, s : &IntoStyle) -> &View
}

///|
pub impl View for Unit with fn style(_self, _i) -> &View {
  ()
}

///|
/// String -> View
pub impl View for String with fn style(self, _s : &IntoStyle) -> &View {
  text(self)
}
