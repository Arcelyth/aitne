///|
pub fn anchor(href : String, children : Array[&View]) -> &View {
  fn inner(href : Memo[String], children : Array[&View]) -> &View {
    // TODO 
    a().attr("href", href.get()).children(children)
  }
  let h_memo = use_resolved_path(href)
  inner(h_memo, children)
}

///|
pub fn use_resolved_path(path : String) -> Memo[String] {

  // TODO: match
  Memo::new(_ => {
    if path.has_prefix("/") {
      path
    } else {
      path
    }
  })
}
