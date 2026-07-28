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
      route(path="/", view=() => home()),
      parent_route(path="/users", view=() => users_page(), children=[
        route(path="/:id", view=() => user_detail_page()),
      ]),
      parent_route(path="/t", view=() => try_page(), children=[
        route(path="/t1", view=() => try_page()),
      ]),
    ]),
  ])
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
