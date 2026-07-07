///|
using @dom {trait View}

///|
fn app() -> &View {
  let (selected, set_selected) = @reactive.create_signal(false)

  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.button(children=["\"toggle\""]).on(Click, _ => {
      set_selected.set(!selected.get())
    }),
    @Arcelyth/aitne/src/dom.div(children=[
      @Arcelyth/aitne/src/dom.text_dyn(() => {
        if selected.get() {
          "selected"
        } else {
          "normal"
        }
      }),
    ]).class(
      @Arcelyth/aitne/src/dom.rx_class(() => {
        if selected.get() {
          "danger"
        } else {
          ""
        }
      }),
    ),
  ])
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
