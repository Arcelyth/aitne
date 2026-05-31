exp_counter: 
	chmod +x ./examples/counter/run.sh
	./examples/counter/run.sh

run: 
	python3 -m http.server 8000
	
