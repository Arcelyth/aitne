///|
pub fn anchor(href : String, children : Array[&View]) -> &View {
  fn inner(href : Memo[String], children : Array[&View]) -> &View {
    let rctx : RouterContext? = use_context()
    let ctx = match rctx {
      Some(c) => c
      None => {
        println("[Error] tried to use link_to outside the range of router")
        panic()
      }
    }
    // TODO: for aria
    let _is_active = () => {
      let p = normalize_path(href.get())
      ctx.current_url.with_val(loc => loc.path == p)
    }
    // TODO 
    a().attr("href", href.get()).children(children)
  }
  let h_memo = use_resolved_path(href)
  inner(h_memo, children)
}

///|
pub(all) struct Matched(Memo[String])

///|
pub impl TypeName for Matched with fn get_ty() {
  "Matched"
}
