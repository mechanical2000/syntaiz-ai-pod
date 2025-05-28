import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

# 📁 Dossier local où le modèle est téléchargé
MODEL_DIR = "/workspace/models/mixtral"

# 🔄 Chargement du tokenizer
print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

# 🚀 Chargement du modèle quantifié avec bitsandbytes
print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    torch_dtype=torch.float16,
    load_in_4bit=True,
    trust_remote_code=True
)

# 🧠 Mise en mode d'inférence
model.eval()

# 🧾 Fonction de génération de texte
def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=512,
            do_sample=True,
            temperature=0.7,
            top_k=50,
            top_p=0.9
        )
    return tokenizer.decode(outputs[0], skip_special_tokens=True)
