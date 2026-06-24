using @dom { trait View }

pub fn counter() -> &View {
  let (count, set_count) = @reactive.create_signal(0)

  @Arcelyth/aitne/src/dom.div()
  .children([
    @Arcelyth/aitne/src/dom.h1()
  .children([
    "Counter"
  ]),
    @Arcelyth/aitne/src/dom.p()
  .children([
    @Arcelyth/aitne/src/dom.text_dyn(
         () => count.get().to_string() 
      )
  ]),
    @Arcelyth/aitne/src/dom.button()
  .children([
    "+1"
  ])
  .on(Click, (_) => { set_count.update((v) => { v + 1 }) }),
    @Arcelyth/aitne/src/dom.button()
  .children([
    "-1"
  ])
  .on(Click, (_) => { set_count.update((v) => { v - 1 }) })
  ])
}
