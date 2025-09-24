import os
import shutil
from fastapi import FastAPI, UploadFile
from pathlib import Path
from uuid import uuid4

from argofilechecker_python_wrapper import FileChecker

ROOT_PATH = os.getenv("API_ROOT_PATH", "")

app = FastAPI(root_path=ROOT_PATH)


@app.get("/")
def app_status():
    return {"OK"}


@app.post("/check-files")
def check_file_list(files: list[UploadFile]):
    request_id = uuid4()
    request_file_dir = Path(f"/home/app/input/{request_id}")
    os.makedirs(request_file_dir)
    for upload_file in files:
        try:
            with request_file_dir.joinpath(upload_file.filename).open("wb") as buffer:
                shutil.copyfileobj(upload_file.file, buffer)
        finally:
            upload_file.file.close()
    file_checker = FileChecker(specs_path='/home/app/file_checker_spec')
    results = {"results": file_checker.check_files(request_file_dir.glob("*"), "bodc")}
    return results
