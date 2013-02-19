build: components lib
	@rm -rf dist
	@mkdir dist
	@coffee -o dist/ -c lib/main.coffee lib/defaultClient.coffee lib/Client.coffee lib/Socket.coffee lib/util.coffee
	@component build --standalone ProtoSock
	@mv build/build.js protosock.js
	@rm -rf build
	@node_modules/.bin/uglifyjs -nc --unsafe -mt -o protosock.min.js protosock.js
	@echo "File size (minified): " && cat protosock.min.js | wc -c
	@echo "File size (gzipped): " && cat protosock.min.js | gzip -9f  | wc -c

components: component.json
	@component install --dev

clean:
	rm -fr components