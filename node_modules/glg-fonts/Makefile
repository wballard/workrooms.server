.PHONY: build

build:
	[ -d build ] || mkdir build
	./bin/fontify.litcoffee ./fonts src/grotesk.less > build/grotesk.less
	lessc build/grotesk.less build/grotesk.css
	cp src/glg.less build/glg.less
	lessc build/glg.less build/glg.css
