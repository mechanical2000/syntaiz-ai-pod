from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline,  BitsAndBytesConfig
import torch
import os

bnb_config = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_threshold=6.0,
    llm_int8_has_fp16_weight=True,
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4"
)

MODEL_DIR = "/workspace/models/mixtral"

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    device_map="auto",
    torch_dtype=torch.float16,
    quantization_config=bnb_config
)

pipe = pipeline("text-generation", model=model, tokenizer=tokenizer)

def generate_response(prompt: str, max_new_tokens: int = 256) -> str:
    print(f"⚙️ Génération pour : {prompt}")
    outputs = pipe(prompt, max_new_tokens=max_new_tokens, do_sample=True, temperature=0.7)
    return outputs[0]["generated_text"]
