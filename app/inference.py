from transformers import AutoTokenizer, TextStreamer
from auto_gptq import AutoGPTQForCausalLM
import torch
import os

MODEL_DIR = "/workspace/models/mixtral"

# 🔄 Chargement du tokenizer
print("🔄 Chargement du tokenizer Mixtral GPTQ...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True, trust_remote_code=True)

# 🔄 Chargement du modèle GPTQ quantifié
print("🔄 Chargement du modèle Mixtral GPTQ...")
model = AutoGPTQForCausalLM.from_quantized(
    MODEL_DIR,
    device_map="auto",
    torch_dtype=torch.float16,
    use_safetensors=True,
    trust_remote_code=True
)

streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=256)
    return tokenizer.decode(output[0], skip_special_tokens=True)
