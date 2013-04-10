build: components lib
	@rm -rf dist
	@mkdir -p dist
	@coffee -o dist -c lib/holla.coffee lib/Call.coffee lib/shims.coffee
	@component build --standalone holla
	@mv build/build.js holla.js
	@rm -rf build
	@node_modules/.bin/uglifyjs -nc --unsafe -mt -o holla.min.js holla.js
	@echo "File size (minified): " && cat holla.min.js | wc -c
	@echo "File size (gzipped): " && cat holla.min.js | gzip -9f  | wc -c
	@cp holla.js examples/holla.js
	@cp effects.css examples/effects.css


components: component.json
	@component install --dev

clean:
	rm -rf components holla.js holla.min.js dist build