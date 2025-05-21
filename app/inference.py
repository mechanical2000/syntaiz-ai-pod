from transformers import AutoTokenizer, AutoModelForCausalLM, TextStreamer
import torch
import os

MODEL_PATH = "/workspace/models/mixtral"

# Charger le tokenizer
print("🔄 Chargement du tokenizer Mixtral...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=True)

# Charger le modèle en 4-bit avec bnb
print("🔄 Chargement du modèle Mixtral (4-bit)...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    device_map="auto",
    torch_dtype=torch.float16,
    load_in_4bit=True
)

# Préparer un streamer pour l'affichage si besoin
streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=256)
    return tokenizer.decode(output[0], skip_special_tokens=True)