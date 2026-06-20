///|
using @dom {
  trait View,
  div,
  h2,
  h3,
  p,
  text,
  ul,
  li,
  anchor,
  router,
  routes,
  route,
  parent_route,
}

///|
pub fn app() -> &View {
  router(
    routes(() => not_found(), [
      route("/", () => home()).child(
        parent_route(
          "/users",
          () => users_page(),
          route("/:id", () => user_detail_page()),
        ),
      ),
      route("/try", () => try_page()),
    ]),
    base=Some(""),
  )
}


///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
