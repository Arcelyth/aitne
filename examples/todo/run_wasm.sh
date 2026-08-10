#!/bin/bash

target_dir="."

target_file="${target_dir}/index.html"

cat > "$target_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo Example (WASM)</title>
    <script>
      globalThis.AITNE_WASM_URL = "./_build/wasm-gc/debug/build/examples/todo/todo.wasm";
    </script>
    <script type="module" src="./runtime/wasm/glue.js"></script>
</head>
<body></body>
</html>
EOF

if [ $? -eq 0 ]; then
    echo "Created HTML file: $target_file successfully."
else
    echo "Failed to create HTML file"
    exit 1
fi
