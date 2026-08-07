///|
let __tmpl_cache_0 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
let __tmpl_cache_1 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
pub fn not_found() -> &View {
  let __tmpl_0 = match __tmpl_cache_0.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(_t, "<div>NOT FOUND !!!!!!</div>")
      __tmpl_cache_0.val = Some(_t)
      _t
    }
  }
  let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(__tmpl_0)
  let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_frag),
  )
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}

///|
pub fn try_page() -> &View {
  let __tmpl_1 = match __tmpl_cache_1.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div>This is try page !!!!!!</div>",
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

///|
pub fn home() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    anchor(href="/", children=[text("Home")]),
    anchor(href="/users", children=[text("Users")]),
    anchor(href="/users/1", children=[text("User #1")]),
    anchor(href="/try", children=[text("TRY")]),
    anchor(href="/about", children=[text("404 Demo")]),
    anchor(href="/xyz", children=[text("Also 404")]),
    anchor(href="/t/t1", children=[text("t1")]),
    anchor(href="/t/t2", children=[text("t2")]),
  ]).attr(
    "style", "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;",
  )
}

///|
pub fn users_page() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h2(children=["Users Overview"]),
    @Arcelyth/aitne/src/dom.p(children=["Please select a user to view details:"]),
    @Arcelyth/aitne/src/dom.ul(children=[
      @Arcelyth/aitne/src/dom.li(children=[
        anchor(href="/users/1", children=[text("User #1 (Alice)")]),
      ]),
      @Arcelyth/aitne/src/dom.li(children=[
        anchor(href="/users/2", children=[text("User #2 (Bob)")]),
      ]),
      @Arcelyth/aitne/src/dom.li(children=[
        anchor(href="/users/3", children=[text("User #3 (Charlie)")]),
      ]),
    ]),
    outlet(),
  ]).attr("style", "padding: 1rem; border: 1px solid #eee; margin-top: 1rem;")
}

///|
pub fn user_detail_page() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h3(children=["User Profile Detail"]),
    @Arcelyth/aitne/src/dom.p(children=[
      "Successfully loaded user data via context parameters.",
    ]),
    @Arcelyth/aitne/src/dom.div(children=[
      anchor(href="/users", children=[text("← Back to Users List")]),
    ]).attr("style", "margin-top: 1rem;"),
  ]).attr(
    "style", "padding: 1rem; background-color: #f9f9f9; border-radius: 4px; margin-top: 1rem;",
  )
}
