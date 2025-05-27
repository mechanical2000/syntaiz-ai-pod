from transformers import AutoModelForCausalLM, AutoTokenizer, GenerationConfig, BitsAndBytesConfig
import torch

MODEL_DIR = "/workspace/models/mixtral"

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR, use_fast=True)

bnb_config = BitsAndBytesConfig(
    load_in_8bit=True,
    llm_int8_enable_fp32_cpu_offload=True
)

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_DIR,
    quantization_config=bnb_config,
    device_map="auto",
    trust_remote_code=True,
    torch_dtype=torch.float16
)

generation_config = GenerationConfig(
    max_new_tokens=256,
    temperature=0.7,
    top_p=0.95,
    top_k=40,
    repetition_penalty=1.2,
    do_sample=True,
    eos_token_id=tokenizer.eos_token_id,
)

def generate_response(prompt: str) -> str:
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            generation_config=generation_config
        )
    return tokenizer.decode(outputs[0], skip_special_tokens=True)
