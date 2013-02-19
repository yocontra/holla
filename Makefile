build: components lib
	@rm -rf dist
	@mkdir -p dist
	@coffee -o dist -c lib/holla.coffee lib/Call.coffee lib/RTC.coffee
	@component build --standalone holla
	@mv build/build.js holla.js
	@rm -rf build dist
	@node_modules/.bin/uglifyjs -nc --unsafe -mt -o holla.min.js holla.js
	@echo "File size (minified): " && cat holla.min.js | wc -c
	@echo "File size (gzipped): " && cat holla.min.js | gzip -9f  | wc -c
	@cp holla.js examples/holla.js

components: component.json
	@component install --dev

clean:
	rm -rf components holla.js holla.min.js dist build