.PHONY: run build deploy deploy-firestore

run:
	flutter run -d chrome

build:
	flutter build web --release

deploy: build
	firebase deploy --only hosting

deploy-firestore:
	firebase deploy --only firestore:rules,firestore:indexes
