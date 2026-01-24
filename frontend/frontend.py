import streamlit as st
import requests
import pandas as pd

# Config
API_URL = "http://10.0.2.150:5000/students"
st.set_page_config(page_title="EduStream Pro", layout="wide")

# Custom CSS for modern look
st.markdown("""
    <style>
    .main { background-color: #f5f7f9; }
    .stButton>button { width: 100%; border-radius: 5px; height: 3em; background-color: #007bff; color: white; }
    .metric-card { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 2px 2px 10px rgba(0,0,0,0.1); }
    </style>
    """, unsafe_allow_html=True)

st.title("🎓 EduStream Pro | Student Management")

# Sidebar for Navigation
menu = st.sidebar.selectbox("Navigation", ["Dashboard", "Enroll Student", "Manage Database"])

if menu == "Dashboard":
    st.subheader("System Overview")
    response = requests.get(API_URL)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data)
        
        # Modern Metrics
        col1, col2, col3 = st.columns(3)
        col1.metric("Total Students", len(df))
        col2.metric("Average GPA", round(df['gpa'].astype(float).mean(), 2) if not df.empty else 0)
        col3.metric("Active Enrollments", "94%")

        st.divider()
        st.subheader("Student Directory")
        st.dataframe(df, use_container_width=True, hide_index=True)
    else:
        st.error("Could not connect to Application Layer.")

elif menu == "Enroll Student":
    st.subheader("New Student Registration")
    with st.container():
        col1, col2 = st.columns(2)
        with col1:
            name = st.text_input("Full Name")
            email = st.text_input("Institutional Email")
        with col2:
            course = st.selectbox("Department", ["Computer Science", "Data Science", "AI", "Business"])
            gpa = st.slider("Current GPA", 0.0, 4.0, 3.5)

        if st.button("Complete Enrollment"):
            payload = {"name": name, "email": email, "course": course, "gpa": gpa}
            res = requests.post(API_URL, json=payload)
            if res.status_code == 201:
                st.success(f"Successfully enrolled {name}!")
                st.balloons()
                
elif menu == "Manage Database":
    st.subheader("🛠️ Administrative Control Panel")
    
    # Fetch latest data for selection
    response = requests.get(API_URL)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data)
        
        if df.empty:
            st.info("The database is currently empty.")
        else:
            # 1. Search and Select Student
            student_names = df['name'].tolist()
            selected_student_name = st.selectbox("Select a student to modify or remove", student_names)
            
            # Get the specific student data
            student_row = df[df['name'] == selected_student_name].iloc[0]
            student_id = student_row.get('id') # Assuming your API returns an 'id' field

            st.write(f"**Managing Record for:** {selected_student_name} (ID: {student_id})")
            
            # 2. Update and Delete Tabs
            tab1, tab2 = st.tabs(["Update Info", "Danger Zone"])
            
            with tab1:
                with st.form("update_form"):
                    new_email = st.text_input("Update Email", value=student_row['email'])
                    new_course = st.selectbox("Update Department", 
                                            ["Computer Science", "Data Science", "AI", "Business"], 
                                            index=["Computer Science", "Data Science", "AI", "Business"].index(student_row['course']))
                    new_gpa = st.slider("Update GPA", 0.0, 4.0, float(student_row['gpa']))
                    
                    if st.form_submit_button("Save Changes"):
                        update_payload = {"name": selected_student_name, "email": new_email, "course": new_course, "gpa": new_gpa}
                        # Typically PUT /students/{id}
                        update_res = requests.put(f"{API_URL}/{student_id}", json=update_payload)
                        if update_res.status_code in [200, 204]:
                            st.success("Student record updated!")
                            st.rerun()
                        else:
                            st.error("Failed to update record.")

            with tab2:
                st.warning("Action is irreversible!")
                if st.button(f"🗑️ Permanent Delete {selected_student_name}"):
                    # Typically DELETE /students/{id}
                    delete_res = requests.delete(f"{API_URL}/{student_id}")
                    if delete_res.status_code in [200, 204]:
                        st.success("Record deleted successfully.")
                        st.rerun()
                    else:
                        st.error("Could not delete record.")
    else:
        st.error("Unable to fetch data from the API.")
