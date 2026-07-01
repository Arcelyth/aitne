exp_counter: 
	moon build ./examples/counter
	chmod +x ./examples/counter/run.sh
	./examples/counter/run.sh

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
	
# use mbx format
exp_counter2: 
	moon run cmd/mbxc
	moon build ./examples/counter_mbx
	chmod +x ./examples/counter_mbx/run.sh
	./examples/counter_mbx/run.sh

exp_page2: 
	moon build ./examples/page_mbx
	chmod +x ./examples/page_mbx/run.sh
	./examples/page_mbx/run.sh

exp_todo2: 
	moon build ./examples/todo_mbx
	chmod +x ./examples/todo_mbx/run.sh
	./examples/todo_mbx/run.sh

exp_route2: 
	moon build ./examples/route_mbx
	chmod +x ./examples/route_mbx/run.sh
	./examples/route_mbx/run.sh

# macOS/Linux
run: 
	moon run --target=native cmd/aitne -- run 

# Windows
run_win: 
	python3 ./scripts/spa_server.py

# tests
mbxc_test: 
	moon test src/mbxc --target=native
