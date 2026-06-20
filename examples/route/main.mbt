using @dom {router, routes, route, parent_route}

pub fn app() -> &View {
  router(
    routes(
      () => not_found_page(),
      route("/", () => home_page()).child(
        parent_route(
          "/users",
          () => users_page(),
          route("/:id", () => user_detail_page()),
        ),
      ),
    ),
    base=Some(""),
  )
}


fn main {
  let _ = @dom.mount_to_body(() => app())
}
