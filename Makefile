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
	
exp_counter2: 
	moon run cmd/mbxc
	moon build ./examples/counter_mbx
	chmod +x ./examples/counter_mbx/run.sh
	./examples/counter_mbx/run.sh

run: 
	python3 -m http.server 8000
	
