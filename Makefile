exp_counter: 
	chmod +x ./examples/counter/run.sh
	./examples/counter/run.sh

exp_page: 
	chmod +x ./examples/page/run.sh
	./examples/page/run.sh

run: 
	python3 -m http.server 8000
	
