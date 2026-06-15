using @dom {trait View, div, h1, p, button, text, a}

pub fn page() -> &View {
  div()
    .style("min-height: 100vh; background-color: #0f172a; display: flex; align-items: center; justify-content: center; padding: 1rem; font-family: system-ui, -apple-system, sans-serif;")
    .children([
      div()
        .style("max-width: 28rem; width: 100%; background-color: #1e293b; border-radius: 1rem; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); border: 1px solid #334155; padding: 2rem;")
        .children([
          header_section(),
          interactive_section(),
          footer_section()
        ])
    ])
}

fn header_section() -> &View {
  div()
    .style("text-align: center; margin-bottom: 2rem;")
    .children([
      h1()
        .style("font-size: 2.25rem; font-weight: 800; background: linear-gradient(to right, #2dd4bf, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 0 0 0.75rem 0; tracking-content: -0.025em;")
        .children([text("Aitne")]),
      p()
        .style("color: #94a3b8; font-size: 0.875rem; margin: 0; line-height: 1.5;")
        .children([text("Build lightweight, high-performance reactive web application.")])
    ])
}

fn interactive_section() -> &View {
  div()
    .style("display: flex; flex-direction: column; align-items: center;")
    .children([
      button()
        .style("padding: 0.75rem 1.5rem; width: 100%; background-color: #2563eb; color: #ffffff; font-weight: 600; border-radius: 0.75rem; border: none; cursor: pointer; box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.4); font-size: 1rem; transition: background-color 0.2s;")
        .on(Click, fn(_ev) {
          println("Clicked")
        })
        .children([text("Start")]),
    ])
}

fn footer_section() -> &View {
  div()
    .style("text-align: center; margin-top: 2rem;")
    .children([
      a()
        .attr("href", "#")
        .style("color: #64748b; font-size: 0.875rem; text-decoration: none;")
        .children([text("document")])
    ])
}
