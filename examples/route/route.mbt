///|
pub fn not_found() -> &View {
  div().children([text("NOT FOUND !!!!!!")])
}

///|
pub fn try_page() -> &View {
  div().children([text("This is try page !!!!!!")])
}

///|
pub fn home() -> &View {
  div()
  .children([
    anchor(href="/", children=[text("Home")]),
    anchor(href="/users", children=[text("Users")]),
    anchor(href="/users/1", children=[text("User #1")]),
    anchor(href="/try", children=[text("TRY")]),
    anchor(href="/about", children=[text("404 Demo")]),
    anchor(href="/xyz", children=[text("Also 404")]),
    anchor(href="/t/t1", children=[text("t1")]),
    anchor(href="/t/t2", children=[text("t2")]),
  ])
  .style("display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;")
}

///|
pub fn users_page() -> &View {
  div()
  .children([
    h2().children([text("Users Overview")]),
    p().children([text("Please select a user to view details:")]),
    ul().children([
      li().children([anchor(href="/users/1", children=[text("User #1 (Alice)")])]),
      li().children([anchor(href="/users/2", children=[text("User #2 (Bob)")])]),
      li().children([anchor(href="/users/3", children=[text("User #3 (Charlie)")])]),
    ]),
    outlet(),
  ])
  .style("padding: 1rem; border: 1px solid #eee; margin-top: 1rem;")
}

///|
pub fn user_detail_page() -> &View {
  div()
  .children([
    h3().children([text("User Profile Detail")]),
    p().children([text("Successfully loaded user data via context parameters.")]),
    div()
    .children([anchor(href="/users", children=[text("← Back to Users List")])])
    .style("margin-top: 1rem;"),
  ])
  .style(
    "padding: 1rem; background-color: #f9f9f9; border-radius: 4px; margin-top: 1rem;",
  )
}
