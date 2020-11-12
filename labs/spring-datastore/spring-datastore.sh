# Spring Boot application with Cloud Datastore

gcloud auth list
gcloud config list project
export PROJECT=$(gcloud config get-value project)
export REGION=us-east1

# Initialize and bootstrap a new Spring Boot application
curl https://start.spring.io/starter.tgz \
  -d packaging=war \
  -d dependencies=cloud-gcp \
  -d baseDir=datastore-example \
  -d bootVersion=2.1.1.RELEASE | tar -xzvf -

# Modify the pom.xml file to add the Spring Data Cloud Datastore Spring Boot starter dependency
cat pom.xml > datastore-example/pom.xml
# Create the BookRepository interface
cp BookRepository.java datastore-example/src/main/java/com/example/demo/
# Create the interactive CLI application
cat DemoApplication.java > datastore-example/src/main/java/com/example/demo/DemoApplication.java

mvn spring-boot:run
