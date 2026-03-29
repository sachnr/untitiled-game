run:
	odin run src -debug

test:
	odin test src -debug -all-packages

build:
    mkdir bin
    odin build src -debug -out:bin/app

valgrind:
    valgrind \
    --tool=memcheck \
    --track-origins=yes \
    --leak-check=full \
    --show-leak-kinds=all \
    --errors-for-leak-kinds=definite \
    ./bin/app
