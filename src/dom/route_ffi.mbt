///|
pub extern "js" fn current_origin() -> String =
  #|() => location.origin

///|
pub extern "js" fn current_pathname() -> String =
  #|() => location.pathname

///|
pub extern "js" fn current_search() -> String =
  #|() => location.search

///|
pub extern "js" fn current_hash() -> String =
  #|() => location.hash

///|
pub extern "js" fn history_push_state(url : String) -> Unit =
  #|(url) => { history.pushState(null, "", url); }

///|
pub extern "js" fn history_replace_state(url : String) -> Unit =
  #|(url) => { history.replaceState(null, "", url); }

///|
pub extern "js" fn on_popstate(cb : () -> Unit) -> () -> Unit =
  #|(cb) => {
  #|  const f = () => cb();
  #|  window.addEventListener("popstate", f);
  #|  return () => window.removeEventListener("popstate", f);
  #|}

///|
pub extern "js" fn dom_clear_children(node : Node) -> Unit =
  #|(node) => { while (node.firstChild) node.removeChild(node.firstChild); }


