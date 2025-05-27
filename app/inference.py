from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

MODEL_DIR = "/workspace/models/mixtral-4bit"

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

print("🚀 Chargement du modèle GPTQ quantifié 4-bit...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    trust_remote_code=True,
    torch_dtype=torch.float16
)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=512)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)
