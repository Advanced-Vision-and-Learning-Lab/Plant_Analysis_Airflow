#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <path_to_airflow_cfg> [<path_to_dags_folder>] <path_to_repo>"
    exit 1
fi

# Assign input arguments to variables
AIRFLOW_CFG_PATH=$1

# Set the repository path
if [ "$#" -eq 3 ]; then
    REPO_PATH=$3
elif [ "$#" -eq 2 ]; then
    REPO_PATH=$2
else
    echo "Error: Repository path is required."
    exit 1
fi

# Default the DAGs folder to the repository path if not provided
if [ "$#" -eq 3 ]; then
    DAGS_FOLDER_PATH=$2
else
    DAGS_FOLDER_PATH=$REPO_PATH
fi

echo "Updating Airflow configuration..."

# Update the dags_folder in the airflow.cfg file
sed -i "s|^dags_folder =.*|dags_folder = $DAGS_FOLDER_PATH|" "$AIRFLOW_CFG_PATH"

echo "Successfully updated dags_folder to $DAGS_FOLDER_PATH in $AIRFLOW_CFG_PATH"

# Set the PROJECT_HOME environment variable
echo "Setting PROJECT_HOME to $REPO_PATH"
export PROJECT_HOME=$REPO_PATH

# Add the PROJECT_HOME environment variable to .bashrc for future sessions
if ! grep -q "export PROJECT_HOME=$REPO_PATH" ~/.bashrc; then
    echo "export PROJECT_HOME=$REPO_PATH" >> ~/.bashrc
    echo "PROJECT_HOME environment variable added to .bashrc"
else
    echo "PROJECT_HOME is already set in .bashrc"
fi

# Generate the latest requirements.txt from requirements.in
if [ -f "$REPO_PATH/requirements.in" ]; then
    echo "Generating requirements.txt from requirements.in..."
    pip install pip-tools
    pip-compile "$REPO_PATH/requirements.in" -o "$REPO_PATH/requirements.txt"
else
    echo "No requirements.in file found in $REPO_PATH. Skipping requirements generation."
fi

# Install dependencies from requirements.txt
if [ -f "$REPO_PATH/requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r "$REPO_PATH/requirements.txt"
else
    echo "No requirements.txt file found. Skipping dependency installation."
fi

# Optionally restart Airflow services
# Uncomment the following lines if you want to restart Airflow automatically
# echo "Restarting Airflow services..."
# airflow scheduler
# airflow webserver

echo "Setup completed."
