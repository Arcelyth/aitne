using @dom { type Route, type RouterBuilder,  mount_router, dom_get_body}

fn main {
  let routes = [
    Route::parent("/", app_layout, [
      Route::new("", home_view),
      Route::new("about", about_view),
    ])
  ]

  let builder = RouterBuilder::{
    routes: routes,
    fallback: not_found_view,
  }

  let _ = mount_router(dom_get_body(), None, builder)
}
