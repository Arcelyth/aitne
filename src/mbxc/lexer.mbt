///|
using @hashmap {type HashMap}

///|
pub(all) struct TokenAttr {
  ns : StringView?
  name : StringView
} derive(Debug, Eq, Hash)

///|
/// <div style="">
pub(all) struct TagOpen {
  tag : StringView
  attrs : HashMap[TokenAttr, AttrValue]
} derive(Debug, Eq)

///|
/// </div>
pub(all) struct TagClose {
  tag : StringView
} derive(Debug, Eq)

///|
/// <div />
pub(all) struct TagSelfClose {
  tag : StringView
  attrs : HashMap[TokenAttr, AttrValue]
} derive(Debug, Eq)

///|
/// <!
pub struct DocTag {} derive(Debug, Eq)

///|
pub(all) enum Token {
  TagOpen(TagOpen)
  TagClose(TagClose)
  TagSelfClose(TagSelfClose)
  DocTag(DocTag)
  RawText(StringView)
  CodeBlock(StringView)
  BraceOpen // {
  BraceClose // }
  HashBraceOpen // #{
  HashBraceClose // }#
} derive(Debug, Eq)

///|
pub(all) enum AttrValue {
  Str(StringView)
  Expr(StringView)
} derive(Debug, Eq)

///|
pub(all) struct Lexer {
  src : String
  mut cur : Int
  mut brace_depth : Int
  mut tag_depth : Int
  mut in_closing_tag : Bool
}

///|
pub fn Lexer::new(src : String) -> Lexer {
  Lexer::{ src, cur: 0, brace_depth: 0, tag_depth: 0, in_closing_tag: false }
}

///|
pub fn Lexer::is_end(self : Lexer) -> Bool {
  self.cur >= self.src.length()
}

///|
pub fn Lexer::peek(self : Lexer, count : Int) -> UInt16? {
  if self.cur + count >= self.src.length() {
    None
  } else {
    Some(self.src[self.cur + count])
  }
}

///|
#inline
fn is_ident_char(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
#inline
fn is_tag_start_char(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn Lexer::is_raw_boundary(self : Lexer, c : UInt16) -> Bool {
  if c == '#' && self.peek(1) == Some('{') {
    return true
  }
  if c == '}' && self.peek(1) == Some('#') {
    return true
  }

  if self.tag_depth > 0 && (c == '{' || c == '}') {
    return true
  }

  if c == '<' {
    match self.peek(1) {
      Some('/') => return true
      Some('!') => return true
      Some(next) if is_tag_start_char(next) => return true
      _ => return false
    }
  }

  false
}

///|
fn Lexer::read_code_block(self : Lexer) -> StringView raise MbxcError {
  if self.src[self.cur] != '{' {
    raise LexerError("read_code_block expects '{' at current position")
  }

  let start = self.cur + 1
  self.cur += 1
  self.brace_depth = 1

  while !self.is_end() && self.brace_depth > 0 {
    let c = self.src[self.cur]

    if c == '\"' || c == '\'' {
      let quote = c
      self.cur += 1
      while !self.is_end() && self.src[self.cur] != quote {
        if self.src[self.cur] == '\\' && self.cur + 1 < self.src.length() {
          self.cur += 2
        } else {
          self.cur += 1
        }
      }
      if self.is_end() {
        raise LexerError("Unclosed string literal in code block")
      }
      self.cur += 1
      continue
    }

    if c == '/' && self.peek(1) == Some('/') {
      self.cur += 2
      while !self.is_end() && self.src[self.cur] != '\n' {
        self.cur += 1
      }
      if !self.is_end() {
        self.cur += 1
      }
      continue
    }

    if c == '{' {
      self.brace_depth += 1
      self.cur += 1
      continue
    }

    if c == '}' {
      self.brace_depth -= 1
      self.cur += 1
      continue
    }

    self.cur += 1
  }

  if self.brace_depth > 0 {
    raise LexerError("Unclosed code block: expected '}'")
  }

  self.brace_depth = 0
  return self.src[start:self.cur - 1]
}

///|
fn is_space(c : UInt16) -> Bool {
  match c {
    ' ' | '\n' | '\r' | '\t' => true
    _ => false
  }
}

///|
pub fn Lexer::scan_comment(self : Lexer) -> Unit {
  while !self.is_end() && self.src[self.cur] != '\n' {
    self.cur += 1
  }
  if !self.is_end() {
    self.cur += 1
  }
}

///|
pub fn Lexer::scan_string(self : Lexer) -> Unit raise MbxcError {
  while !self.is_end() && self.src[self.cur] != '"' {
    self.cur += 1
  }
  if self.is_end() {
    raise LexerError("Unclosed string literal in MoonBit block")
  } else {
    self.cur += 1
  }
}

///|
pub fn Lexer::next_token(self : Lexer) -> Token? raise MbxcError {
  guard !self.is_end() else { return None }

  let start = self.cur
  match self.src[self.cur] {
    // #{ 
    '#' if self.peek(1) == Some('{') => {
      self.cur += 2
      while !self.is_end() && self.src[self.cur] != '<' {
        self.cur += 1
      }
      if self.is_end() {
        raise LexerError("Expected match tag in #{}#")
      }
      return Some(Token::HashBraceOpen)
    }
    '{' if self.tag_depth > 0 => {
      self.cur += 1
      self.brace_depth += 1
      return Some(Token::BraceOpen)
    }
    // }# 
    '}' if self.peek(1) == Some('#') => {
      self.cur += 2
      return Some(Token::HashBraceClose)
    }
    '}' if self.tag_depth > 0 => {
      self.cur += 1
      self.brace_depth -= 1
      return Some(Token::BraceClose)
    }
    '<' =>
      match self.peek(1) {
        Some('!') => {
          self.cur += 2
          while !self.is_end() && self.src[self.cur] != '>' {
            self.cur += 1
          }
          if !self.is_end() {
            self.cur += 1
          }
          return Some(Token::DocTag(DocTag::{  }))
        }
        Some('/') => {
          self.cur += 2
          while !self.is_end() && is_space(self.src[self.cur]) {
            self.cur += 1
          }
          let tag_start = self.cur
          while !self.is_end() && is_ident_char(self.src[self.cur]) {
            self.cur += 1
          }
          let tag = self.src[tag_start:self.cur]

          while !self.is_end() && is_space(self.src[self.cur]) {
            self.cur += 1
          }
          if self.is_end() || self.src[self.cur] != '>' {
            raise LexerError("Expected '>' after closing tag")
          }
          self.cur += 1

          if self.tag_depth > 0 {
            self.tag_depth -= 1
          }
          return Some(Token::TagClose(TagClose::{ tag, }))
        }
        Some(next) if is_tag_start_char(next) => {
          self.cur += 1
          while !self.is_end() && is_space(self.src[self.cur]) {
            self.cur += 1
          }

          let tag_start = self.cur
          while !self.is_end() && is_ident_char(self.src[self.cur]) {
            self.cur += 1
          }
          let tag = self.src[tag_start:self.cur]

          let attrs : HashMap[TokenAttr, AttrValue] = HashMap([])

          while !self.is_end() {
            while !self.is_end() && is_space(self.src[self.cur]) {
              self.cur += 1
            }
            if self.is_end() {
              break
            }
            let ch = self.src[self.cur]
            if ch == '/' || ch == '>' {
              break
            }

            // Parse attribute name and optional namespace
            let ns_start = self.cur
            while !self.is_end() && is_ident_char(self.src[self.cur]) {
              self.cur += 1
            }
            let mut ns = None
            let mut name = self.src[ns_start:self.cur]

            if !self.is_end() && self.src[self.cur] == ':' {
              self.cur += 1
              ns = Some(name)
              let name_start = self.cur
              while !self.is_end() && is_ident_char(self.src[self.cur]) {
                self.cur += 1
              }
              name = self.src[name_start:self.cur]
            }

            while !self.is_end() && is_space(self.src[self.cur]) {
              self.cur += 1
            }

            let mut val_attr = AttrValue::Str(self.src[self.cur:self.cur])

            if !self.is_end() && self.src[self.cur] == '=' {
              self.cur += 1
              while !self.is_end() && is_space(self.src[self.cur]) {
                self.cur += 1
              }

              if !self.is_end() {
                let quote_c = self.src[self.cur]
                if quote_c == '"' || quote_c == '\'' {
                  let quote = quote_c
                  self.cur += 1
                  let val_start = self.cur
                  while !self.is_end() && self.src[self.cur] != quote {
                    if self.src[self.cur] == '\\' &&
                      self.cur + 1 < self.src.length() {
                      self.cur += 2
                    } else {
                      self.cur += 1
                    }
                  }
                  if self.is_end() {
                    raise LexerError("Unclosed attribute value")
                  }
                  val_attr = AttrValue::Str(self.src[val_start:self.cur])
                  self.cur += 1 // skip quote
                } else if quote_c == '{' {
                  val_attr = AttrValue::Expr(self.read_code_block())
                } else {
                  // unquoted attribute value
                  let val_start = self.cur
                  while !self.is_end() &&
                        !is_space(self.src[self.cur]) &&
                        self.src[self.cur] != '/' &&
                        self.src[self.cur] != '>' {
                    self.cur += 1
                  }
                  val_attr = AttrValue::Str(self.src[val_start:self.cur])
                }
              }
            }

            attrs.set(TokenAttr::{ ns, name }, val_attr)
          }

          if !self.is_end() && self.src[self.cur] == '/' {
            if self.peek(1) == Some('>') {
              self.cur += 2
              return Some(Token::TagSelfClose(TagSelfClose::{ tag, attrs }))
            } else {
              raise LexerError("Expected '>' after '/'")
            }
          } else if !self.is_end() && self.src[self.cur] == '>' {
            self.cur += 1
            self.tag_depth += 1
            return Some(Token::TagOpen(TagOpen::{ tag, attrs }))
          } else {
            raise LexerError("Unexpected character in tag")
          }
        }
        _ => return None
      }
    _ => {
      while !self.is_end() {
        let next_c = self.src[self.cur]
        if next_c == '"' {
          self.cur += 1
          try! self.scan_string()
          continue
        }
        if next_c == '/' && self.peek(1) == Some('/') {
          self.cur += 2
          try! self.scan_comment()
          continue
        }
        if self.is_raw_boundary(next_c) {
          break
        }
        self.cur += 1
      }
      return Some(Token::RawText(self.src[start:self.cur]))
    }
  }
}

///|
pub fn Lexer::tokenizer(self : Lexer) -> Array[Token] raise MbxcError {
  let tokens = []
  while true {
    match self.next_token() {
      Some(t) => tokens.push(t)
      None => break
    }
  }
  tokens
}
