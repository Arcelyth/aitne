///|
let next_client_id : Ref[Int] = { val: 0 }

///|
pub(all) struct HmrState {
  mut clients : Array[(Int, @websocket.Conn)]
  mut watcher : @async_fs.Watcher?
  cfg : Config
  enabled : Bool
}

///|
let hmr_client_script : String =
  #| <script>
  #| (function connect(){
  #|   var ws=new WebSocket("ws://"+location.host+"/__hmr");
  #|   ws.onmessage=function(ev){if(ev.data==="reload")location.reload();};
  #|   ws.onclose=function(){setTimeout(connect,1000);};
  #| })();
  #| </script>

///|
pub fn HmrState::new(cfg~ : Config, enabled~ : Bool) -> HmrState {
  { clients: [], watcher: None, cfg, enabled }
}

///|
pub fn HmrState::shutdown(self : HmrState) -> Unit {
  match self.watcher {
    Some(w) => {
      w.close()
      self.watcher = None
    }
    None => ()
  }
}

///|
pub fn HmrState::add_client(
  self : HmrState,
  id : Int,
  ws : @websocket.Conn,
) -> Unit {
  self.clients.push((id, ws))
}

///|
pub fn HmrState::remove_client(self : HmrState, id : Int) -> Unit {
  let alive : Array[(Int, @websocket.Conn)] = []
  for item in self.clients {
    if item.0 != id {
      alive.push(item)
    }
  }
  self.clients = alive
}

///|
pub async fn HmrState::broadcast(self : HmrState, msg : String) -> Unit {
  let current = self.clients.copy()
  for item in current {
    let (id, client) = item
    client.send_text(msg) catch {
      _ => self.remove_client(id)
    }
  }
}

///|
pub fn start_hmr_watcher(
  state : HmrState,
  group : @async.TaskGroup[Unit],
  watch_dir : String,
) -> Unit {
  if !state.enabled {
    return
  }
  group.spawn_bg(async fn() {
    try {
      let watcher = @async_fs.Watcher::Watcher(
        watch_dir,
        debounce_timeout=300,
        max_debounce_delay=1000,
        ignored_paths=fn(path) {
          path.contains("_build/") ||
          path.contains(".mooncakes/") ||
          path.contains(".git/") ||
          path.contains("dist/") ||
          path.contains("target/") ||
          path.has_suffix(".DS_Store") ||
          path.has_suffix(".mbx.mbt") ||
          path.has_suffix("~") ||
          path.has_suffix(".swp") ||
          path.has_suffix(".swx")
        },
      ) catch {
        err => {
          println("HMR: watcher init failed: \{err}")
          return
        }
      }
      println("[Debug]HMR watcher created.")
      state.watcher = Some(watcher)

      for _i = 0; _i < 999999; _i = _i + 1 {
        let w = match state.watcher {
          Some(w) => w
          None => break
        }
        let events = w.wait() catch {
          err => {
            if @async.is_cancellation_error(err) {
              break
            }
            continue
          }
        }

        let mut trigger = ""
        for event in events {
          let path = match event {
            @async_fs.FsEvent::Modify(p) | @async_fs.FsEvent::Create(p) => p
            _ => continue
          }

          let is_mbt = path.has_suffix(".mbt") && !path.has_suffix(".mbx.mbt")
          let is_mbx = path.has_suffix(".mbx")
          let is_css = path.has_suffix(".css")

          if is_mbt || is_mbx || is_css {
            trigger = path
            break
          }
        }

        if trigger != "" {
          println("HMR: \{trigger} changed")

          build_project(state.cfg) catch {
            err => println("HMR: build failed: \{err}")
          }

          state.broadcast("reload")
        }
      }
    } catch {
      err => println("HMR: watcher error: \{err}")
    }
  })
}
