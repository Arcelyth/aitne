///|
let __tmpl_cache_0 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
using @dom {trait View}

///|
fn app() -> &View {
  let (selected, set_selected) = @reactive.create_signal(false)

  let __tmpl_0 = match __tmpl_cache_0.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div><button>\n      &quot;toggle&quot;\n    </button><div><!></div></div>",
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
  let _n1 = @Arcelyth/aitne/src/ffi.prim_next_sibling(
    @Arcelyth/aitne/src/ffi.prim_first_child(
      @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
    ),
  )
  let _n2 = @Arcelyth/aitne/src/ffi.prim_first_child(
    @Arcelyth/aitne/src/ffi.prim_next_sibling(
      @Arcelyth/aitne/src/ffi.prim_first_child(
        @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
      ),
    ),
  )
  let _ = @Arcelyth/aitne/src/dom.add_event_listener(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
    "click",
    _ => set_selected.set(!selected.get()),
  )
  let _ = @reactive.Effect::new(fn(_) {
    @Arcelyth/aitne/src/ffi.dom_set_attr(
      @Arcelyth/aitne/src/ffi.cast_node_to_element(_n1),
      "class",
      (() => if selected.get() { "danger" } else { "" })(),
    )
  })
  let _t_parent = @Arcelyth/aitne/src/ffi.dom_parent(_n2)
  let _t_text = @Arcelyth/aitne/src/ffi.prim_create_text_node(
    @Arcelyth/aitne/src/dom.document(),
    (() => if selected.get() { "selected" } else { "normal" })(),
  )
  @Arcelyth/aitne/src/ffi.dom_insert_before(
    _t_parent,
    @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text),
    _n2,
  )
  @Arcelyth/aitne/src/ffi.dom_remove(_n2)
  let _ = @reactive.Effect::new(fn(_) {
    @Arcelyth/aitne/src/ffi.dom_set_text(
      @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text),
      (() => if selected.get() { "selected" } else { "normal" })(),
    )
  })
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
