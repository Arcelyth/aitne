///|
#cfg(target="wasm-gc")
#alias(node_as_element)
pub extern "wasm" fn cast_node_to_element(node : Node) -> Element =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn cast_node_to_comment(node : Node) -> Comment =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn cast_node_to_text(node : Node) -> Text =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
#alias(el_as_node)
pub extern "wasm" fn cast_element_to_node(el : Element) -> Node =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
#alias(text_as_node)
pub extern "wasm" fn cast_text_to_node(t : Text) -> Node =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
#alias(comment_as_node)
pub extern "wasm" fn cast_comment_to_node(c : Comment) -> Node =
  #|(func (param externref) (result externref) (local.get 0))

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn cast_template_element_to_node(c : TemplateElement) -> Node =
  #|(func (param externref) (result externref) (local.get 0))
