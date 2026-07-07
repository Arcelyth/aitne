///|
using @dom {
  trait View,
  text,
  anchor,
  router,
  routes,
  route,
  parent_route,
  outlet,
}

///|
pub fn app() -> &View {
  router(base="/", children=[
    routes(fallback=() => not_found(), children=[
      route(view=() => home(), path="/"),
      parent_route(view=() => users_page(), path="/users", children=[
        route(view=() => user_detail_page(), path="/:id"),
      ]),
      parent_route(view=() => try_page(), path="/t", children=[
        route(view=() => try_page(), path="/t1"),
      ]),
    ]),
  ])
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
