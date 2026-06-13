///|
pub struct View[T](T)

///|
pub fn[T] View::new(inner : T) -> View[T] {
  View(inner)
}

///|
pub fn[T] View::inner(self : View[T]) -> T {
  self.0
}

///|
pub trait IntoView : Render + RenderHtml {
  fn into_view(Self) -> View[Self] 
}

///|
pub impl[T : Render] Render for View[T] with build(self) -> RenderState {
  self.0.build() 
}

///|
pub impl[T : Render] Render for View[T] with rebuild(self, state: Ref[RenderState]) -> Unit {
  self.0.rebuild(state) 
}

///|
pub impl[T : RenderHtml] RenderHtml for View[T] with html_len(self) -> Int {
  self.0.html_len()
}

///|
pub impl[T : RenderHtml] RenderHtml for View[T] with to_html_with_buf(self, buf : StringBuilder, pos : Ref[Position]) -> Unit {
  self.0.to_html_with_buf(buf, pos)
}

