# syntaiz-ai-pod

pod configuration for syntaiz ai

in /workspace

1. rm -rf syntaiz-ai-pod
2. git clone https://github.com/mechanical2000/syntaiz-ai-pod.git
3. cd syntaiz-ai-pod
4. chmod +x setup/setup_system.sh
5. ./setup/setup_system.sh

pod image build

docker buildx build --platform linux/amd64 -t marccauliflow/syntaiz-ai-pod --push .
