#external
type Node

pub extern "js" fn dom_create_element(tag : String) -> Node =
  #|(tag) => document.createElement(tag)

pub extern "js" fn dom_create_text_node(text : String) -> Node =
  #|(text) => document.createTextNode(text)

pub extern "js" fn dom_get_element_by_id(id : String) -> Node =
  #|(id) => document.getElementById(id)

pub extern "js" fn dom_set_text(node : Node, text : String) -> Unit =
  #|(node, text) => node.textContent = text

pub extern "js" fn dom_set_attr(node : Node, key : String, val : String) -> Unit =
  #|(node, key, val) => node.setAttribute(key, val)

pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => node.classList.add(cls)

pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => parent.appendChild(child)

pub extern "js" fn dom_add_event(node : Node, ev : String, handler : () -> Unit) -> Unit =
  #|(node, ev, handler) => node.addEventListener(ev, handler)

pub extern "js" fn dom_get_body() -> Node =
  #|() => document.body


pub(all) enum Event {
  Click
  Input
  Change
  Submit
  Keydown
  Keyup
}

fn Event::to_string(self : Event) -> String {
  match self {
    Click   => "click"
    Input   => "input"
    Change  => "change"
    Submit  => "submit"
    Keydown => "keydown"
    Keyup   => "keyup"
  }
}

pub enum Html {
  Element(ElementBuilder)
  Text(String)
  DynText(() -> String)
}


pub struct ElementBuilder {
  tag: String
  classes: Array[String]
  attrs: Array[(String, String)]
  events: Array[(String, () -> Unit)]
  children: Array[Html]
}

fn el(tag : String) -> Html {
  Html::Element({
    tag, 
    classes: [],
    attrs: [],
    events: [],
    children: [],
  })
}

pub fn Html::class_(self : Html, cls : String) -> Html {
  match self {
    Element(b) => Element({ ..b, classes: b.classes + [cls] })
    other => other
  }
}

pub fn Html::attr(self : Html, key : String, val : String) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, val)] })
    other => other
  }
}

pub fn Html::bool_attr(self : Html, key : String, _val : Bool) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, "")] })
    other => other
  }
}

pub fn Html::on(self : Html, ev : Event, handler : () -> Unit) -> Html {
  match self {
    Element(b) => Element({ ..b, events: b.events + [(ev.to_string(), handler)] })
    other => other
  }
}

pub fn Html::children(self : Html, kids : Array[Html]) -> Html {
  match self {
    Element(b) => Element({ ..b, children: kids })
    other => other
  }
}

pub fn Html::mount(self : Html, parent : Node) -> Unit {
  match self {
    Text(s) => {
      let node = dom_create_text_node(s) 
      dom_append(parent, node)
    }
    DynText(f) => {
      let node = dom_create_element("text")
      dom_append(parent, node)
      @reactive.create_effect(fn() {
        dom_set_text(node, f())
      })
    }
    Element(b) => {
      let node = dom_create_element(b.tag)
      for cls in b.classes { dom_add_class(node, cls) }
      b.attrs.each(fn(p) {
        dom_set_attr(node, p.0, p.1)
      })
      b.events.each(fn(p) { dom_add_event(node, p.0, p.1) })
      for child in b.children { child.mount(node) }
      dom_append(parent, node)
    }
  }
}

pub fn mount_to_body(app : Html) -> Unit {
  let body = dom_get_body()
  app.mount(body)
}
                
pub fn div()    -> Html { el("div")    }
pub fn p()      -> Html { el("p")      }
pub fn span()   -> Html { el("span")   }
pub fn h1()     -> Html { el("h1")     }
pub fn h2()     -> Html { el("h2")     }
pub fn h3()     -> Html { el("h3")     }
pub fn button() -> Html { el("button") }
pub fn input()  -> Html { el("input")  }
pub fn ul()     -> Html { el("ul")     }
pub fn li()     -> Html { el("li")     }
pub fn a()      -> Html { el("a")      }
pub fn form()   -> Html { el("form")   }
pub fn label()  -> Html { el("label")  }

pub fn text(s : String) -> Html { Html::Text(s) }
pub fn text_dyn(f : () -> String) -> Html { Html::DynText(f) }
pub fn unit_view() -> Html { Html::Text("") }
