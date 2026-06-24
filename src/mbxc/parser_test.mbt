///|
test "parser_basic_and_nested" {
  // <div>hello <img src="a.png"/></div>
  let tokens = [
    Token::TagOpen({ tag: "div", attrs: HashMap([]) }),
    Token::RawText("hello "),
    Token::TagSelfClose({
      tag: "img",
      attrs: HashMap([({ ns: None, name: "src" }, "a.png")]),
    }),
    Token::TagClose({ tag: "div" }),
  ]

  let parser = Parser::new(tokens)
  let ast = parser.parse()

  inspect(
    ast,
    content="[ElementNode(div, HashMap::from_array([]), [PureCode(hello ), ElementNode(img, HashMap::from_array([({ns: None, name: src}, a.png)]), [])])]",
  )
}

///|
test "parser_embedded_code_blocks" {
  // let v = #{ <div>{ () => #{ <div /> }# }</div> }#
  let tokens = [
    Token::RawText("let v = "),
    Token::HashBraceOpen,
    Token::TagOpen({ tag: "div", attrs: HashMap([]) }),
    Token::BraceOpen,
    Token::RawText(" () => "),
    Token::HashBraceOpen,
    Token::TagSelfClose({ tag: "div", attrs: HashMap([]) }),
    Token::HashBraceClose,
    Token::BraceClose,
    Token::TagClose({ tag: "div" }),
    Token::HashBraceClose,
  ]

  let parser = Parser::new(tokens)
  let ast = parser.parse()

  inspect(
    ast,
    content="[PureCode(let v = ), ElementNode(div, HashMap::from_array([]), [PureCode( () => ), ElementNode(div, HashMap::from_array([]), [])])]",
  )
}
