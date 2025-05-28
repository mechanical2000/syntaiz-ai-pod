from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
import torch

# 🔄 Identifiant Hugging Face du modèle (repo public)
MODEL_ID = "mistralai/Mixtral-8x7B-Instruct-v0.1"

# ⚙️ Configuration quantification 4-bit
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.float16
)

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, use_fast=True, token=__import__("os").environ.get("HUGGINGFACE_HUB_TOKEN"))

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID,
    quantization_config=bnb_config,
    device_map="auto",
    trust_remote_code=True,
    token=__import__("os").environ.get("HUGGINGFACE_HUB_TOKEN")
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
