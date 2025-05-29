from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
import torch

torch.backends.cuda.matmul.allow_tf32 = True

MODEL_PATH = "/workspace/models/mixtral"

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True,
    bnb_4bit_compute_dtype=torch.float16
)

print("🔄 Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=True)

print("🚀 Chargement du modèle quantifié avec bitsandbytes...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    quantization_config=bnb_config,
    torch_dtype=torch.float16,
    device_map={"": "cuda:0"},
    trust_remote_code=True
)

# 🔥 Warm-up : première génération très légère
print("⚡ Préchauffage du modèle...")
_ = model.generate(
    **tokenizer("Bonjour", return_tensors="pt").to(model.device),
    max_new_tokens=1
)

def generate_response(
    prompt: str,
    max_new_tokens: int = 128,
    do_sample: bool = False,
    temperature: float = 0.7
) -> str:
    inputs = tokenizer(prompt, return_tensors="pt")
    inputs = {k: v.to(model.device) for k, v in inputs.items()}
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=do_sample,
            temperature=temperature
        )
    output_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    if output_text.strip().startswith(prompt.strip()):
        output_text = output_text[len(prompt):]

    return output_text.strip()
