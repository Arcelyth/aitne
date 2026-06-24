///|
suberror MbxcError {
  LexerError(String)
  ParserError(String)
} derive(Debug, Show)

///|
pub(all) enum MbxAST {
  PureCode(StringView)
  TextNode(StringView)
  DynamicNode(StringView)
  ElementNode(StringView, Array[MbxAttribute], Array[MbxAST])
} derive(Debug, Show, Eq)

///|
pub(all) struct MbxAttribute {
  name : StringView
  scope : StringView?
  value : AttrVal
} derive(Debug, Show, Eq)

///|
pub(all) enum AttrVal {
  Static(StringView)
  Dynamic(StringView)
} derive(Debug, Show, Eq)

///|
pub(all) struct Parser {
  tokens : Array[Token]
  mut cur : Int
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  Parser::{ tokens, cur: 0 }
}

///|
fn Parser::is_end(self : Parser) -> Bool {
  self.cur >= self.tokens.length()
}

///|
fn Parser::peek(self : Parser, step? : Int = 0) -> Token? {
  if self.is_end() {
    None
  } else {
    Some(self.tokens[self.cur + step])
  }
}

///|
fn Parser::advance(self : Parser) -> Unit {
  self.cur += 1
}

///|
fn Parser::parse_attributes(self : Parser) -> Array[MbxAttribute] {
  let attrs = []
//  while !self.is_end() {
//    match self.peek() {
//      Some(Token::Ident(name)) => {
//        self.advance()
//        let mut ns = None
//        let mut final_name = name
//
//        match self.peek() {
//          Some(Token::Colon) => {
//            self.advance()
//            match self.peek() {
//              Some(Token::Ident(sub_name)) => {
//                self.advance()
//                ns = Some(final_name)
//                final_name = sub_name
//              }
//              _ => ()
//            }
//          }
//          _ => ()
//        }
//
//        match self.peek() {
//          Some(Token::Equal) => {
//            self.advance()
//            match self.peek() {
//              Some(Token::AttrValue(v)) => {
//                self.advance()
//                attrs.push({
//                  name: final_name,
//                  scope: ns,
//                  value: AttrVal::Static(v),
//                })
//              }
//              Some(Token::CodeBlock(c)) => {
//                self.advance()
//                attrs.push({
//                  name: final_name,
//                  scope: ns,
//                  value: AttrVal::Dynamic(c),
//                })
//              }
//              _ => ()
//            }
//          }
//          _ =>
//            attrs.push({
//              name: final_name,
//              scope: ns,
//              value: AttrVal::Static(""),
//            })
//        }
//      }
//      _ => break
//    }
//  }
  attrs
}

///|
pub fn Parser::parse_node(self : Parser) -> MbxAST? raise MbxcError {
  guard !self.is_end() else { return None }

  match self.peek().unwrap() {
    Token::RawText(code) => {
      self.advance()
      Some(MbxAST::PureCode(code))
    }
//    Token::Start => {
//      self.advance()
//      match self.peek() {
//        Some(Token::Ident(tag)) => {
//          self.advance()
//          let attrs = self.parse_attributes()
//
//          match self.peek() {
//            Some(Token::SlashEnd) => {
//              self.advance()
//              Some(MbxAST::ElementNode(tag, attrs, []))
//            }
//            Some(Token::End) => {
//              self.advance()
//              let children = []
//
//              while !self.is_end() {
//                match self.peek() {
//                  Some(Token::Start) => {
//                    let mut is_closing = false
//
//                    if self.cur + 1 < self.tokens.length() {
//                      match self.tokens[self.cur + 1] {
//                        Token::Slash => {
//                          is_closing = true
//                          self.cur += 2
//
//                          match self.peek() {
//                            Some(Token::Ident(close_tag)) => {
//                              if close_tag != tag {
//                                raise ParserError(
//                                  "Mismatched tag! Expected </\{tag}>, found </\{close_tag}>",
//                                )
//                              }
//                              self.advance()
//
//                              match self.peek() {
//                                Some(Token::End) => self.advance()
//                                _ =>
//                                  raise ParserError(
//                                    "Expected '>' to close tag </\{tag}>",
//                                  )
//                              }
//                            }
//                            _ =>
//                              raise ParserError("Expected tag name after '</'")
//                          }
//                        }
//                        _ => ()
//                      }
//                    }
//
//                    if is_closing {
//                      break
//                    } else {
//                      match self.parse_node() {
//                        Some(child) => children.push(child)
//                        None => ()
//                      }
//                    }
//                  }
//                  Some(Token::RawText(t)) => {
//                    self.advance()
//                    children.push(MbxAST::PureCode(t))
//                  }
//                  _ =>
//                    match self.parse_node() {
//                      Some(child) => children.push(child)
//                      None => ()
//                    }
//                }
//              }
//              Some(MbxAST::ElementNode(tag, attrs, children))
//            }
//            _ =>
//              raise ParserError(
//                "Expected '>' or '/>' after attributes in <\{tag}>",
//              )
//          }
//        }
//        _ => raise ParserError("Expected valid tag name after '<'")
//      }
//    }
    _ => {
      self.advance()
      None
    }
  }
}

///|
pub fn Parser::parse(self : Parser) -> Array[MbxAST] raise MbxcError {
  let ast_list = []

  while !self.is_end() {
    match self.parse_node() {
      Some(ast) => ast_list.push(ast)
      None => ()
    }
  }

  ast_list
}
