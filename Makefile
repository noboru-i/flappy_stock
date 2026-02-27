.PHONY: run build deploy

run:
	flutter run -d chrome

build:
	flutter build web --release

deploy: build
	firebase deploy --only hosting
