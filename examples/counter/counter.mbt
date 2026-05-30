pub fn counter_component(initial : Int) -> @dom.Html {
  // Create reactive state
  let count = @reactive.Signal::new(initial)

  let doubled = @reactive.Memo::new(fn() { count.get() * 2 })

  let handle_inc = fn() { count.update(fn(n) { n + 1 }) }
  let handle_dec = fn() { count.update(fn(n) { n - 1 }) }

  @reactive.create_effect(fn() {
    let n = count.get()
    let d = doubled.get()
    println("count=\{n}  doubled=\{d}")
  })

  @dom.div()
    .class_("counter")
    .children([
      @dom.h1().children([@dom.text("Counter")]),
      @dom.p().children([@dom.text_dyn(fn() { count.get().to_string() })]),
      @dom.button().on(@dom.Click, handle_inc).children([@dom.text("+1")]),
      @dom.button().on(@dom.Click, handle_dec).children([@dom.text("-1")]),
      @dom.p().children([
        @dom.text("Doubled: "),
        @dom.text_dyn(fn() { doubled.get().to_string() }),
      ]),
    ])
}
