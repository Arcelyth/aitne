///|
let __tmpl_cache_0 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
let __tmpl_cache_1 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
using @dom {trait View}

///|
pub fn page() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.div(children=[
      header_section(),
      interactive_section(),
      footer_section(),
    ]).attr(
      "style", "max-width: 28rem; width: 100%; background-color: #1e293b; border-radius: 1rem; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); border: 1px solid #334155; padding: 2rem;",
    ),
  ]).class("page")
}

///|
fn header_section() -> &View {
  let title = "Aitne"
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h1(children=[title]).attr(
      "style", "font-size: 2.25rem; font-weight: 800; background: linear-gradient(to right, #2dd4bf, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 0 0 0.75rem 0; tracking-content: -0.025em;",
    ),
    @Arcelyth/aitne/src/dom.p(children=[
      "Build lightweight, high-performance reactive web application.",
    ]).attr(
      "style", "color: #94a3b8; font-size: 0.875rem; margin: 0; line-height: 1.5;",
    ),
  ]).class("header_section")
}

///|
fn interactive_section() -> &View {
  let __tmpl_0 = match __tmpl_cache_0.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div class=\"interactive_section\"><button style=\"padding: 0.75rem 1.5rem; width: 100%; background-color: #2563eb; color: #ffffff; font-weight: 600; border-radius: 0.75rem; border: none; cursor: pointer; box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.4); font-size: 1rem; transition: background-color 0.2s;\">\n      Start\n    </button></div>",
      )
      __tmpl_cache_0.val = Some(_t)
      _t
    }
  }
  let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(__tmpl_0)
  let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_frag),
  )
  let _n0 = @Arcelyth/aitne/src/ffi.prim_first_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
  let _ = @Arcelyth/aitne/src/dom.add_event_listener(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
    "click",
    fn(_ev) { println("Clicked") },
  )
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}

///|
fn footer_section() -> &View {
  let __tmpl_1 = match __tmpl_cache_1.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div class=\"footer_section\"><a href=\"#\" style=\"color: #64748b; font-size: 0.875rem; text-decoration: none;\">\n      document\n    </a></div>",
      )
      __tmpl_cache_1.val = Some(_t)
      _t
    }
  }
  let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(__tmpl_1)
  let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_frag),
  )
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}
