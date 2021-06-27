compile: compile-debug compile-prod

compile-debug:
	dart2js -o lib/src/worker/worker.dart.js lib/src/worker/worker.dart -m

compile-prod:
	dart2js -o example/web/lib/src/worker/worker.dart.js lib/src/worker/worker.dart -m
