using @dom { trait View }

pub fn counter() -> &View {
  let (count, set_count) = @reactive.create_signal(0)

  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.h1()
  .children([
    @Arcelyth/aitne/src/dom.text("Counter")
  ]),
    @Arcelyth/aitne/src/dom.p()
  .children([
    @Arcelyth/aitne/src/dom.text_dyn({ () => count.get().to_string() })
  ]),
    @Arcelyth/aitne/src/dom.button()
  .children([
    @Arcelyth/aitne/src/dom.text("+1")
  ])
  .on(Click, {fn(_e) { set_count.update(fn(v) { v + 1 }) }}),
    @Arcelyth/aitne/src/dom.button()
  .children([
    @Arcelyth/aitne/src/dom.text("-1")
  ])
  .on(Click, {fn(_e) { set_count.update(fn(v) { v - 1 }) }})
  ])
}
