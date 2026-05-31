type Window
type Document
type Element
type Event
type TimeoutHandle
type IntervalHandle
type AnimationFrameHandle
type Node

///| 
pub extern "js" fn prim_window() -> Window =
  #|() => window

///| 
pub extern "js" fn prim_document() -> Document =
  #|() => document

///|
pub extern "js" fn prim_create_element(doc : Document, tag : String) -> Node = 
  #|(doc, tag) => doc.createElement(tag)

///| 
pub extern "js" fn prim_create_text_node(doc : Document, text : String) -> Node = 
  #|(doc, text) => doc.createTextNode(text)

///|
pub extern "js" fn prim_get_element_by_id(doc : Document, id : String) -> Option[Node] = 
  #|(doc, id) => { let el = doc.getElementById(id); return el === null ? undefined : el; }

///|
pub extern "js" fn prim_get_body(doc : Document) -> Node = 
  #|(doc) => doc.body

///|
pub extern "js" fn set_property(el : Element, prop_name : String, value : String) -> Unit =
  #|(el, prop_name, value) => { el[prop_name] = value; }

///|
pub extern "js" fn remove_property(el : Element, prop_name : String) -> Unit =
  #|(el, prop_name) => { delete el[prop_name]; }

///|
pub extern "js" fn get_property(el : Element, prop_name : String) -> String =
  #|(el, prop_name) => String(el[prop_name] || "")

///|
pub extern "js" fn event_target_value(ev : Event) -> String =
  #|(ev) => ev.target ? (ev.target.value || "") : ""

///|
pub extern "js" fn event_target_checked(ev : Event) -> Bool =
  #|(ev) => ev.target ? !!ev.target.checked : false

///|
pub extern "js" fn set_timeout(cb : () -> Unit, ms : Int) -> TimeoutHandle =
  #|(cb, ms) => setTimeout(cb, ms)

///|
pub extern "js" fn clear_timeout(handle : TimeoutHandle) -> Unit =
  #|(handle) => clearTimeout(handle)

///|
pub extern "js" fn set_interval(cb : () -> Unit, ms : Int) -> IntervalHandle =
  #|(cb, ms) => setInterval(cb, ms)

///|
pub extern "js" fn clear_interval(handle : IntervalHandle) -> Unit =
  #|(handle) => clearInterval(handle)

///|
pub extern "js" fn request_animation_frame(cb : () -> Unit) -> AnimationFrameHandle =
  #|(cb) => requestAnimationFrame(cb)

///|
pub extern "js" fn cancel_animation_frame(handle : AnimationFrameHandle) -> Unit =
  #|(handle) => cancelAnimationFrame(handle)

///|
pub extern "js" fn window_add_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.addEventListener(name, cb)

///|
pub extern "js" fn window_remove_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.removeEventListener(name, cb)

///|
pub fn dom_create_element(tag : String) -> Node {
  prim_create_element(document(), tag)
}

///|
pub fn dom_create_text_node(text : String) -> Node {
  prim_create_text_node(document(), text)
}

///|
pub fn dom_get_element_by_id(id : String) -> Option[Node] {
  prim_get_element_by_id(document(), id)
}

///|
pub fn dom_get_body() -> Node {
  prim_get_body(document())
}

///|
pub fn on_window_event(ev_name : String, cb : (Event) -> Unit) -> () -> Unit {
  window_add_event_listener(ev_name, cb)
  fn() {
    window_remove_event_listener(ev_name, cb)
  }
}

///|
pub extern "js" fn dom_set_text(node : Node, text : String) -> Unit =
  #|(node, text) => { node.textContent = text; }

///|
pub extern "js" fn dom_set_attr(node : Node, key : String, val : String) -> Unit =
  #|(node, key, val) => { node.setAttribute(key, val); }

///|
pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => { node.classList.add(cls); }

///|
pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => { parent.appendChild(child); }

///|
pub extern "js" fn dom_add_event(node : Node, ev : String, handler : (Event) -> Unit) -> Unit =
  #|(node, ev, handler) => { node.addEventListener(ev, handler); }

///|
pub(all) enum EventType {
  Click
  Input
  Change
  Submit
  Keydown
  Keyup
}

///|
pub fn EventType::to_string(self : EventType) -> String {
  match self {
    Click   => "click"
    Input   => "input"
    Change  => "change"
    Submit  => "submit"
    Keydown => "keydown"
    Keyup   => "keyup"
  }
}

///|
pub enum Html {
  Element(ElementBuilder)
  Text(String)
  DynText(() -> String)
}

///|
pub struct ElementBuilder {
  tag: String
  classes: Array[String]
  attrs: Array[(String, String)]
  events: Array[(String, (Event) -> Unit)]
  children: Array[Html]
}

///|
fn el(tag : String) -> Html {
  Html::Element({
    tag, 
    classes: [],
    attrs: [],
    events: [],
    children: [],
  })
}

///|
pub fn Html::class_(self : Html, cls : String) -> Html {
  match self {
    Element(b) => Element({ ..b, classes: b.classes + [cls] })
    other => other
  }
}

///|
pub fn Html::attr(self : Html, key : String, val : String) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, val)] })
    other => other
  }
}

///|
pub fn Html::bool_attr(self : Html, key : String, _val : Bool) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, "")] })
    other => other
  }
}

///|
pub fn Html::on(self : Html, ev : EventType, handler : (Event) -> Unit) -> Html {
  match self {
    Element(b) => Element({ ..b, events: b.events + [(ev.to_string(), handler)] })
    other => other
  }
}

///|
pub fn Html::children(self : Html, kids : Array[Html]) -> Html {
  match self {
    Element(b) => Element({ ..b, children: kids })
    other => other
  }
}

///|
pub fn Html::mount(self : Html, parent : Node) -> Unit {
  match self {
    Text(s) => {
      let node = dom_create_text_node(s) 
      dom_append(parent, node)
    }
    DynText(f) => {
      let node = dom_create_text_node("")
      dom_append(parent, node)
      @reactive.create_effect(fn() {
        dom_set_text(node, f())
      })
    }
    Element(b) => {
      let node = dom_create_element(b.tag)
      for cls in b.classes { dom_add_class(node, cls) }
      b.attrs.each(fn(p) { dom_set_attr(node, p.0, p.1) })
      b.events.each(fn(p) { dom_add_event(node, p.0, p.1) })
      for child in b.children { child.mount(node) }
      dom_append(parent, node)
    }
  }
}

///|
pub fn mount_to_id(id : String, app : Html) -> Unit {
  match dom_get_element_by_id(id) {
    Some(parent) => app.mount(parent)
    None => ()
  }
}

///|
pub fn mount_to_body(app : Html) -> Unit {
  let body = dom_get_body()
  app.mount(body)
}

///|
pub fn div()    -> Html { el("div")    }
///|
pub fn p()      -> Html { el("p")      }
///|
pub fn span()   -> Html { el("span")   }
///|
pub fn h1()     -> Html { el("h1")     }
///|
pub fn h2()     -> Html { el("h2")     }
///|
pub fn h3()     -> Html { el("h3")     }
///|
pub fn button() -> Html { el("button") }
///|
pub fn input()  -> Html { el("input")  }
///|
pub fn ul()     -> Html { el("ul")     }
///|
pub fn li()     -> Html { el("li")     }
///|
pub fn a()      -> Html { el("a")      }
///|
pub fn form()   -> Html { el("form")   }
///|
pub fn label()  -> Html { el("label")  }

///|
pub fn text(s : String) -> Html { Html::Text(s) }
///|
pub fn text_dyn(f : () -> String) -> Html { Html::DynText(f) }
///|
pub fn unit_view() -> Html { Html::Text("") }
