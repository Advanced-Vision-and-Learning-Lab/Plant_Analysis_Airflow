# Plant_Analysis_Airflow
This repository contains Airflow DAG for plant analysis pipeline

## Running
* Make sure apache-airflow is installed along with the dependencies in [Plant Analysis repository](https://github.com/Advanced-Vision-and-Learning-Lab/Plant_Analysis)
* Make a directory for your airflow project
* Download all the files in this repository to a folder named 'dags' in your airflow project folder. Edit the model path in pipeline config yaml file and input, output paths in plant_analysis_dag.py file
* Now, in the airflow project folder, run 'airflow standalone'
* Go to the link shown in the stdout
* You may need to sign in with a username and a password. They will be printed in the stdout
* After signing in, in the DAGs, you may find a DAG called 'plant_analysis_workflow'. You can click run to run the pipeline
* After all the tasks are successfully run, the last GUI task will show 'running'
* Check the GUI task logs to get the link to GUI
