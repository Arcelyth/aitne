///|
#cfg(target="wasm-gc")
pub extern "wasm" fn current_origin() -> String = "aitne" "current_origin"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn current_pathname() -> String = "aitne" "current_pathname"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn current_search() -> String = "aitne" "current_search"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn current_hash() -> String = "aitne" "current_hash"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn history_push_state(url : String) -> Unit = "aitne" "history_push_state"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn history_replace_state(url : String) -> Unit = "aitne" "history_replace_state"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn on_popstate(cb : () -> Unit) -> EventHandle = "aitne" "on_popstate"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn node_is_anchor(node : Node) -> Bool = "aitne" "node_is_anchor"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn anchor_href(el : Element) -> String = "aitne" "anchor_href"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn anchor_target(el : Element) -> String = "aitne" "anchor_target"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn anchor_has_attr(el : Element, name : String) -> Bool = "aitne" "anchor_has_attr"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn anchor_get_attr(el : Element, name : String) -> String = "aitne" "anchor_get_attr"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn url_can_parse(href : String, base : String) -> Bool = "aitne" "url_can_parse"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn url_origin_from_base(
  href : String,
  base : String,
) -> String = "aitne" "url_origin_from_base"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn url_path_from_base(href : String, base : String) -> String = "aitne" "url_path_from_base"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn url_search_from_base(
  href : String,
  base : String,
) -> String = "aitne" "url_search_from_base"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn url_hash_from_base(href : String, base : String) -> String = "aitne" "url_hash_from_base"
