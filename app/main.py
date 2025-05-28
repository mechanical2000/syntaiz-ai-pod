import os
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
import torch
from huggingface_hub import snapshot_download

# 📁 Répertoire du modèle local
MODEL_DIR = "/workspace/models/mixtral"
MODEL_REPO = "mistralai/Mixtral-8x7B-Instruct-v0.1"
HF_TOKEN = os.environ.get("HUGGINGFACE_HUB_TOKEN")

# 📥 Téléchargement conditionnel du modèle
if not os.path.isdir(MODEL_DIR):
    print(f"📦 Téléchargement du modèle depuis {MODEL_REPO} dans {MODEL_DIR}...")
    snapshot_download(
        repo_id=MODEL_REPO,
        local_dir=MODEL_DIR,
        local_dir_use_symlinks=False,
        token=HF_TOKEN
    )

# 🔄 Chargement du tokenizer
print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True, token=HF_TOKEN)

# ⚙️ Quantization config pour bitsandbytes 4bit
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.float16,
)

# 🚀 Chargement du modèle
print("🚀 Chargement du modèle quantifié en 4bit avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    quantization_config=bnb_config,
    trust_remote_code=True,
    token=HF_TOKEN
)

# 🔁 Fonction de génération
def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=256,
            do_sample=True,
            top_k=50,
            top_p=0.95,
            temperature=0.7,
            repetition_penalty=1.1
        )
    return tokenizer.decode(outputs[0], skip_special_tokens=True)
