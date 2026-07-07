///|
using @dom {trait View}

///|
pub fn page() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.div(children=[
      header_section(),
      interactive_section(),
      footer_section(),
    ]).attr(
      "style", "max-width: 28rem; width: 100%; background-color: #1e293b; border-radius: 1rem; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); border: 1px solid #334155; padding: 2rem;",
    ),
  ]).class("page")
}

///|
fn header_section() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h1(children=["Aitne"]).attr(
      "style", "font-size: 2.25rem; font-weight: 800; background: linear-gradient(to right, #2dd4bf, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 0 0 0.75rem 0; tracking-content: -0.025em;",
    ),
    @Arcelyth/aitne/src/dom.p(children=[
      "Build lightweight, high-performance reactive web application.",
    ]).attr(
      "style", "color: #94a3b8; font-size: 0.875rem; margin: 0; line-height: 1.5;",
    ),
  ]).class("header_section")
}

///|
fn interactive_section() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.button(children=["Start"])
    .on(Click, fn(_ev) { println("Clicked") })
    .attr(
      "style", "padding: 0.75rem 1.5rem; width: 100%; background-color: #2563eb; color: #ffffff; font-weight: 600; border-radius: 0.75rem; border: none; cursor: pointer; box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.4); font-size: 1rem; transition: background-color 0.2s;",
    ),
  ]).class("interactive_section")
}

///|
fn footer_section() -> &View {
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.a(children=["document"])
    .attr("href", "#")
    .attr(
      "style", "color: #64748b; font-size: 0.875rem; text-decoration: none;",
    ),
  ]).class("footer_section")
}
