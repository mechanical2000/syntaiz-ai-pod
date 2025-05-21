from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
import inference

app = FastAPI()

API_KEY = "syntaiz-super-secret-key"

class PromptInput(BaseModel):
    prompt: str

@app.middleware("http")
async def verify_api_key(request: Request, call_next):
    if request.headers.get("x-api-key") != API_KEY:
        raise HTTPException(status_code=403, detail="Forbidden")
    return await call_next(request)

@app.post("/generate")
def generate_text(input: PromptInput):
    return {"response": inference.generate_response(input.prompt)}