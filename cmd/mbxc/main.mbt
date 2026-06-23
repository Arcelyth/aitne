///| 
pub fn walk_and_compile(dir : String, show? : Bool = false, tmp? : Bool = false) -> Unit raise @fs.IOError {
  let entries = try? @fs.read_dir(dir)
  match entries {
    Ok(files) => {
      for file in files {
        if file == "." || file == ".." {
          continue
        }

        let path = dir + "/" + file
        
        if @fs.is_dir(path) {
          walk_and_compile(path, show=show, tmp=tmp)
        } else if path.has_suffix(".mbx") {
          let target = path[0:path.length()] + ".mbt"
          let _ = @mbxc.from_file(path, show=show, to=Some(target.to_owned()), tmp=tmp)
        }
      }
    }
    Err(e) => {
      debug(e)
    }
  }
}

///| 
fn main() -> Unit {
  let args = @sys.get_cli_args()
  let mut show = false
  let mut tmp = false
  let mut target_dir = "."

  for i = 1; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "-show" {
      show = true
    } else if arg == "-template" {
      tmp = true 
    } else {
      target_dir = arg
    }
  }

  let res = try? walk_and_compile(target_dir, show=show, tmp=tmp)
  match res {
    Ok(_) => ()
    Err(e) => debug(e)
  }
}
