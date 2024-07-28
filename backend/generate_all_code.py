# GPT'den yardım alınacağı zaman tüm kodu tek tek toplamak ile uğraşmamak için yapılmış bir amme hizmeti
# Çalıştırıldığı zaman seçilen tüm dosyaları düzenli bir şekilde all_code.txt dosyasında toplar

import os

def gather_code(file_paths, output_file):
    with open(output_file, 'w') as outfile:
        for file_path in file_paths:
            if os.path.isfile(file_path):
                with open(file_path, 'r') as infile:
                    content = infile.read()
                    outfile.write(f"--- Start of {file_path} ---\n")
                    outfile.write(content)
                    outfile.write("\n--- End of {file_path} ---\n\n")
            else:
                print(f"Warning: {file_path} is not a valid file path.")

if __name__ == "__main__":
    # Example usage
    files = [
        'models/user.py',
        'routes/user.py',
        'db.py',
        'main.py',
        # Add more file paths as needed
    ]
    output = 'all_code.txt'
    gather_code(files, output)
    print(f"Code from files has been copied to {output}")
