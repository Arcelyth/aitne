pub fn counter() -> @dom.Html {
  let (count, set_count) = @reactive.create_signal(0)

  
  {
    let _tpl = @Arcelyth/aitne/src/dom.create_template("<div>\n    <h1>Counter</h1>\n    \n    <p></p>\n\n    <button>\n      +1\n    </button>\n\n    <button>\n      -1\n    </button>\n  </div>")
    let _root = @Arcelyth/aitne/src/dom.clone_node(_tpl)
      @Arcelyth/aitne/src/dom.insert_dynamic(_root, [0, 3, 0], { () => count.get().to_string() })
    @Arcelyth/aitne/src/dom.on(_root, [0, 5], "click", {fn(_e) { set_count.update(fn(v) { v + 1 }) }})
    @Arcelyth/aitne/src/dom.on(_root, [0, 7], "click", {fn(_e) { set_count.update(fn(v) { v - 1 }) }})
   @Arcelyth/aitne/src/dom.Html::RawNode(_root)
  }

}
