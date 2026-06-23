using @dom {trait View, div, h1, p, button, text, a}

pub fn page() -> &View {
  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.div()
  .children([
    header_section(),
    interactive_section(),
    footer_section()
  ])
  .attr("style", "&quot;max-width: 28rem; width: 100%; background-color: #1e293b; border-radius: 1rem; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); border: 1px solid #334155; padding: 2rem;&quot;")
  ])
  .attr("style", "&quot;min-height: 100vh; background-color: #0f172a; display: flex; align-items: center; justify-content: center; padding: 1rem; font-family: system-ui, -apple-system, sans-serif;&quot;")
}

fn header_section() -> &View {
  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.h1()
  .children([
    @Arcelyth/aitne/src/dom.text("Aitne")
  ])
  .attr("style", "&quot;font-size: 2.25rem; font-weight: 800; background: linear-gradient(to right, #2dd4bf, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 0 0 0.75rem 0; tracking-content: -0.025em;&quot;"),
    @Arcelyth/aitne/src/dom.p()
  .children([
    @Arcelyth/aitne/src/dom.text("Build lightweight, high-performance reactive web application.")
  ])
  .attr("style", "&quot;color: #94a3b8; font-size: 0.875rem; margin: 0; line-height: 1.5;&quot;")
  ])
  .attr("style", "&quot;text-align: center; margin-bottom: 2rem;&quot;")
}

fn interactive_section() -> &View {
  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.button()
  .children([
    @Arcelyth/aitne/src/dom.text("Start")
  ])
  .attr("style", "&quot;padding: 0.75rem 1.5rem; width: 100%; background-color: #2563eb; color: #ffffff; font-weight: 600; border-radius: 0.75rem; border: none; cursor: pointer; box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.4); font-size: 1rem; transition: background-color 0.2s;&quot;")
  .on(Click, {fn(_ev) { println("Clicked") }})
  ])
  .attr("style", "&quot;display: flex; flex-direction: column; align-items: center;&quot;")
}

fn footer_section() -> &View {
  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.a()
  .children([
    @Arcelyth/aitne/src/dom.text("document")
  ])
  .attr("href", "&quot;#&quot;")
  .attr("style", "&quot;color: #64748b; font-size: 0.875rem; text-decoration: none;&quot;")
  ])
  .attr("style", "&quot;text-align: center; margin-top: 2rem;&quot;")
}
