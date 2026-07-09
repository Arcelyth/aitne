///|
using @dom {trait View}

///|
fn app() -> &View {
  let (count, set_count) = @reactive.create_signal(0)

  @reactive.create_effect(_ => println("Value: \{count.get()}"))

  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h1(children=["Counter"]),
    @Arcelyth/aitne/src/dom.p(children=[
      @Arcelyth/aitne/src/dom.text_dyn(() => count.get().to_string()),
    ]),
    @Arcelyth/aitne/src/dom.button(children=["+1"]).on(Click, _ => {
      set_count.update(v => v + 1)
    }),
    @Arcelyth/aitne/src/dom.button(children=["-1"]).on(Click, _ => {
      set_count.update(v => v - 1)
    }),
  ])
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
