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
pub fn[V : ToTemplate] TemplateView::get_template(
  _self : TemplateView[V],
) -> TemplateElement {
  let id = V::type_id()
  match templates_cache.get(id) {
    Some(tpl) => tpl
    None => {
      let tpl = @ffi.clone_node_shallow(get_base_template())

      let buf = StringBuilder::new()
      V::to_template(buf)
      @ffi.set_inner_html(tpl, buf.to_string())

      templates_cache.set(id, tpl)
      tpl
    }
  }
}

///|
pub fn[V : View + ToTemplate] TemplateView::new(view : V) -> TemplateView[V] {
  TemplateView(view)
}

///|
pub impl[V : View + ToTemplate] Render for TemplateView[V] with fn build(
  _self : TemplateView[V],
) -> RenderState {
  // TODO
  RenderState::None
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

///|
pub fn clone_template(tpl : TemplateElement) -> Element {
  @ffi.clone_template_content(tpl)
}
