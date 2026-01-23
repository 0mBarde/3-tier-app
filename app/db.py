from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# Replace with your DB Server Private IP
DB_PRIVATE_IP = "10.0.3.179" 
app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://admin_user:SecurePassword123@{DB_PRIVATE_IP}/university_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Student(db.Model):
    __tablename__ = 'students'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    department = db.Column(db.String(100))
    gpa = db.Column(db.Float)

def get_all_students():
    return Student.query.all()

def add_student_to_db(name, email, department, gpa):
    new_student = Student(name=name, email=email, department=department, gpa=gpa)
    db.session.add(new_student)
    db.session.commit()
