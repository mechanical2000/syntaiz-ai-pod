from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline,  BitsAndBytesConfig
import torch
import os

bnb_config = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_enable_fp32_cpu_offload=True
)

MODEL_DIR = "/workspace/models/mixtral"

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    quantization_config=bnb_config,
    torch_dtype=torch.float16
)

pipe = pipeline("text-generation", model=model, tokenizer=tokenizer)

def generate_response(prompt: str, max_new_tokens: int = 256) -> str:
    print(f"⚙️ Génération pour : {prompt}")
    outputs = pipe(prompt, max_new_tokens=max_new_tokens, do_sample=True, temperature=0.7)
    return outputs[0]["generated_text"]
