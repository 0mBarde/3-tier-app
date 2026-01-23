from flask import Flask, request, jsonify
from db import app, db, get_all_students, add_student_to_db 

@app.route('/students', methods=['GET'])
def list_students():
    try:
        students = get_all_students()
        return jsonify([{"id": s.id, "name": s.name, "email": s.email, "department": s.department, "gpa": s.gpa} for s in students])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/students', methods=['POST'])
def create_student():
    try:
        data = request.json
        add_student_to_db(data['name'], data['email'], data.get('department'), data.get('gpa'))
        return jsonify({"message": "Student created successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    # Initialize the database table remotely if it doesn't exist
    with app.app_context():
        db.create_all()
    # Listen on all interfaces so the Web Server can reach this instance
    app.run(host='0.0.0.0', port=5000)
