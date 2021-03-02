import tensorflow.estimator as tflearn
import tensorflow.contrib.layers as tflayers
import tensorflow.contrib.metrics as tfmetrics
import numpy as np
import tensorflow as tf

CSV_COLUMNS  = \
('ontime,dep_delay,taxiout,distance,avg_dep_delay,avg_arr_delay,' + \
 'carrier,dep_lat,dep_lon,arr_lat,arr_lon,origin,dest').split(',')
LABEL_COLUMN = 'ontime'
DEFAULTS     = [[0.0],[0.0],[0.0],[0.0],[0.0],[0.0],\
                ['na'],[0.0],[0.0],[0.0],[0.0],['na'],['na']]

def read_dataset(filename, mode=tf.contrib.learn.ModeKeys.EVAL,
                 batch_size=512, num_training_epochs=10):
     # the actual input function passed to TensorFlow
   def _input_fn():
      # This is double indented to make a later edit simpler
      if mode == tf.contrib.learn.ModeKeys.TRAIN:
         num_epochs = num_training_epochs
      else:
         num_epochs = 1
      # could be a path to one file or a file pattern.
      input_file_names = tf.train.match_filenames_once(filename)
      filename_queue = tf.train.string_input_producer(
          input_file_names, num_epochs=num_epochs, shuffle=True)
      # Read in and parse the CSV
      reader = tf.TextLineReader()
      _, value = reader.read_up_to(
          filename_queue, num_records=batch_size)
      value_column = tf.expand_dims(value, -1)
      columns = tf.decode_csv(value_column, record_defaults=DEFAULTS)
      features = dict(zip(CSV_COLUMNS, columns))
      label = features.pop(LABEL_COLUMN)
      return features, label
     # return input function callback.
   return _input_fn

def get_features():
    # Using three basic inputs
    real = {
      colname : tflayers.real_valued_column(colname) \
          for colname in \
            ('dep_delay,taxiout,distance').split(',')
    }
    sparse = {}
    return real, sparse

def my_rmse(labels,predictions):
    predicted_classes = predictions['probabilities'][:,1]
    custom_metric = tf.metrics.root_mean_squared_error(labels, predicted_classes,name="rmse")
    return {'rmse':custom_metric}

def linear_model(output_dir):
    real, sparse = get_features()
    all = {}
    all.update(real)
    all.update(sparse)
    estimator = tflearn.LinearClassifier(model_dir=output_dir, feature_columns=all.values())
    return estimator

def serving_input_fn():
    real, sparse = get_features()

    feature_placeholders = {
      key : tf.placeholder(tf.float32, [None]) \
        for key in real.keys()
    }
    feature_placeholders.update( {
      key : tf.placeholder(tf.string, [None]) \
        for key in sparse.keys()
    } )

    features = {
      # tf.expand_dims will insert a dimension 1 into tensor shape
      # This will make the input tensor a batch of 1
      key: tf.expand_dims(tensor, -1)
         for key, tensor in feature_placeholders.items()
    }
    return tf.estimator.export.ServingInputReceiver(
      features,
      feature_placeholders)

def run_experiment(traindata,evaldata,output_dir):
  train_input = read_dataset(traindata,\
                 mode=tf.contrib.learn.ModeKeys.TRAIN)
  # Don't shuffle evaluation data
  eval_input = read_dataset(evaldata)
  train_spec = tf.estimator.TrainSpec(train_input, max_steps=1000)
  eval_spec  = tf.estimator.EvalSpec(eval_input)
  run_config = tf.estimator.RunConfig()
  run_config = run_config.replace(model_dir=output_dir)
  print('model dir {}'.format(run_config.model_dir))
  estimator = linear_model(output_dir)

  tf.estimator.train_and_evaluate(estimator, train_spec, eval_spec)
