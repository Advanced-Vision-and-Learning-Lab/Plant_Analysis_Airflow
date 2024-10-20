# Plant_Analysis_Airflow
This repository contains Airflow DAG for plant analysis pipeline

# Table of Contents
- [Pipeline Description](#pipeline-description)
- [Airflow DAG Configuration Setup](#airflow-dag-configuration-setup)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [1. Default DAG Folder (Repo Folder)](#1-default-dag-folder-repo-folder)
    - [2. Custom DAG Folder](#2-custom-dag-folder)
    - [3. Environment Setup](#3-environment-setup)
    - [4. Optional: Restart Airflow Services](#4-optional-restart-airflow-services)
- [Airflow UI](#airflow-ui)
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
The setup script `setup.sh` helps you update the `dags_folder` in the `airflow.cfg` file to point to the repository folder by default or to a custom path if needed. Additionally, it sets up the `PROJECT_HOME` environment variable for easy reference to the repository path. More importantly, it uses `requirments.in` to generate up-to-date `requirements.txt` and this install the dependancies needed for this project. Please note that `~8GB` are needed to install these libraries. 

### Prerequisites

- Ensure that `airflow.cfg` exists and you know its location.
- The script can accept an optional custom DAGs folder path. If not provided, it defaults to the repository root.

### Usage

#### 1. Default DAG Folder (Repo Folder)

By default, the DAGs folder is set to the repository root directory. You can run the script as follows:

```bash
./setup.sh <path_to_airflow_cfg> <path_to_repo>
```
`<path_to_airflow_cfg>`: The path to the airflow.cfg configuration file.
`<path_to_repo>`: The path to the repository where the DAGs are located.

Example:

```bash
./setup.sh /home/user/airflow/airflow.cfg /home/user/projects/Plant_Analysis_Airflow
```

#### 2. Custom DAG Folder

If you want to specify a different DAGs folder path, you can provide it as a second argument:
./setup.sh <path_to_airflow_cfg> <path_to_dags_folder> <path_to_repo>

`<path_to_dags_folder>`: The custom folder where DAGs are stored.
`<path_to_repo>`: The path to the repository.

Example:

```bash
./setup.sh /home/user/airflow/airflow.cfg /home/user/custom_dags /home/user/projects/Plant_Analysis_Airflow
```

#### 3. Environment Setup

The script also sets the PROJECT_HOME environment variable to the repository path for future sessions:

- It exports the PROJECT_HOME variable during the script execution.
- It adds the PROJECT_HOME environment variable to ~/.bashrc for persistence across sessions.
- If the PROJECT_HOME variable is already set in ~/.bashrc, the script will not overwrite it.

#### 4. Optional: Restart Airflow Services:

If you want the script to automatically restart Airflow services after updating the airflow.cfg, you can uncomment the lines at the end of the script that run airflow scheduler and airflow webserver.

## Airflow UI:
---
* To run the Airflow UI, you can run this command:
  
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
