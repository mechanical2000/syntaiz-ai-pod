from transformers import AutoTokenizer, AutoModelForCausalLM, TextStreamer
import torch
import os

MODEL_DIR = "/workspace/models/mixtral"

# 🔄 Chargement du tokenizer
print("🔄 Chargement du tokenizer Mixtral...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

# 🔄 Chargement du modèle en 8-bit via bitsandbytes
print("🔄 Chargement du modèle Mixtral (8-bit avec bitsandbytes)...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    load_in_8bit=True,
    torch_dtype=torch.float16,
    llm_int8_enable_fp32_cpu_offload=True
)

streamer = TextStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=256)
    return tokenizer.decode(output[0], skip_special_tokens=True)
