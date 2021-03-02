import argparse
# import model
import trainer.model as model
# import trainer.model as model
import tensorflow as tf
if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--traindata',
      help='Training data file(s)',
      required=True
  )
  parser.add_argument(
      '--evaldata',
      help='Training data can have wildcards',
      required=True
   )
  parser.add_argument(
      '--output_dir',
      help='Output directory',
      required=True
   )
  parser.add_argument(
      '--job-dir',
      help='required by gcloud',
      default='./junk'
   )
  # parse args
  args = parser.parse_args()
  arguments = args.__dict__
  traindata = arguments.pop('traindata')
  evaldata =  arguments.pop('evaldata')
  output_dir = arguments.pop('output_dir')

tf.logging.set_verbosity(tf.logging.INFO)
model.run_experiment(traindata,evaldata,output_dir)
