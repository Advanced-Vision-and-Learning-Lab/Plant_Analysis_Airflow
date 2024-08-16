# Plant_Analysis_Airflow
This repository contains Airflow DAG for plant analysis pipeline

## Usage
* Make sure apache-airflow is installed along with the dependencies in [Plant Analysis repository](https://github.com/Advanced-Vision-and-Learning-Lab/Plant_Analysis)
* Make a directory for your airflow project
* Download all the files in this repository to a folder named 'dags' in your airflow project folder. Edit the model path in pipeline config yaml file and input, output paths in plant_analysis_dag.py file
* Now, in the airflow project folder, run 'airflow standalone'
* Go to the link shown in the stdout
* You may need to sign in with a username and a password. They will be printed in the stdout
* After signing in, in the DAGs, you may find a DAG called 'plant_analysis_workflow'. You can click run to run the pipeline
* After all the tasks are successfully run, the last GUI task will show 'running'
* Check the GUI task logs to get the link to GUI

## TO-DO
* FileSensor task was used to trigger the DAG for every new plant entry into the dataset. However, it did not work as intended after testing. After looking into the documentation, it was found that FileSensor will be triggered when the folder associated is not empty. A new mechanism or a different design is needed to address this.
* The next step in the Airflow conversion is to containerize each task (pipeline module) in the DAG. As the IT does not support docker containers in the Lab GPU systems, it is suggested to use podman (a docker alternative)

Rough steps need to be followed to containerize the tasks (need to be tested):
* Make a base podman image that has the pipeline prerequisites installed (PlantCV, ultralytics, scikit-image, PIL, OpenCV, etc..)
* Prepare a shell command that runs a podman container from the pipeline image. Mount the input, interm, and output folders to each containers
* Prepare a separate python file with functions to be run during each task and call the respective function inside the podman container when executing a task
* For the GUI task, install gradio aditionally and forward appropriate ports in order to access GUI outside the container
