from transformers import AutoTokenizer, AutoModelForCausalLM, TextGenerationPipeline
import torch

# Nom du modèle quantifié 4-bit
model_name = "TheBloke/Mixtral-8x7B-v0.1-GPTQ"
revision = "gptq-4bit-128g-actorder_True"

# Chargement du tokenizer
print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=True)

# Chargement du modèle quantifié
print("🚀 Chargement du modèle quantifié avec AutoGPTQ (4-bit)...")
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    trust_remote_code=True,
    revision=revision
)

# Pipeline de génération
pipe = TextGenerationPipeline(model=model, tokenizer=tokenizer, device=0)

def generate_response(prompt: str) -> str:
    outputs = pipe(
        prompt,
        max_new_tokens=256,
        do_sample=True,
        temperature=0.7,
        top_p=0.95,
        repetition_penalty=1.1,
        num_return_sequences=1,
        eos_token_id=tokenizer.eos_token_id
    )
    return outputs[0]['generated_text']
