import os
import subprocess
import sys
from transformers import AutoTokenizer

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, '../../../'))
MODEL_ID = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets/mobile_assets")

def install_dependencies():
    print("Checking/Installing dependencies for Apple Silicon...")
    # This is a basic check; users should ideally run pip install -r requirements_export.txt
    subprocess.check_call([sys.executable, "-m", "pip", "install", "optimum[exporters-tflite]", "transformers", "sentence-transformers", "tensorflow-macos"])

def export_model():
    print(f"Exporting '{MODEL_ID}' to TFLite (Int8 Dynamic Quantization)...")
    
    # Ensure output directory exists (optimum creates it, but good to be safe)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Command construction
    # We use optimum-cli to handle the complex export process
    cmd = [
        "optimum-cli", "export", "tflite",
        "--model", MODEL_ID,
        "--task", "feature-extraction",
        "--quantize", "int8",  # Applies dynamic range quantization
        OUTPUT_DIR
    ]

    print(f"Running command: {' '.join(cmd)}")
    try:
        subprocess.check_call(cmd)
        print("Model export successful.")
    except subprocess.CalledProcessError as e:
        print(f"Error during export: {e}")
        sys.exit(1)

def download_vocab():
    print("Downloading vocabulary files...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    
    # Save standard files
    tokenizer.save_pretrained(OUTPUT_DIR)
    
    # Force creation of vocab.txt for our Dart tokenizer
    # XLM-R models don't have a vocab.txt by default, so we generate it.
    print("Generating 'vocab.txt' from tokenizer vocabulary...")
    vocab = tokenizer.get_vocab()
    # Sort by index to ensure line number == token ID
    sorted_vocab = sorted(vocab.items(), key=lambda item: item[1])
    
    vocab_path = os.path.join(OUTPUT_DIR, "vocab.txt")
    with open(vocab_path, "w", encoding="utf-8") as f:
        for token, index in sorted_vocab:
            # Handle special characters if needed, but writing raw token is usually fine
            f.write(token + "\n")
            
    print(f"Successfully created '{vocab_path}' with {len(vocab)} tokens.")
    
    # Check what was saved
    files = os.listdir(OUTPUT_DIR)
    print(f"Saved tokenizer files to '{OUTPUT_DIR}': {files}")

def main():
    # Optional: Uncomment to auto-install (better to let user do it via requirements file)
    # install_dependencies()
    
    export_model()
    download_vocab()
    print(f"\nDone! Assets are in '{os.path.abspath(OUTPUT_DIR)}'")

if __name__ == "__main__":
    main()
