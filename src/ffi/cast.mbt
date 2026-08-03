///|
#alias(node_as_element)
pub extern "js" fn cast_node_to_element(node : Node) -> Element =
  #| (node) => node

///|
pub extern "js" fn cast_node_to_comment(node : Node) -> Comment =
  #| (node) => node

///|
pub extern "js" fn cast_node_to_text(node : Node) -> Text =
  #| (node) => node

///|
#alias(el_as_node)
pub extern "js" fn cast_element_to_node(el : Element) -> Node =
  #|(el) => el

///|
#alias(text_as_node)
pub extern "js" fn cast_text_to_node(t : Text) -> Node =
  #|(t) => t

///|
#alias(comment_as_node)
pub extern "js" fn cast_commen_to_node(c : Comment) -> Node =
  #|(c) => c
