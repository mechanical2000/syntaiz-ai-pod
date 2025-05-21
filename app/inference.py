from transformers import AutoTokenizer, AutoModelForCausalLM, TextStreamer
from huggingface_hub import snapshot_download
import torch
import os

MODEL_DIR = "/workspace/models/mixtral"

# 📥 Télécharger le modèle si absent
if not os.path.exists(os.path.join(MODEL_DIR, "config.json")):
    print("📦 Téléchargement du modèle Mixtral via snapshot_download...")
    snapshot_download(
        repo_id="mistralai/Mixtral-8x7B-Instruct-v0.1",
        local_dir=MODEL_DIR,
        local_dir_use_symlinks=False,
        use_auth_token=True
    )
else:
    print("✅ Modèle déjà présent dans", MODEL_DIR)

# 🔄 Chargement du tokenizer
print("🔄 Chargement du tokenizer Mixtral...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

# 🔄 Chargement du modèle en 4-bit
print("🔄 Chargement du modèle Mixtral (4-bit)...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    torch_dtype=torch.float16,
    load_in_4bit=True
)

streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=256)
    return tokenizer.decode(output[0], skip_special_tokens=True)