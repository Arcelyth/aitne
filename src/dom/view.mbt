/////|
//pub struct View[T](T)
//
/////|
//pub fn[T] View::new(inner : T) -> View[T] {
//  View(inner)
//}
//
/////|
//pub fn[T] View::inner(self : View[T]) -> T {
//  self.0
//}
//
/////|
//pub trait IntoView : Render + RenderHtml {
//  fn[T] into_view(Self) -> View[T] 
//}
//``
/////|
//pub impl[T : Render] Render for View[T] with build(self) -> RenderState {
//  self.0.build() 
//}
//
/////|
//pub impl[T : Render] Render for View[T] with rebuild(self, state: Ref[RenderState]) -> Unit {
//  self.0.rebuild(state) 
//}
//
/////|
//pub impl[T : RenderHtml] RenderHtml for View[T] with html_len(self) -> Int {
//  self.0.html_len()
//}
//
/////|
//pub impl[T : RenderHtml] RenderHtml for View[T] with to_html_with_buf(self, buf : StringBuilder, pos : Ref[Position]) -> Unit {
//  self.0.to_html_with_buf(buf, pos)
//}
//
//pub impl[T : ElementType, A : Attribute, C : Render + RenderHtml] IntoView for HtmlElement[T, A, C] with into_view(self) -> View[HtmlElement[T, A, C]] {
//  View::new(self)
//}
//
//pub impl IntoView for TextNode with into_view(self) -> View[TextNode] {
//  View::new(self)
//}
//
//pub impl IntoView for DynTextNode with into_view(self) -> View[DynTextNode] {
//  View::new(self)
//}
//
pub trait View : Render + RenderHtml {
}

pub impl[T : ElementType, A : Attribute, C : Render + RenderHtml] View for HtmlElement[T, A, C] 

pub impl View for TextNode  
pub impl View for DynTextNode  
