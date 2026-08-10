exp_counter: 
	moon build ./examples/counter
	chmod +x ./examples/counter/run.sh
	./examples/counter/run.sh

exp_counter_no_mbx: 
	moon build ./examples/counter_no_mbx
	chmod +x ./examples/counter_no_mbx/run.sh
	./examples/counter_no_mbx/run.sh

exp_page: 
	moon build ./examples/page
	chmod +x ./examples/page/run.sh
	./examples/page/run.sh

exp_route: 
	moon build ./examples/route
	chmod +x ./examples/route/run.sh
	./examples/route/run.sh

exp_todo: 
	moon build ./examples/todo
	chmod +x ./examples/todo/run.sh
	./examples/todo/run.sh
	
exp_dyn: 
	moon build ./examples/dyn/
	chmod +x ./examples/dyn/run.sh
	./examples/dyn/run.sh

exp_effect: 
	moon build ./examples/effect/
	chmod +x ./examples/effect/run.sh
	./examples/effect/run.sh

exp_bench: 
	moon build ./examples/bench/
	chmod +x ./examples/bench/run.sh
	./examples/bench/run.sh

# macOS/Linux
run: 
	moon run --target=native cmd/aitne -- run 

# Windows
run_win: 
	python3 ./scripts/spa_server.py

# tests
mbxc_test: 
	moon test src/mbxc --target=native

mbxc_run: 
	moon run cmd/aitne --target=native -- mbxc

mbxc_no_tmp: 
	moon run cmd/aitne --target=native -- mbxc -n

build_cmd: 
	moon build cmd/aitne --target=native
	
build_cmd_r: 
	moon build cmd/aitne --target=native --release

# WASM targets
build_wasm:
	moon build --target=wasm-gc

build_wasm_release:
	moon build --target=wasm-gc --release

check_wasm:
	moon check --target=wasm-gc

exp_bench_wasm:
	moon build ./examples/bench --target=wasm-gc
	chmod +x ./examples/bench/run_wasm.sh
	./examples/bench/run_wasm.sh

exp_counter_wasm:
	moon build ./examples/counter --target=wasm-gc
	chmod +x ./examples/counter/run_wasm.sh
	./examples/counter/run_wasm.sh

exp_page_wasm:
	moon build ./examples/page --target=wasm-gc
	chmod +x ./examples/page/run_wasm.sh
	./examples/page/run_wasm.sh

exp_todo_wasm:
	moon build ./examples/todo --target=wasm-gc
	chmod +x ./examples/todo/run_wasm.sh
	./examples/todo/run_wasm.sh
