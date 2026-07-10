/////|
//test "lexer_basic_html" {
//  let src =
//    #|<div>hello</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(hello), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_string_handle" {
//  let src =
//    #|let a = "<div>"
//    #|<div>"<div>"</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[RawText(let a = \"<div>\"\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(\"<div>\"), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_<_handle_outside" {
//  let src =
//    #|if a < b
//    #|<div>"<div>"</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[RawText(if a < b\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(\"<div>\"), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_<_handle_inside" {
//  let src =
//    #|<div>a < b</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(a < b), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_attributes" {
//  let src =
//    #|<div id="app"></div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: div, attrs: HashMap::from_array([({ns: None, name: id}, Str(app))])}), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_event_attribute" {
//  let src =
//    #|<button on:click={() => 1}>+</button>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: button, attrs: HashMap::from_array([({ns: Some(on), name: click}, Expr(() => 1))])}), RawText(+), TagClose({tag: button})]",
//  )
//}
//
/////|
//test "lexer_self_closing_str" {
//  let src =
//    #|<img src="a.png"/>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagSelfClose({tag: img, attrs: HashMap::from_array([({ns: None, name: src}, Str(a.png))])})]",
//  )
//}
//
/////|
//test "lexer_self_closing_expr" {
//  let src =
//    #|<button on:click={() => a}/>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagSelfClose({tag: button, attrs: HashMap::from_array([({ns: Some(on), name: click}, Expr(() => a))])})]",
//  )
//}
//
/////|
//test "lexer_code_then_html" {
//  let src =
//    #|let a = 1
//    #|<div>{() => a}</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[RawText(let a = 1\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), BraceOpen, RawText(() => a), BraceClose, TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_no_brace" {
//  let src =
//    #|let a = 1
//    #|<div>() => a</div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[RawText(let a = 1\n), TagOpen({tag: div, attrs: HashMap::from_array([])}), RawText(() => a), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "lexer_has_brace_html" {
//  let src =
//    #|let v = #{
//    #|  <div>{ () => #{ <div/>}#}</div>}#
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[RawText(let v = ), HashBraceOpen, TagOpen({tag: div, attrs: HashMap::from_array([])}), BraceOpen, RawText( () => ), HashBraceOpen, TagSelfClose({tag: div, attrs: HashMap::from_array([])}), HashBraceClose, BraceClose, TagClose({tag: div}), HashBraceClose]",
//  )
//}
//
/////|
//test "lexer_nested_code_block_attr" {
//  let src =
//    #|<div value={{ a: { b: 1 } }}></div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: div, attrs: HashMap::from_array([({ns: None, name: value}, Expr({ a: { b: 1 } }))])}), TagClose({tag: div})]",
//  )
//}
//
/////|
//test "custom_component" {
//  let src =
//    #|<What />
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagSelfClose({tag: What, attrs: HashMap::from_array([])})]",
//  )
//}
//
/////|
//test "lexer_mixed_attributes" {
//  let src =
//    #|<div data-count={123}></div>
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  debug_inspect(
//    tokens,
//    content="[TagOpen({tag: div, attrs: HashMap::from_array([({ns: None, name: data-count}, Expr(123))])}), TagClose({tag: div})]",
//  )
//}

///|
test "lexer_basic_html" {
  let src =
    #|<div>hello</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "hello">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_string_handle" {
  let src =
    #|let a = "<div>"
    #|<div>"<div>"</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = \"<div>\"\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "\"<div>\"">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_<_handle_outside" {
  let src =
    #|if a < b
    #|<div>"<div>"</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "if a < b\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "\"<div>\"">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_<_handle_inside" {
  let src =
    #|<div>a < b</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "a < b">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_attributes" {
  let src =
    #|<div id="app"></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "id"> }: Str(<StringView: "app">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_event_attribute" {
  let src =
    #|<button on:click={() => 1}>+</button>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "button">,
      #|      attrs: <HashMap:
      #|        { { ns: Some(<StringView: "on">), name: <StringView: "click"> }: Expr(<StringView: "() => 1">) }>,
      #|    },
      #|  ),
      #|  RawText(<StringView: "+">),
      #|  TagClose({ tag: <StringView: "button"> }),
      #|]
    ),
  )
}

///|
test "lexer_self_closing_str" {
  let src =
    #|<img src="a.png"/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "img">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "src"> }: Str(<StringView: "a.png">) }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer_self_closing_expr" {
  let src =
    #|<button on:click={() => a}/>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagSelfClose(
      #|    {
      #|      tag: <StringView: "button">,
      #|      attrs: <HashMap:
      #|        { { ns: Some(<StringView: "on">), name: <StringView: "click"> }: Expr(<StringView: "() => a">) }>,
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "lexer_code_then_html" {
  let src =
    #|let a = 1
    #|<div>{() => a}</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = 1\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: "() => a">),
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_no_brace" {
  let src =
    #|let a = 1
    #|<div>() => a</div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let a = 1\n">),
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  RawText(<StringView: "() => a">),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "lexer_has_brace_html" {
  let src =
    #|let v = #{
    #|  <div>{ () => #{ <div/>}#}</div>}#
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  RawText(<StringView: "let v = ">),
      #|  HashBraceOpen,
      #|  TagOpen({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  BraceOpen,
      #|  RawText(<StringView: " () => ">),
      #|  HashBraceOpen,
      #|  TagSelfClose({ tag: <StringView: "div">, attrs: <HashMap: {}> }),
      #|  HashBraceClose,
      #|  BraceClose,
      #|  TagClose({ tag: <StringView: "div"> }),
      #|  HashBraceClose,
      #|]
    ),
  )
}

///|
test "lexer_nested_code_block_attr" {
  let src =
    #|<div value={{ a: { b: 1 } }}></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "value"> }: Expr(<StringView: "{ a: { b: 1 } }">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}

///|
test "custom_component" {
  let src =
    #|<What />
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[TagSelfClose({ tag: <StringView: "What">, attrs: <HashMap: {}> })]
    ),
  )
}

///|
test "lexer_mixed_attributes" {
  let src =
    #|<div data-count={123}></div>
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  debug_inspect(
    tokens,
    content=(
      #|[
      #|  TagOpen(
      #|    {
      #|      tag: <StringView: "div">,
      #|      attrs: <HashMap:
      #|        { { ns: None, name: <StringView: "data-count"> }: Expr(<StringView: "123">) }>,
      #|    },
      #|  ),
      #|  TagClose({ tag: <StringView: "div"> }),
      #|]
    ),
  )
}
