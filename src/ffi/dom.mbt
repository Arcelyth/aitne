///|
#cfg(target="js")
pub extern "js" fn prim_document() -> Document =
  #|() => document

///|
#cfg(target="js")
pub extern "js" fn prim_get_body(doc : Document) -> Node =
  #|(doc) => doc.body

///|
#cfg(target="js")
pub extern "js" fn prim_get_element_by_id(doc : Document, id : String) -> Node =
  #|(doc, id) => doc.getElementById(id)

///|
#cfg(target="js")
pub extern "js" fn prim_create_element(doc : Document, tag : String) -> Element =
  #|(doc, tag) => doc.createElement(tag)

///|
#cfg(target="js")
pub extern "js" fn prim_create_text_node(doc : Document, text : String) -> Text =
  #|(doc, text) => doc.createTextNode(text)

///|
#cfg(target="js")
pub extern "js" fn dom_create_comment(text : String) -> Node =
  #|(text) => document.createComment(text)

///|
#cfg(target="js")
pub extern "js" fn prim_create_template(html : String) -> Node =
  #|(html) => { const tpl = document.createElement('template'); tpl.innerHTML = html; return tpl.content; }

///|
#cfg(target="js")
pub extern "js" fn dom_null_node() -> Node =
  #|() => null

///|
#cfg(target="js")
pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => parent.appendChild(child)

///|
#cfg(target="js")
pub extern "js" fn dom_insert_before(
  parent : Node,
  new_child : Node,
  ref_child : Node,
) -> Unit =
  #|(parent, new_child, ref_child) => { parent.insertBefore(new_child, ref_child); }

///|
#cfg(target="js")
pub extern "js" fn dom_remove_child(parent : Node, child : Node) -> Unit =
  #|(parent, child) => { parent.removeChild(child); }

///|
#cfg(target="js")
pub extern "js" fn dom_remove_self(node : Node) -> Unit =
  #|(node) => {
  #|  if (node && node.parentNode) {
  #|    node.parentNode.removeChild(node);
  #|  }
  #|}

///|
#cfg(target="js")
pub extern "js" fn dom_remove(node : Node) -> Unit =
  #|(node) => node.remove()

///|
#cfg(target="js")
pub extern "js" fn dom_clear_children(node : Node) -> Unit =
  #|(node) => { while (node.firstChild) node.removeChild(node.firstChild); }

///|
#cfg(target="js")
pub extern "js" fn prim_clone_node(node : Node) -> Node =
  #|(node) => node.cloneNode(true)

///|
#cfg(target="js")
pub extern "js" fn dom_remove_range(start : Node, end : Node) -> Unit =
  #|(start, end) => {
  #|  const range = document.createRange();
  #|  range.setStartAfter(start);
  #|  range.setEndBefore(end);
  #|  range.deleteContents();
  #|}

///|
#cfg(target="js")
pub extern "js" fn prim_node_eq(a : Node, b : Node) -> Bool =
  #|(a, b) => a === b

///|
#cfg(target="js")
#alias(dom_is_null)
pub extern "js" fn prim_is_null(node : Node) -> Bool =
  #|(node) => node === null || node === undefined

///|
#cfg(target="js")
pub extern "js" fn element_is_null(el : Element) -> Bool =
  #|(el) => el === null || el === undefined

///|
#cfg(target="js")
pub extern "js" fn prim_first_child(node : Node) -> Node =
  #|(node) => node.firstChild

///|
#cfg(target="js")
pub extern "js" fn prim_first_element_child(node : Node) -> Element =
  #|(node) => node.firstElementChild

///|
#cfg(target="js")
pub extern "js" fn prim_next_sibling(node : Node) -> Node =
  #|(node) => node.nextSibling

///|
#cfg(target="js")
pub extern "js" fn dom_parent(node : Node) -> Node =
  #|(node) => node.parentNode

///|
#cfg(target="js")
pub extern "js" fn dom_tag_name(node : Node) -> String =
  #|(node) => node.tagName?.toLowerCase() ?? ""

// ----- Attributes

///|
#cfg(target="js")
pub extern "js" fn dom_set_attr(
  el : Element,
  key : String,
  val : String,
) -> Unit =
  #|(el, key, val) => { el.setAttribute(key, val); }

///|
#cfg(target="js")
pub extern "js" fn dom_set_attribute(
  el : Element,
  key : String,
  value : String,
) -> Unit =
  #|(el, key, value) => el.setAttribute(key, value)

///|
#cfg(target="js")
pub extern "js" fn dom_remove_attr(el : Element, key : String) -> Unit =
  #|(el, key) => { el.removeAttribute(key); }

///|
#cfg(target="js")
pub extern "js" fn dom_remove_attribute(el : Element, key : String) -> Unit =
  #|(el, key) => el.removeAttribute(key)

// -----

///|
#cfg(target="js")
pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => { node.classList.add(cls); }

///|
#cfg(target="js")
pub extern "js" fn dom_set_text(node : Node, text : String) -> Unit =
  #|(node, text) => { node.textContent = text; }

// ----- Properties

///|
#cfg(target="js")
pub extern "js" fn set_property(
  el : Element,
  prop_name : String,
  value : String,
) -> Unit =
  #|(el, prop_name, value) => { el[prop_name] = value; }

///|
#cfg(target="js")
pub extern "js" fn dom_set_prop(
  node : Node,
  key : String,
  val : String,
) -> Unit =
  #|(node, key, val) => { node[key] = val; }

///|
#cfg(target="js")
pub extern "js" fn remove_property(el : Element, prop_name : String) -> Unit =
  #|(el, prop_name) => { delete el[prop_name]; }

///|
#cfg(target="js")
pub extern "js" fn get_property(el : Element, prop_name : String) -> String =
  #|(el, prop_name) => String(el[prop_name] || "")

///|
#cfg(target="js")
pub extern "js" fn get_bool_property(el : Element, key : String) -> Bool =
  #|(el, key) => {
  #|  const v = el[key];
  #|  return typeof v === "boolean" ? v : false;
  #|}

///|
#cfg(target="js")
pub extern "js" fn dom_set_property_bool(
  el : Element,
  key : String,
  value : Bool,
) -> Unit =
  #|(el, key, value) => el[key] = value

// -----

///|
#cfg(target="js")
pub extern "js" fn is_text_node(node : Node) -> Bool =
  #| (node) => node.nodeType === 3
