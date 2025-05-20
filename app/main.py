from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class PromptInput(BaseModel):
    prompt: str

@app.post("/generate")
def generate_text(input: PromptInput):
    return {"response": f"(Fake response) You said: {input.prompt}"}