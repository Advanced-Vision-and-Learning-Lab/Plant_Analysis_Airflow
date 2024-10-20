#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_airflow_cfg> <path_to_dags_folder>"
    exit 1
fi

# Assign input arguments to variables
AIRFLOW_CFG_PATH=$1
DAGS_FOLDER_PATH=$2

echo "Updating Airflow configuration..."

# Update the dags_folder in the airflow.cfg file
sed -i "s|^dags_folder =.*|dags_folder = $DAGS_FOLDER_PATH|" "$AIRFLOW_CFG_PATH"

echo "Successfully updated dags_folder to $DAGS_FOLDER_PATH in $AIRFLOW_CFG_PATH"

# Optionally restart Airflow services
# Uncomment the following lines if you want to restart Airflow automatically
# echo "Restarting Airflow services..."
# airflow scheduler
# airflow webserver

echo "Setup completed."
