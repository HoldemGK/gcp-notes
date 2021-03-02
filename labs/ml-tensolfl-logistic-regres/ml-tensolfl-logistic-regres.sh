gcloud compute ssh vminst
sudo apt -y update
sudo apt -y upgrade
sudo apt -y install git
git clone  https://github.com/GoogleCloudPlatform/data-science-on-gcp/
sudo apt-get install -y python-pip python-dev python3-pip python3-dev virtualenv
sudo pip install virtualenv
virtualenv -p python3 venv
source venv/activate
pip install tensorflow==1.15.2

#Create minimal training and test datasets
mkdir -p ~/data/flights
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export BUCKET=${PROJECT_ID}
#Create the training data set by extracting about 10000 records
gsutil cp \
  gs://${BUCKET}/flights/chapter8/output/trainFlights-00001*.csv \
  full.csv
head -10003 full.csv > ~/data/flights/train.csv
rm full.csv
#Create the test data set
gsutil cp \
  gs://${BUCKET}/flights/chapter8/output/testFlights-00001*.csv \
  full.csv
head -10003 full.csv > ~/data/flights/test.csv
rm full.csv

#Create a TensorFlow experimental framework in Python
mkdir ~/tensorflow
cd ~/tensorflow/
mkdir flights
cd flights
mkdir trainer
cd trainer
touch __init__.py
nano -w model.py
nano -w task.py
python task.py --traindata ~/data/flights/train.csv
nano -w model.py
nano -w task.py
python task.py \
       --traindata ~/data/flights/train.csv \
       --output_dir ./trained_model \
       --evaldata ~/data/flights/test.csv

pushd ~/data-science-on-gcp/09_cloudml/flights/
cp PKG-INFO ~/tensorflow/flights
cp setup.cfg ~/tensorflow/flights
cp setup.py ~/tensorflow/flights
popd
nano -w ~/tensorflow/flights/setup.py
export PYTHONPATH=${PYTHONPATH}:~/tensorflow/flights
cd ~/tensorflow
export DATA_DIR=~/data/flights

python -m trainer.task \
  --output_dir=./trained_model \
  --traindata $DATA_DIR/train* --evaldata $DATA_DIR/test*

nano ~/tensorflow/flights/trainer/task.py
nano -w ~/tensorflow/flights/trainer/model.py
rm -rf trained_model/

python -m trainer.task \
  --output_dir=./trained_model \
  --traindata $DATA_DIR/train* --evaldata $DATA_DIR/test*

nano -w ~/tensorflow/flights/trainer/model.py
rm -rf trained_model/

python -m trainer.task \
  --output_dir=./trained_model \
  --traindata $DATA_DIR/train* --evaldata $DATA_DIR/test*

nano -w ~/tensorflow/flights/trainer/model.py
rm -rf trained_model/

python -m trainer.task \
  --output_dir=./trained_model \
  --traindata $DATA_DIR/train* --evaldata $DATA_DIR/test*

export PROJECT_ID=$(gcloud info --format='value(config.project)')
export BUCKET=$PROJECT_ID
export REGION=us-central1
export OUTPUT_DIR=gs://${BUCKET}/flights/chapter9/output
export DATA_DIR=gs://${BUCKET}/flights/chapter8/output
export JOBNAME=flights_$(date -u +%y%m%d_%H%M%S)
cd ~/tensorflow

gcloud ai-platform jobs submit training $JOBNAME \
  --module-name=trainer.task \
  --package-path=$(pwd)/flights/trainer \
  --job-dir=$OUTPUT_DIR \
  --staging-bucket=gs://$BUCKET \
  --region=$REGION \
  --scale-tier=STANDARD_1 \
  --python-version=3.5 \
  --runtime-version=1.14 \
  -- \
  --output_dir=$OUTPUT_DIR \
  --traindata $DATA_DIR/train* --evaldata $DATA_DIR/test*
