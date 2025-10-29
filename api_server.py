from fastapi import FastAPI
import pickle
import uvicorn

app = FastAPI()


@app.get("/filaments")
def get_filaments():
    with open("/home/ruth/prusa_qr/ClothoPus/filamentstore.pkl", "rb") as f:
        return pickle.load(f)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
    
