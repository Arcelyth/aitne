///|
using @ffi {type TemplateElement, type Element}

///|
using @hashmap {type HashMap}

///|
pub(open) trait ToTemplate {
  fn type_id() -> String
  fn to_template(StringBuilder) -> Unit
}

///|
let base_template_element : Ref[TemplateElement?] = { val: None }

///|
let templates_cache : HashMap[String, TemplateElement] = HashMap([])

///|
pub(all) struct TemplateView[V](V)

///|
fn get_base_template() -> TemplateElement {
  match base_template_element.val {
    Some(tpl) => tpl
    None => {
      let tpl = @ffi.create_template()
      base_template_element.val = Some(tpl)
      tpl
    }
  }
}

///|
pub fn[V] TemplateView::new(view : V) -> TemplateView[V] {
  TemplateView(view)
}

///|
pub impl[V : View + ToTemplate] Render for TemplateView[V] with fn build(
  self : TemplateView[V],
) -> RenderState {
  let tpl = get_template(self.0)
  let content = clone_template(tpl)
  RenderHtml::hydrate(
    self.0,
    Cursor::new(@ffi.cast_element_to_node(content)),
    PositionState::default(),
  )
}

///|
pub impl[V : View + ToTemplate] Render for TemplateView[V] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  Render::rebuild(self.0, state)
}

///|
pub impl[V : View + ToTemplate] RenderHtml for TemplateView[V] with fn html_len(
  self,
) -> Int {
  RenderHtml::html_len(self.0)
}

///|
pub impl[V : View + ToTemplate] RenderHtml for TemplateView[V] with fn hydrate(
  self,
  cursor : Cursor,
  pos : PositionState,
) -> RenderState {
  RenderHtml::hydrate(self.0, cursor, pos)
}

///|
pub impl[V : View + ToTemplate] RenderHtml for TemplateView[V] with fn to_html_with_buf(
  self,
  buf,
  position,
) -> Unit {
  RenderHtml::to_html_with_buf(self.0, buf, position)
}
