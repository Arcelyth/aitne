using @dom {type Html, div, h1, text, link, nav, hr}

pub fn app_layout(outlet : Html) -> Html {
  div().children([
    nav().children([
      link("/", text("Home page")),
      text(" | "),
      link("/about", text("about us")),
      text(" | "),
      link("/some/broken/path", text("Test 404")),
    ]),
    hr(),
    div().children([outlet]), 
  ])
}

pub fn home_view() -> Html {
  h1().children([text("Home Page !!!!!")])
}

pub fn about_view() -> Html {
  h1().children([text("About us.")])
}

pub fn not_found_view() -> Html {
  h1().children([text("404 - Nothing here.")])
}
