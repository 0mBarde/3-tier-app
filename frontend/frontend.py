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
