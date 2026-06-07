///| 
pub fn walk_and_compile(dir : String) -> Unit raise @fs.IOError{
  let entries = try? @fs.read_dir(dir)
  match entries {
    Ok(files) => {
      for file in files {
        if file == "." || file == ".." {
          continue
        }

        let path = dir + "/" + file
        
        if @fs.is_dir(path) {
          walk_and_compile(path)
        } else if path.has_suffix(".mbx") {
          let target = path[0:path.length()] + ".mbt"
          let _ = @mbxc.from_file(path, show=false, to=Some(target.to_owned()))
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
  
  let target_dir = if args.length() > 2 {
    args[args.length() - 1]
  } else {
    "."
  }

  let res = try? walk_and_compile(target_dir)
  match res {
    Ok(_) => ()
    Err(e) => debug(e)
  }
}
