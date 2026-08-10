///|
#cfg(target="js")
pub extern "js" fn create_template() -> TemplateElement =
  #| () => document.createElement("template")

///|
#cfg(target="js")
pub extern "js" fn clone_node_shallow(tpl : TemplateElement) -> TemplateElement =
  #| (tpl) => tpl.cloneNode(false)

///|
#cfg(target="js")
pub extern "js" fn clone_template_content(tpl : TemplateElement) -> Element =
  #| (tpl) => tpl.content.cloneNode(true)

///|
#cfg(target="js")
pub extern "js" fn set_inner_html(tpl : TemplateElement, html : String) -> Unit =
  #| (tpl, html) => { tpl.innerHTML = html; }

///|
#cfg(target="js")
pub extern "js" fn first_child_skip_comments(node : Node) -> Node =
  #| (node) => {
  #|   let curr = node.firstChild;
  #|   while (curr && curr.nodeType === 8 &&
  #|         (curr.textContent.startsWith('bo') || curr.textContent.startsWith('bc'))) {
  #|     curr = curr.nextSibling;
  #|   }
  #|   return curr || null;
  #| }

///|
#cfg(target="js")
pub extern "js" fn next_sibling_skip_comments(node : Node) -> Node =
  #| (node) => {
  #|   let curr = node.nextSibling;
  #|   while (curr && curr.nodeType === 8 &&
  #|         (curr.textContent.startsWith('bo') || curr.textContent.startsWith('bc'))) {
  #|     curr = curr.nextSibling;
  #|   }
  #|   return curr || null;
  #| }

///|
#cfg(target="js")
pub extern "js" fn parent_node(node : Node) -> Node =
  #| (node) => node.parentNode || null

///|
#cfg(target="js")
pub extern "js" fn is_comment_node(node : Node) -> Bool =
  #| (node) => node.nodeType === 8

///|
#cfg(target="js")
pub extern "js" fn console_error(msg1 : String, node : Node, msg2 : String) =
  #| (m1, n, m2) => console.error(m1, n, m2)
