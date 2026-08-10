///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_document() -> Document = "aitne" "prim_document"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_get_body(doc : Document) -> Node = "aitne" "prim_get_body"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_get_element_by_id(
  doc : Document,
  id : String,
) -> Node = "aitne" "prim_get_element_by_id"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_create_element(
  doc : Document,
  tag : String,
) -> Element = "aitne" "prim_create_element"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_create_text_node(
  doc : Document,
  text : String,
) -> Text = "aitne" "prim_create_text_node"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_create_comment(text : String) -> Node = "aitne" "dom_create_comment"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_create_template(html : String) -> Node = "aitne" "prim_create_template"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_null_node() -> Node = "aitne" "dom_null_node"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_append(parent : Node, child : Node) -> Unit = "aitne" "dom_append"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_insert_before(
  parent : Node,
  new_child : Node,
  ref_child : Node,
) -> Unit = "aitne" "dom_insert_before"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove_child(parent : Node, child : Node) -> Unit = "aitne" "dom_remove_child"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove_self(node : Node) -> Unit = "aitne" "dom_remove_self"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove(node : Node) -> Unit = "aitne" "dom_remove"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_clear_children(node : Node) -> Unit = "aitne" "dom_clear_children"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_clone_node(node : Node) -> Node = "aitne" "prim_clone_node"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove_range(start : Node, end : Node) -> Unit = "aitne" "dom_remove_range"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_node_eq(a : Node, b : Node) -> Bool = "aitne" "prim_node_eq"

///|
#cfg(target="wasm-gc")
#alias(dom_is_null)
pub extern "wasm" fn prim_is_null(node : Node) -> Bool = "aitne" "prim_is_null"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn element_is_null(el : Element) -> Bool = "aitne" "element_is_null"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_first_child(node : Node) -> Node = "aitne" "prim_first_child"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_first_element_child(node : Node) -> Element = "aitne" "prim_first_element_child"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_next_sibling(node : Node) -> Node = "aitne" "prim_next_sibling"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_parent(node : Node) -> Node = "aitne" "dom_parent"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_tag_name(node : Node) -> String = "aitne" "dom_tag_name"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_set_attr(
  el : Element,
  key : String,
  val : String,
) -> Unit = "aitne" "dom_set_attr"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_set_attribute(
  el : Element,
  key : String,
  value : String,
) -> Unit = "aitne" "dom_set_attribute"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove_attr(el : Element, key : String) -> Unit = "aitne" "dom_remove_attr"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_remove_attribute(el : Element, key : String) -> Unit = "aitne" "dom_remove_attribute"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_add_class(node : Node, cls : String) -> Unit = "aitne" "dom_add_class"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_set_text(node : Node, text : String) -> Unit = "aitne" "dom_set_text"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn set_property(
  el : Element,
  prop_name : String,
  value : String,
) -> Unit = "aitne" "set_property"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_set_prop(
  node : Node,
  key : String,
  val : String,
) -> Unit = "aitne" "dom_set_prop"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn remove_property(el : Element, prop_name : String) -> Unit = "aitne" "remove_property"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn get_property(el : Element, prop_name : String) -> String = "aitne" "get_property"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn get_bool_property(el : Element, key : String) -> Bool = "aitne" "get_bool_property"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_set_property_bool(
  el : Element,
  key : String,
  value : Bool,
) -> Unit = "aitne" "dom_set_property_bool"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn is_text_node(node : Node) -> Bool = "aitne" "is_text_node"
