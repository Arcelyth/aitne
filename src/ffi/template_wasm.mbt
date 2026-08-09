///|
#cfg(target="wasm-gc")
pub extern "wasm" fn create_template() -> TemplateElement = "aitne" "create_template"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn clone_node_shallow(
  tpl : TemplateElement,
) -> TemplateElement = "aitne" "clone_node_shallow"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn clone_template_content(tpl : TemplateElement) -> Element = "aitne" "clone_template_content"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn set_inner_html(
  tpl : TemplateElement,
  html : String,
) -> Unit = "aitne" "set_inner_html"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn first_child_skip_comments(node : Node) -> Node = "aitne" "first_child_skip_comments"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn next_sibling_skip_comments(node : Node) -> Node = "aitne" "next_sibling_skip_comments"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn parent_node(node : Node) -> Node = "aitne" "parent_node"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn is_comment_node(node : Node) -> Bool = "aitne" "is_comment_node"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn console_error(msg1 : String, node : Node, msg2 : String) = "aitne" "console_error"
