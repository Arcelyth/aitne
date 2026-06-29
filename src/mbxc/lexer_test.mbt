///|
test "lexer_basic_html" {
  let src =
    #|<div>hello</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(hello), TagClose({tag: div})]",
  )
}

///|
test "lexer_string_handle" {
  let src =
    #|let a = "<div>"
    #|<div>"<div>"</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[RawText(let a = \"<div>\"\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(\"<div>\"), TagClose({tag: div})]",
  )
}

///|
test "lexer_<_handle_outside" {
  let src =
    #|if a < b
    #|<div>"<div>"</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[RawText(if a < b\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(\"<div>\"), TagClose({tag: div})]",
  )
}

///|
test "lexer_<_handle_inside" {
  let src =
    #|<div>a < b</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(a < b), TagClose({tag: div})]",
  )
}

///|
test "lexer_attributes" {
  let src =
    #|<div id="app"></div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagOpen({tag: div, attrs: HashMap::from_array([({ns: None, name: id}, app)])}), TagClose({tag: div})]",
  )
}

///|
test "lexer_event_attribute" {
  let src =
    #|<button on:click={() => 1}>+</button>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagOpen({tag: button, attrs: HashMap::from_array([({ns: Some(on), name: click}, () => 1)])}), RawText(+), TagClose({tag: button})]",
  )
}

///|
test "lexer_self_closing" {
  let src =
    #|<img src="a.png"/>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagSelfClose({tag: img, attrs: HashMap::from_array([({ns: None, name: src}, a.png)])})]",
  )
}

///|
test "lexer_self_closing" {
  let src =
    #|<button on:click={() => a}/>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagSelfClose({tag: button, attrs: HashMap::from_array([({ns: Some(on), name: click}, () => a)])})]",
  )
}

///|
test "lexer_code_then_html" {
  let src =
    #|let a = 1
    #|<div>{() => a}</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[RawText(let a = 1\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), BraceOpen, RawText(() => a), BraceClose, TagClose({tag: div})]",
  )
}

///|
test "lexer_no_brace" {
  let src =
    #|let a = 1
    #|<div>() => a</div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[RawText(let a = 1\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(() => a), TagClose({tag: div})]",
  )
}

///|
test "lexer_has_brace_html" {
  let src =
    #|let v = #{
    #|  <div>{ () => #{ <div/>}#}</div>}#

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[RawText(let v = ), HashBraceOpen, TagOpen({tag: div, attrs: HashMap::from_array([])}), BraceOpen, RawText( () => ), HashBraceOpen, TagSelfClose({tag: div, attrs: HashMap::from_array([])}), HashBraceClose, BraceClose, TagClose({tag: div}), HashBraceClose]",
  )
}

///|
test "lexer_nested_code_block_attr" {
  let src =
    #|<div value={{ a: { b: 1 } }}></div>

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagOpen({tag: div, attrs: HashMap::from_array([({ns: None, name: value}, { a: { b: 1 } })])}), TagClose({tag: div})]",
  )
}

///|
test "custom_component" {
  let src =
    #|<What />

  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  inspect(
    tokens,
    content="[TagSelfClose({tag: What, attrs: HashMap::from_array([])})]",
  )
}
