#!/bin/bash

# Function to handle errors, log them, and exit
handle_error() {
    echo "Error: $1" | tee -a "$MAIN_LOG"
    exit 1
}

# Capture the directory of the script before changing to SETUP_DIR
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Check if a custom working directory is provided as the first argument
if [ -n "$1" ]; then
    CUSTOM_HOME="$1"
    echo "Custom working directory provided: $CUSTOM_HOME" | tee -a "$MAIN_LOG"
else
    # Default to using $HOME if no custom directory is provided
    CUSTOM_HOME="$HOME"
    echo "No custom working directory provided. Using default HOME: $CUSTOM_HOME" | tee -a "$MAIN_LOG"
fi

# Set up the directory for the setup
SETUP_DIR="$CUSTOM_HOME/plant_analysis_setup"
mkdir -p "$SETUP_DIR" || handle_error "Failed to create setup directory at $SETUP_DIR"

# Change to SETUP_DIR for installation purposes
cd "$SETUP_DIR" || handle_error "Failed to change to setup directory"
echo "Setup directory: $SETUP_DIR" | tee -a "$MAIN_LOG"

# Create log files inside the setup directory
MAIN_LOG="$SETUP_DIR/setup_main.log"
VENV_LOG="$SETUP_DIR/setup_venv.log"
PIP_LOG="$SETUP_DIR/setup_pip.log"
# Overwrite logs at the start of each new run
echo "Starting setup in $SETUP_DIR..." > "$MAIN_LOG"
echo "" > "$VENV_LOG"  # Clear virtual environment log
echo "" > "$PIP_LOG"   # Clear pip log
echo "Starting setup in $SETUP_DIR..." | tee -a "$MAIN_LOG"

# Install virtualenv if not already installed
echo "Checking if virtualenv is installed..." | tee -a "$MAIN_LOG"
python3 -m pip install virtualenv >> "$VENV_LOG" 2>&1 || handle_error "Failed to install virtualenv"

# Create a virtual environment in the setup directory
VENV_DIR="$SETUP_DIR/plant_analysis_env"
echo "Creating a virtual environment in $VENV_DIR..." | tee -a "$MAIN_LOG"
python3 -m virtualenv "$VENV_DIR" >> "$VENV_LOG" 2>&1 || handle_error "Failed to create virtual environment"

# Activate the virtual environment
source "$VENV_DIR/bin/activate" >> "$VENV_LOG" 2>&1 || handle_error "Failed to activate virtual environment"
echo "Virtual environment created and activated." | tee -a "$MAIN_LOG"

# Check if an argument was provided for Airflow version
AIRFLOW_VERSION=${2:-2.10.2} # Default to 2.10.2 if no argument is provided for Airflow version

# Set up Airflow installation with constraints
echo "Installing Apache Airflow version ${AIRFLOW_VERSION}..." | tee -a "$MAIN_LOG"

# Get Python version and the corresponding constraint URL
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# Install Airflow
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}" >> "$PIP_LOG" 2>&1 || handle_error "Failed to install Apache Airflow"

echo "Apache Airflow installation completed." | tee -a "$MAIN_LOG"

# Automatically detect Airflow paths
export AIRFLOW_HOME="$SETUP_DIR/airflow"
mkdir -p "$AIRFLOW_HOME" || handle_error "Failed to create Airflow home directory at $AIRFLOW_HOME"
AIRFLOW_CFG_PATH="$AIRFLOW_HOME/airflow.cfg"

# Initialize Airflow DB
echo "Initializing Airflow database..." | tee -a "$MAIN_LOG"
airflow db init >> "$PIP_LOG" 2>&1 || handle_error "Failed to initialize Airflow database"
echo "Airflow database initialized successfully." | tee -a "$MAIN_LOG"

# Use SCRIPT_DIR instead of REPO_PATH for repo detection
REPO_PATH="$SCRIPT_DIR"
echo "Repository path: $REPO_PATH" | tee -a "$MAIN_LOG"
if [ -z "$REPO_PATH" ]; then
    handle_error "Failed to detect repository path"
fi

# Default the DAGs folder to the repo's 'dags' directory if not specified
DAGS_FOLDER_PATH="${REPO_PATH}/dags"
if [ ! -d "$DAGS_FOLDER_PATH" ]; then
    handle_error "DAGs folder not found at $DAGS_FOLDER_PATH"
fi

# Install dependencies by generating requirements.txt from requirements.in
if [ -f "$REPO_PATH/requirements.in" ]; then
    echo "Generating requirements.txt from requirements.in..." | tee -a "$MAIN_LOG"
    pip install pip-tools >> "$PIP_LOG" 2>&1 || handle_error "Failed to install pip-tools"
    pip-compile "$REPO_PATH/requirements.in" -o "$REPO_PATH/requirements.txt" >> "$PIP_LOG" 2>&1 || handle_error "Failed to generate requirements.txt"
    pip install -r "$REPO_PATH/requirements.txt" >> "$PIP_LOG" 2>&1 || handle_error "Failed to install dependencies from generated requirements.txt"
    echo "Dependencies installation completed." | tee -a "$MAIN_LOG"
else
    handle_error "requirements.in file is missing. Cannot proceed with dependency installation."
fi

echo "Updating Airflow configuration..." | tee -a "$MAIN_LOG"

# Update the dags_folder in the airflow.cfg file
if ! sed -i "s|^dags_folder =.*|dags_folder = $DAGS_FOLDER_PATH|" "$AIRFLOW_CFG_PATH"; then
    handle_error "Failed to update dags_folder in Airflow configuration"
fi

echo "Successfully updated dags_folder to $DAGS_FOLDER_PATH in $AIRFLOW_CFG_PATH" | tee -a "$MAIN_LOG"

# Set the PROJECT_HOME environment variable for the current session
echo "Setting PROJECT_HOME to $REPO_PATH for the current session" | tee -a "$MAIN_LOG"
export PROJECT_HOME=$REPO_PATH

# Permanently add the PROJECT_HOME environment variable to .bashrc 
BASHRC_PATH="$HOME/.bashrc"
if ! grep -q "export PROJECT_HOME=$REPO_PATH" "$BASHRC_PATH"; then
    echo "Adding PROJECT_HOME to $BASHRC_PATH for future sessions" | tee -a "$MAIN_LOG"
    echo "export PROJECT_HOME=$REPO_PATH" >> "$BASHRC_PATH" || handle_error "Failed to update $BASHRC_PATH with PROJECT_HOME"
    echo "PROJECT_HOME environment variable added to $BASHRC_PATH" | tee -a "$MAIN_LOG"
else
    echo "PROJECT_HOME is already set in $BASHRC_PATH" | tee -a "$MAIN_LOG"
fi

echo "Setup completed successfully." | tee -a "$MAIN_LOG"
