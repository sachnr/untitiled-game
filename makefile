.PHONY: debug test release clean

debug:
	odin build src -out:game -debug
	./game

test:
	odin run src -debug

release:
	odin build src -out:game -o:speed

clean:
	rm -f game game.exe
