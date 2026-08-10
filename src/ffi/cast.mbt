///|
#cfg(target="js")
#alias(node_as_element)
pub extern "js" fn cast_node_to_element(node : Node) -> Element =
  #| (node) => node

///|
#cfg(target="js")
pub extern "js" fn cast_node_to_comment(node : Node) -> Comment =
  #| (node) => node

///|
#cfg(target="js")
pub extern "js" fn cast_node_to_text(node : Node) -> Text =
  #| (node) => node

///|
#cfg(target="js")
#alias(el_as_node)
pub extern "js" fn cast_element_to_node(el : Element) -> Node =
  #|(el) => el

///|
#cfg(target="js")
#alias(text_as_node)
pub extern "js" fn cast_text_to_node(t : Text) -> Node =
  #|(t) => t

///|
#cfg(target="js")
#alias(comment_as_node)
pub extern "js" fn cast_comment_to_node(c : Comment) -> Node =
  #|(c) => c

///|
#cfg(target="js")
pub extern "js" fn cast_template_element_to_node(c : TemplateElement) -> Node =
  #|(c) => c
