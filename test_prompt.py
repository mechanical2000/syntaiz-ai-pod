import requests
import time
import argparse

# Configuration
API_URL = "http://<TON_IP_RUNPOD>:8000/generate"  # ← remplace avec ton URL réelle

# Interface CLI
parser = argparse.ArgumentParser(description="Tester un prompt Mixtral distant")
parser.add_argument("--max_new_tokens", type=int, default=128, help="Nombre max de tokens générés (default: 128)")
parser.add_argument("--temperature", type=float, default=0.7, help="Température (default: 0.7)")
parser.add_argument("--do_sample", action="store_true", help="Active l'échantillonnage (default: False)")
args = parser.parse_args()

# Fonction de test
def test_prompt(prompt):
    payload = {
        "prompt": prompt,
        "max_new_tokens": args.max_new_tokens,
        "temperature": args.temperature,
        "do_sample": args.do_sample
    }

    try:
        start = time.time()
        response = requests.post(API_URL, json=payload)
        duration = time.time() - start

        response.raise_for_status()
        result = response.json()

        print(f"\n🧠 Réponse Mixtral ({duration:.2f} sec) :\n")
        print(result.get("response", "[Aucune réponse]"))

    except Exception as e:
        print("❌ Erreur :", str(e))

# Boucle interactive
if __name__ == "__main__":
    print("💬 Testeur de prompts Mixtral (Ctrl+C pour quitter)")
    print(f"🎛️  Params : max_tokens={args.max_new_tokens}, temperature={args.temperature}, do_sample={args.do_sample}\n")

    while True:
        try:
            prompt = input("📝 Prompt > ").strip()
            if prompt:
                test_prompt(prompt)
        except KeyboardInterrupt:
            print("\n👋 Fin du test.")
            break
