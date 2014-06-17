.PHONY: build

build:
	[ -d build ] || mkdir build
	./bin/fontify.litcoffee ./fonts src/anonymous-pro.less > build/anonymous-pro.less
	lessc build/anonymous-pro.less build/anonymous-pro.css
	./bin/fontify.litcoffee ./fonts src/font-awesome.less > build/font-awesome.less
	lessc build/font-awesome.less build/font-awesome.css
	cp src/font-awesome-styles.less build/font-awesome-styles.less
	lessc build/font-awesome-styles.less build/font-awesome-styles.css
