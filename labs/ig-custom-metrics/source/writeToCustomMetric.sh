#
# Copyright 2017 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Modified to sync up timing offset to first node startup


#!/bin/bash
if [ $# -ne 4 ]
  then
    echo "Usage $0 [PROJECTID] [INSTANCEID] [ZONEID] [TIMEOFFSET]"
    exit 1
fi
while sleep 10; do node /opt/app/autoscale_metric/writeToCustomMetric.js $1 $2 $3 $4;  done

exit 
