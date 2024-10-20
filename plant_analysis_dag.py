from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.sensors.filesystem import FileSensor
from datetime import datetime, timedelta
import cv2
import os
import gradio as gr
from gradio_viz_app import GUI_Viz
from Plant_Analysis import Plant_Analysis
import pickle

# Define default arguments
default_args = {
   'owner': 'airflow',
    'depends_on_past': True,
    'start_date': datetime(2023, 7, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=1), 
}

# Define the DAG
dag = DAG(
    'plant_analysis_workflow',
    default_args=default_args,
    description='A plant analysis workflow',
    schedule_interval=None,  # Set to None to run the DAG only when triggered
)

# Define the input and output directories
input_plants_folder = '../Data/Raw_Images'
interm_folder = 'interm_objects'
save_analysis_result_folder = 'Viz_Result'

# Ensure the output directory exists
os.makedirs(save_analysis_result_folder, exist_ok=True)
os.makedirs(interm_folder, exist_ok=True)


def launch_viz_gui():

    gui_viz = GUI_Viz(result_folder = save_analysis_result_folder)
    demo = gui_viz.demo
    demo.launch(share = False)

def read_raw_images():

    plant_analysis = Plant_Analysis()
    plant_analysis.update_input_path(input_plants_folder)
    plant_analysis.make_batches()
    plant_analysis.load_raw_images()
    plant_analysis.get_ndvi_image_indices()
    
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis


def make_color_images():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.make_color_images()
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

def stitch_images():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.stitch_color_images()
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

def CCA():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.calculate_connected_components()
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

def run_segmentation():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.load_segmentation_model()
    plant_analysis.run_segmentation()
    del plant_analysis.segmentation_model
    plant_analysis.segmentation_model = None
    
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

def calculate_features_and_statistics():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.load_segmentation_model()
    plant_analysis.calculate_plant_phenotypes()
    plant_analysis.calculate_tips_and_branches()
    plant_analysis.calculate_sift_features()
    plant_analysis.calculate_LBP_features()
    plant_analysis.calculate_HOG_features()
    plant_analysis.calculate_ndvi()
    plant_analysis.save_interm_result()
    del plant_analysis.plants
    del plant_analysis.segmentation_model
    plant_analysis.segmentation_model = None

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

def save_analysis_results():

    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'rb')
    plant_analysis = pickle.load(f)
    f.close()

    plant_analysis.save_results(folder_path = save_analysis_result_folder)
    plant_analysis.clear()
    
    f = open(os.path.join(interm_folder, 'plant_analysis.pkl'), 'wb')
    pickle.dump(plant_analysis, f, protocol=pickle.HIGHEST_PROTOCOL)
    f.close()
    del plant_analysis

# # Define the tasks
# check_for_new_plants = FileSensor(
#     task_id='check_for_new_plants',
#     filepath=input_plants_folder,
#     fs_conn_id='fs_default',
#     poke_interval=10,
#     timeout=600,
#     mode='poke',
#     dag=dag,
# )

read_raw_images = PythonOperator(
    task_id='read_raw_images',
    python_callable=read_raw_images,
    dag=dag,
)

make_color_images = PythonOperator(
    task_id='make_color_images',
    python_callable=make_color_images,
    dag=dag,
)

stitch_images = PythonOperator(
    task_id='stitch_images',
    python_callable=stitch_images,
    dag=dag,
)

do_cca = PythonOperator(
    task_id='do_cca',
    python_callable=CCA,
    dag=dag,
)

run_segmentation = PythonOperator(
    task_id='run_segmentation',
    python_callable=run_segmentation,
    dag=dag,
)

calculate_features_and_statistics = PythonOperator(
    task_id='calculate_features_and_statistics',
    python_callable=calculate_features_and_statistics,
    dag=dag,
)

save_analysis_results = PythonOperator(
    task_id='save_analysis_results',
    python_callable=save_analysis_results,
    dag=dag,
)

run_GUI = PythonOperator(
    task_id='run_visualization_GUI',
    python_callable=launch_viz_gui,
    dag=dag,
)

# Set the task dependencies
# check_for_new_plants >> 
read_raw_images >> make_color_images >> stitch_images >> do_cca >> run_segmentation >> calculate_features_and_statistics >> save_analysis_results >> run_GUI

