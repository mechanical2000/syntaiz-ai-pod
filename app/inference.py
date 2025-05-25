from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import torch
import os

MODEL_DIR = "/workspace/models/mixtral"

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=False)

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    load_in_8bit=True,
    device_map="auto",
    trust_remote_code=True,
    torch_dtype=torch.float16,
    llm_int8_enable_fp32_cpu_offload=True
)

pipe = pipeline("text-generation", model=model, tokenizer=tokenizer)

def generate_text(prompt: str, max_new_tokens: int = 256) -> str:
    print(f"⚙️ Génération pour : {prompt}")
    outputs = pipe(prompt, max_new_tokens=max_new_tokens, do_sample=True, temperature=0.7)
    return outputs[0]["generated_text"]
