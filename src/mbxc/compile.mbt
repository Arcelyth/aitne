using @hashset {type HashSet}
///|
pub fn from_file(
  path : String,
  show? : Bool = false,
  to? : String? = None,
  tmp? : Bool = false,
) -> String? {
  let res = try? @fs.read_file_to_string(path)
  match res {
    Ok(content) => {
      let lexer = Lexer::new(content)
      let tokens = match (try? lexer.tokenizer()) {
        Ok(ts) => ts
        Err(e) => {
          debug(e)
          panic()
        }
      }
      if show {
        debug(tokens)
      }
      let parser = Parser::new(tokens)

      let asts = try! parser.parse()
      if show {
        debug(asts)
      }

      let gen = if tmp {
        let codegen = CodeGenTmp::new(asts)
        codegen.generate()
      } else {
        let codegen = CodeGen::new()
        codegen.generate(asts)
      }
      match to {
        Some(target) => {
          let res2 = try? @fs.write_string_to_file(target, gen)
          match res2 {
            Ok(_) => Some(gen)
            Err(e) => {
              debug(e)
              None
            }
          }
        }
        None => Some(gen)
      }
    }
    Err(e) => {
      debug(e)
      None
    }
  }
}
