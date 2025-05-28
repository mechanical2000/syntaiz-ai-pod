import requests

API_URL = "http://<TON_IP_RUNPOD>:8000/generate"  # 🔁 Remplace par l'URL réelle de ton endpoint

def test_prompt(prompt):
    try:
        response = requests.post(API_URL, json={"prompt": prompt})
        response.raise_for_status()
        result = response.json()
        print("\n🧠 Réponse Mixtral :\n")
        print(result.get("response", "[Aucune réponse]"))
    except Exception as e:
        print("❌ Erreur lors de l'appel au modèle :", str(e))

if __name__ == "__main__":
    print("💬 Testeur de prompts Mixtral (Ctrl+C pour quitter)\n")
    while True:
        try:
            prompt = input("📝 Prompt > ").strip()
            if prompt:
                test_prompt(prompt)
        except KeyboardInterrupt:
            print("\n👋 Fin du test interactif.")
            break
