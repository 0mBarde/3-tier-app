from flask_sqlalchemy import SQLAlchemy
from flask import Flask
from datetime import datetime

db_app = Flask(__name__)
db_app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///university.db'
db = SQLAlchemy(db_app)

class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    course = db.Column(db.String(100))
    gpa = db.Column(db.Float, default=0.0)
    created_at = db.Column(db.String(20), default=datetime.now().strftime("%Y-%m-%d"))

with db_app.app_context():
    db.create_all()

def get_all_students():
    with db_app.app_context():
        return Student.query.all()

def add_student_to_db(name, email, course, gpa):
    with db_app.app_context():
        new_student = Student(name=name, email=email, course=course, gpa=gpa)
        db.session.add(new_student)
        db.session.commit()
