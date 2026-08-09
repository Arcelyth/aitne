///|
#cfg(target="js")
pub extern "js" fn current_origin() -> String =
  #|() => location.origin

///|
#cfg(target="js")
pub extern "js" fn current_pathname() -> String =
  #|() => location.pathname

///|
#cfg(target="js")
pub extern "js" fn current_search() -> String =
  #|() => location.search

///|
#cfg(target="js")
pub extern "js" fn current_hash() -> String =
  #|() => location.hash

///|
#cfg(target="js")
pub extern "js" fn history_push_state(url : String) -> Unit =
  #|(url) => { history.pushState(null, "", url); }

///|
#cfg(target="js")
pub extern "js" fn history_replace_state(url : String) -> Unit =
  #|(url) => { history.replaceState(null, "", url); }

///|
#cfg(target="js")
pub extern "js" fn on_popstate(cb : () -> Unit) -> EventHandle =
  #|(cb) => {
  #|  const f = () => cb();
  #|  window.addEventListener("popstate", f);
  #|  return () => window.removeEventListener("popstate", f);
  #|}

///|
#cfg(target="js")
pub extern "js" fn node_is_anchor(node : Node) -> Bool =
  #|(node) => node instanceof HTMLAnchorElement

///|
#cfg(target="js")
pub extern "js" fn anchor_href(el : Element) -> String =
  #|(el) => el.href

///|
#cfg(target="js")
pub extern "js" fn anchor_target(el : Element) -> String =
  #|(el) => el.target

///|
#cfg(target="js")
pub extern "js" fn anchor_has_attr(el : Element, name : String) -> Bool =
  #|(el, name) => el.hasAttribute(name)

///|
#cfg(target="js")
pub extern "js" fn anchor_get_attr(el : Element, name : String) -> String =
  #|(el, name) => el.getAttribute(name) ?? ""

///|
#cfg(target="js")
pub extern "js" fn url_can_parse(href : String, base : String) -> Bool =
  #|(href, base) => {
  #|  try { new URL(href, base); return true; } catch (e) { return false; }
  #|}

///|
#cfg(target="js")
pub extern "js" fn url_origin_from_base(href : String, base : String) -> String =
  #|(href, base) => new URL(href, base).origin

///|
#cfg(target="js")
pub extern "js" fn url_path_from_base(href : String, base : String) -> String =
  #|(href, base) => new URL(href, base).pathname

///|
#cfg(target="js")
pub extern "js" fn url_search_from_base(href : String, base : String) -> String =
  #|(href, base) => new URL(href, base).search

///|
#cfg(target="js")
pub extern "js" fn url_hash_from_base(href : String, base : String) -> String =
  #|(href, base) => new URL(href, base).hash
