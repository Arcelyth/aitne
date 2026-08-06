///|
let __tmpl_cache_0 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
using @dom {trait View}

///|
fn app() -> &View {
  let (count, set_count) = @reactive.create_signal(0)

  @reactive.create_effect(_ => println("Value: \{count.get()}"))

  let __tmpl_0 = match __tmpl_cache_0.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div><h1>Counter</h1><p><!></p><button>\n      +1\n    </button><button>\n      -1\n    </button></div>",
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
    @Arcelyth/aitne/src/ffi.prim_next_sibling(
      @Arcelyth/aitne/src/ffi.prim_first_child(
        @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
      ),
    ),
  )
  let _n1 = @Arcelyth/aitne/src/ffi.prim_next_sibling(
    @Arcelyth/aitne/src/ffi.prim_next_sibling(
      @Arcelyth/aitne/src/ffi.prim_first_child(
        @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
      ),
    ),
  )
  let _n2 = @Arcelyth/aitne/src/ffi.prim_next_sibling(
    @Arcelyth/aitne/src/ffi.prim_next_sibling(
      @Arcelyth/aitne/src/ffi.prim_next_sibling(
        @Arcelyth/aitne/src/ffi.prim_first_child(
          @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
        ),
      ),
    ),
  )
  let _t_parent = @Arcelyth/aitne/src/ffi.dom_parent(_n0)
  let _t_text = @Arcelyth/aitne/src/ffi.prim_create_text_node(
    @Arcelyth/aitne/src/dom.document(),
    (() => count.get().to_string())(),
  )
  @Arcelyth/aitne/src/ffi.dom_insert_before(
    _t_parent,
    @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text),
    _n0,
  )
  @Arcelyth/aitne/src/ffi.dom_remove(_n0)
  let _ = @reactive.Effect::new(fn(_) {
    @Arcelyth/aitne/src/ffi.dom_set_text(
      @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text),
      (() => count.get().to_string())(),
    )
  })
  let _ = @Arcelyth/aitne/src/dom.add_event_listener(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n1),
    "click",
    _ => set_count.update(v => v + 1),
  )
  let _ = @Arcelyth/aitne/src/dom.add_event_listener(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n2),
    "click",
    _ => set_count.update(v => v - 1),
  )
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
