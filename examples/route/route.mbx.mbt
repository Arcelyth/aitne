///|
pub fn not_found() -> &View {
  @Arcelyth/aitne/src/dom.div(children=["NOT FOUND !!!!!!"])
}

///|
pub fn try_page() -> &View {
  @Arcelyth/aitne/src/dom.div(children=["This is try page !!!!!!"])
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
