///|
using @hashmap {type HashMap}

///|
test "parse valid mbx node with attributes and dynamic expression" {
  let div_attrs = HashMap([])
  div_attrs.set(
    TokenAttr::{ ns: None, name: "eat" },
    AttrValue::Expr("() => omg()"),
  )

  let tokens = [
    // <div eat={() => omg()}> {() => <div/>} </div>
    Token::TagOpen({ tag: "div", attrs: div_attrs }),
    Token::RawText(" "),
    Token::BraceOpen,
    Token::RawText("() => "),
    Token::TagSelfClose({ tag: "div", attrs: HashMap([]) }),
    Token::BraceClose,
    Token::RawText(" "),
    Token::TagClose({ tag: "div" }),
  ]

  let parser = Parser::new(tokens)
  let result = parser.parse()

  inspect(
    result,
    content="[ElementNode(div, HashMap::from_array([({ns: None, name: eat}, Expr(() => omg()))]), [RawText( ), DynamicCode([PureCode(() => ), ElementNode(div, HashMap::from_array([]), [])]), RawText( )])]",
  )
}
