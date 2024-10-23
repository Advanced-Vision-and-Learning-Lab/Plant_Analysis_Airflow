# Plant_Analysis_Airflow
This repository contains Airflow DAG for plant analysis pipeline

# Table of Contents
- [Pipeline Description](#pipeline-description)
- [Airflow DAG Configuration Setup](#airflow-dag-configuration-setup)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
- [Airflow Instructions](#airflow-instructions)
- [TO-DO](#to-do)
- [Containerization Considerations](#containerization-considerations)


## Pipeline Description 
---

 The plant analysis pipeline comprises several stages, which are managed as individual tasks within the AirFlow DAG. It uses `FileSensor` step to detect changes in the current file systems. Once new file are detected, it triggers the subsequent steps. 
 
 * **Image Preprocessing**: The ingested images undergo preprocessing steps such as resizing, normalization, and filtering to ensure they are in the correct format for analysis.
 * **Spatial Transformer Network (STN) YOLO-based Image Segmentation**: The core of the plant analysis system is an advanced object detection and segmentation model based on YOLO (You Only Look Once) architecture, enhanced with a Spatial Transformer Network (STN). This model is designed specifically for agricultural object detection, allowing the system to detect and segment plants and other agricultural objects in real-time from the images. The STN enables the model to focus on specific regions of the image, improving the accuracy of object detection and segmentation
 * **NDVI Index Calculation**: Once the images are segmented, the system calculates the Normalized Difference Vegetation Index (NDVI) for each detected object to evaluate plant health based on infrared spectrum analysis.
 * **Image Stitching**: In cases where the images are captured in tiles, the system stitches them together to create a single composite image, providing a more comprehensive view of the plants.
 * **Feature Extraction and Analysis**: After segmentation, the system extracts various phenotypic features such as plant size, leaf area, and branching structure. These features are essential for understanding plant health and growth patterns.
 * **Connected Components Analysis (CCA)**: The system performs connected components analysis to further refine the identification of plant structures and quantify various aspects of plant phenotypes.


<div style="text-align: center;">
    <img src="./images/Existing System.jpg" alt="Plant Analysis Pipeline" style="max-width: 100%; height: auto;">
</div>


## Airflow DAG Configuration Setup
---
The setup script `setup.sh` helps you update the `dags_folder` in the `airflow.cfg` file to point to the repository folder by default or to a custom path if needed. Additionally, it sets up the `PROJECT_HOME` environment variable for easy reference to the repository path. More importantly, it uses `requirements.in` to generate up-to-date `requirements.txt` and then installs the dependencies needed for this project. Please note that approximately **8GB** of disk space is required to install these libraries.

### Prerequisites

- A Unix-like operating system is required to run this setup script.
- The script assumes that Python 3 is installed and that `python3` is recognized as a valid alias.
- **Tested Environment**:
  * Ubuntu 22.04.1
  * Python 3.10.12

### Usage

1. **Run the setup script**:
   You can optionally provide a custom working directory and Airflow version. If not provided, it defaults to using the `$HOME` directory and installs Airflow version `2.10.2`.

   Example with custom directory and default Airflow version:
   ```bash
   ./setup.sh /path/to/custom/directory
   ```

   Example with custom directory and custom Airflow version:
   ```bash
   ./setup.sh /path/to/custom/directory 2.9.1
   ```

   If no arguments are provided, the script will use the $HOME directory for setup and default to Airflow version 2.10.2:

   ```bash
   ./setup.sh
   ```

2. Activate the virtual environment: After running the setup script, activate the virtual environment created during the setup process:

```bash
source /path/to/custom/directory/plant_analysis_setup/plant_analysis_env/bin/activate
```

3. Initialize Airflow: Once the virtual environment is activated, you can start using Airflow. First, initialize the Airflow database:

```bash
airflow db init
```

4. Run Airflow: To run Airflow webserver and scheduler:

```bash
airflow webserver -p 8080
airflow scheduler
```

5. Environment Variable `PROJECT_HOME`: The setup script automatically sets up the `PROJECT_HOME `environment variable, which points to the repository path. It is also added to your `.bashrc` for future sessions.

6. Dependency Management: The setup script generates a requirements.txt from requirements.in using pip-tools. It then installs all the dependencies specified in the generated requirements.txt.

#### Logs

The setup process logs its actions to three log files:

- **Main log**: `$SETUP_DIR/setup_main.log`
- **Virtual environment log**: `$SETUP_DIR/setup_venv.log`
- **Pip installation log**: `$SETUP_DIR/setup_pip.log`
Check these logs for detailed information about the setup process.


## Airflow Instructions
---

Make sure to modify `segmentation_model_weights_path`, `data_dir` and `output_dir` in `pipeline_config.yaml`

- Input Data Folder Structure

The pipeline expects the input data folder to be in this structure:

```plaintext
SomeDataset/
├── Raw_Images/
│   ├── Plant1/
│   ├── Plant2/
│   └── Plant3/
```

- To run the workflow in debugging mode: 

```bash
python3 dags/plant_analysis_dag.py 
```

- To run the Airflow UI, you can run this command:
  
```bash
airflow standalone
``` 
* Go to the link shown in the stdout
* You may need to sign in with a username and a password. They will be printed in the stdout
* After signing in, in the DAGs, you may find a DAG called 'plant_analysis_workflow'. You can click run to run the pipeline
* After all the tasks are successfully run, the last GUI task will show 'running'
* Check the GUI task logs to get the link to GUI

## TO-DO
---
* FileSensor task was used to trigger the DAG for every new plant entry into the dataset. However, it did not work as intended after testing. After looking into the documentation, it was found that FileSensor will be triggered when the folder associated is not empty. A new mechanism or a different design is needed to address this.
* The next step in the Airflow conversion is to containerize each task (pipeline module) in the DAG. As the IT does not support docker containers in the Lab GPU systems, it is suggested to use podman (a docker alternative)

## Containerization Considerations
---
* Make a base podman image that has the pipeline prerequisites installed (PlantCV, ultralytics, scikit-image, PIL, OpenCV, etc..)
* Prepare a shell command that runs a podman container from the pipeline image. Mount the input, interm, and output folders to each containers
* Prepare a separate python file with functions to be run during each task and call the respective function inside the podman container when executing a task
* For the GUI task, install gradio aditionally and forward appropriate ports in order to access GUI outside the container
