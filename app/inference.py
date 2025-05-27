import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig

MODEL_DIR = "/workspace/models/mixtral"

# Configuration 8bit avec offload CPU
quant_config = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_enable_fp32_cpu_offload=True
)

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)
print("✅ Tokenizer chargé.")

print("🔄 Chargement du modèle Mixtral (8bit + offload CPU)...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    quantization_config=quant_config,
    trust_remote_code=True,
    torch_dtype=torch.float16
)
print("✅ Modèle chargé.")

def generate_response(prompt: str) -> str:
    print(f"📨 Prompt reçu : {prompt}")
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        output = model.generate(
            **inputs,
            max_new_tokens=512,
            do_sample=True,
            temperature=0.7,
            top_p=0.95
        )
    decoded = tokenizer.decode(output[0], skip_special_tokens=True)
    print(f"✅ Réponse générée : {decoded}")
    return decoded
