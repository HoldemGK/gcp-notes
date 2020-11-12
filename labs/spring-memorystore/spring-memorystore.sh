# Cache data from a Spring Boot app with Memorystore

gcloud auth list
gcloud config list project
export PROJECT=$(gcloud config get-value project)
export REGION=us-central1
export ZONE=${REGION}-c

gcloud redis instances create myinstance --size=1 --region=$REGION
gcloud redis instances describe myinstance --region=$REGION | grep host
gcloud compute instances create instance-1 --zone=$ZONE
gcloud compute ssh instance-1
sudo apt-get install openjdk-11-jdk-headless maven telnet
curl https://start.spring.io/starter.tgz \
  -d dependencies=web,redis,cache \
  -d language=java \
  -d baseDir=cache-app \
  | tar -xzvf - $$ cd cache-app

# Edit the application.properties file to configure the app to use the IP address of the Memorystore instance for Redis host
cat application.properties > src/main/resources/application.properties
cat HelloWorldController.java > datastore-example/src/main/java/com/example/demo/HelloWorldController.java
cat DemoApplication.java > datastore-example/src/main/java/com/example/demo/DemoApplication.java
mvn spring-boot:run
