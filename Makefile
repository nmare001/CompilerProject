parse: mini_l3.lex mini_l3.y
	bison -v -d --file-prefix=y mini_l3.y
	flex mini_l3.lex 
	gcc -o parser y.tab.c lex.yy.c -lfl
		
clean:
	rm -f lex.yy.c parser y.tab.c y.tab.h y.output