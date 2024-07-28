import subprocess
import sys
import os
import platform

libraries = [
    "fastapi",
    "SQLAlchemy",
    "bcrypt",
    "PyJWT",
    "opencv-python",
    "keras-facenet",
    "scipy",
    "tensorflow"
]

def create_virtualenv(env_name="env"):
    subprocess.check_call([sys.executable, "-m", "venv", env_name])
    print(f"Virtual environment '{env_name}' created.")

def install_library(env_name, library, os_type):
    if os_type == "Windows":
        pip_executable = os.path.join(env_name, "Scripts", "pip.exe")
    else:
        pip_executable = os.path.join(env_name, "bin", "pip")
    
    subprocess.check_call([pip_executable, "install", library])

def main():
    env_name = "env"
    create_virtualenv(env_name)
    
    os_type = platform.system()
    
    for library in libraries:
        install_library(env_name, library, os_type)
    
    print("All libraries have been installed in the virtual environment.")

if __name__ == "__main__":
    main()