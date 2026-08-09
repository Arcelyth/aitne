///|
#cfg(target="native")
pub async fn start_server(cfg : Config) -> Unit {
  let hmr_state = HmrState::new(
    cfg~,
    enabled=cfg.server.hmr_enabled && cfg.app.mode is Development,
  )

  @async.with_task_group(async fn(group) {
    start_hmr_watcher(hmr_state, group, ".")

    @http.Server(@socket.Addr::parse("\{cfg.server.host}:\{cfg.server.port}")).run_forever((
        request,
        _body,
        conn,
      ) => {
        let path = request.path

        if hmr_state.enabled && path == "/__hmr" {
          let is_ws = match request.headers.get("upgrade") {
            Some(v) => v.to_lower() == "websocket"
            None =>
              match request.headers.get("Upgrade") {
                Some(v) => v.to_lower() == "websocket"
                None => false
              }
          }
          if is_ws {
            let ws = @websocket.Conn::from_http_server(request, conn) catch {
              _ => {
                conn.send_response(500, "Internal Server Error")
                conn.write_string("WebSocket upgrade failed")
                return
              }
            }
            defer ws.close()

            let id = next_client_id.val
            next_client_id.val = id + 1
            hmr_state.add_client(id, ws)

            for ;; {
              let _ = ws.recv()
            }

            hmr_state.remove_client(id)
            return
          }
        }

        if is_static_asset(path) {
          let content = @fs.read_file_to_string(cfg.build.out_dir + path) catch {
            _ => {
              conn.send_response(404, "Not Found")
              conn.write_string("Asset `\{path}` not found")
              return
            }
          }
          let headers = Map::from_iter(
            [("Content-Type", get_mime_type(path))].iter(),
          )
          conn.send_response(200, "OK", extra_headers=headers)
          conn.write_string(content)
        } else {
          let html_content = @fs.read_file_to_string(
            join_paths(cfg.build.out_dir, cfg.app.entry_html),
          ) catch {
            _ => {
              conn.send_response(500, "Internal Server Error")
              conn.write_string(
                "Fatal: \{cfg.build.out_dir} \{cfg.app.entry_html} is missing.",
              )
              return
            }
          }
          let headers = Map::from_iter(
            [("Content-Type", "text/html; charset=utf-8")].iter(),
          )
          let response_html = if hmr_state.enabled {
            inject_hmr_script(html_content)
          } else {
            html_content
          }
          conn.send_response(200, "OK", extra_headers=headers)
          conn.write_string(response_html)
        }
      },
    )
  })
  hmr_state.shutdown()
}

///|
fn inject_hmr_script(html : String) -> String {
  if html.contains("</head>") {
    html.replace(old="</head>", new=hmr_client_script + "\n</head>")
  } else if html.contains("</body>") {
    html.replace(old="</body>", new=hmr_client_script + "\n</body>")
  } else {
    html + "\n" + hmr_client_script
  }
}

///|
#cfg(target="native")
fn is_static_asset(path : String) -> Bool {
  path.has_suffix(".js") ||
  path.has_suffix(".css") ||
  path.has_suffix(".png") ||
  path.has_suffix(".wasm") ||
  path.has_suffix(".ico")
}

///|
#cfg(target="native")
fn get_mime_type(path : String) -> String {
  if path.has_suffix(".js") {
    "application/javascript"
  } else if path.has_suffix(".css") {
    "text/css"
  } else if path.has_suffix(".wasm") {
    "application/wasm"
  } else if path.has_suffix(".png") {
    "image/png"
  } else {
    "application/octet-stream"
  }
}

///|
#cfg(target="native")
fn join_paths(base : String, relative : String) -> String {
  if base.length() == 0 {
    return relative
  }
  if relative.length() == 0 {
    return base
  }
  let base_has_slash = base.has_suffix("/")
  let rel_has_slash = relative.has_prefix("/")
  if base_has_slash && rel_has_slash {
    base + relative[1:relative.length()].to_owned()
  } else if !base_has_slash && !rel_has_slash {
    base + "/" + relative
  } else {
    base + relative
  }
}
