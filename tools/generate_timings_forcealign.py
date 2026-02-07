import os
import sqlite3
import json
import torch
import torchaudio
import torchaudio.functional as F
import librosa
import re
import unicodedata
import subprocess
import sys
import time

# --- CONFIG ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
DB_PATH = os.path.join(PROJECT_ROOT, "assets", "database", "geeta_v2.db")
AUDIO_BASE_PATH = os.path.join(PROJECT_ROOT, "assets", "audio")
OUTPUT_PATH = os.path.join(PROJECT_ROOT, "assets", "database", "timings_forced.json")

# Load the MMS_FA Bundle
BUNDLE = torchaudio.pipelines.MMS_FA

class ReferenceAligner:
    def __init__(self):
        print(f"[INFO] Loading Model: {BUNDLE}...")
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = BUNDLE.get_model().to(self.device)
        self.tokenizer = BUNDLE.get_tokenizer()
        self.dictionary = BUNDLE.get_dict()

    def convert_to_wav(self, input_path):
        """Converts M4A to 16kHz Mono WAV using FFmpeg."""
        temp_wav = os.path.join(BASE_DIR, "temp_production.wav")
        # 2s padding is CRITICAL
        cmd = ["ffmpeg", "-y", "-i", input_path, "-af", "apad=pad_len=32000", "-ar", "16000", "-ac", "1", temp_wav]
        try:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True)
            return temp_wav
        except subprocess.CalledProcessError:
            return None

    def normalize_text(self, text):
        t = text.replace('<C>', ' ').replace('*', ' ').replace('||', '').replace('|', '')
        t = unicodedata.normalize('NFD', t).encode('ascii', 'ignore').decode('ascii')
        t = re.sub(r'[^a-z\s]', '', t.lower())
        return t.split()

    def align(self, audio_path, words):
        temp_wav = self.convert_to_wav(audio_path)
        if not temp_wav: return None

        try:
            wav, sr = librosa.load(temp_wav, sr=16000, mono=True)
        except Exception as e:
            print(f"[ERROR] Librosa load failed: {e}")
            return None
        finally:
            if os.path.exists(temp_wav): os.remove(temp_wav)

        waveform = torch.from_numpy(wav).unsqueeze(0).to(self.device)

        # Filter transcript
        full_transcript = "".join(words)
        valid_transcript = "".join([c for c in full_transcript if c in self.dictionary])
        
        if len(valid_transcript) == 0:
            print("[ERROR] Transcript empty after filtering!")
            return None

        tokens = self.tokenizer([valid_transcript])
        targets = torch.tensor(tokens, dtype=torch.int32, device=self.device)

        with torch.inference_mode():
            emissions, _ = self.model(waveform)
            emissions = torch.log_softmax(emissions, dim=-1)

        input_lengths = torch.tensor([emissions.size(1)], device=self.device)
        target_lengths = torch.tensor([targets.size(1)], device=self.device)

        try:
            aligned_tokens, scores = F.forced_align(
                emissions, targets, input_lengths, target_lengths, blank=0
            )
        except RuntimeError as e:
            print(f"[ALIGN ERROR] {e}")
            return None

        aligned_tokens = aligned_tokens[0]
        scores = scores[0]
        
        token_spans = F.merge_tokens(aligned_tokens, scores)
        final_timings = []
        span_idx = 0
        ratio = waveform.size(1) / emissions.size(1) / 16000

        for word in words:
            word_clean = "".join([c for c in word if c in self.dictionary])
            n_tokens = len(word_clean)
            
            if n_tokens == 0: continue

            if span_idx + n_tokens > len(token_spans):
                print(f"    [WARN] Ran out of spans for word '{word}'")
                break

            relevant_spans = token_spans[span_idx : span_idx + n_tokens]
            
            t0 = relevant_spans[0].start * ratio
            t1 = relevant_spans[-1].end * ratio
            
            final_timings.append({
                "word": word,
                "start": round(t0, 2),
                "end": round(t1, 2)
            })
            
            span_idx += n_tokens

        return final_timings

def main():
    print("\n" + "="*60)
    print("   BHAGAVAD GITA: FULL PRODUCTION ALIGNMENT")
    print("="*60 + "\n")
    
    aligner = ReferenceAligner()
    
    # 1. Load Existing Data (Resume Capability)
    all_results = {}
    if os.path.exists(OUTPUT_PATH):
        try:
            with open(OUTPUT_PATH, 'r') as f:
                all_results = json.load(f)
            print(f"[RESUME] Loaded {len(all_results)} existing shlokas from {OUTPUT_PATH}")
        except json.JSONDecodeError:
            print("[WARN] Existing JSON corrupted. Starting fresh.")

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 2. Select ALL Shlokas
    cursor.execute("""
        SELECT chapter_no, shloka_no, sanskrit_romanized 
        FROM master_shlokas 
        ORDER BY chapter_no, shloka_no
    """)
    rows = cursor.fetchall()
    total_count = len(rows)
    print(f"[INFO] Database contains {total_count} shlokas.\n")

    start_time = time.time()
    processed_count = 0
    skipped_count = 0

    for i, (chap, shlok, text) in enumerate(rows):
        key = f"{chap}.{shlok}"
        progress_str = f"[{i+1}/{total_count}]"
        
        # 3. Skip if already done
        if key in all_results:
            skipped_count += 1
            # Print less frequently for skips to reduce clutter
            if skipped_count % 50 == 0:
                print(f"{progress_str} Skipping {key} (Already Exists)...")
            continue

        print(f"{progress_str} Processing {key}...")
        
        audio_path = os.path.join(AUDIO_BASE_PATH, f"Chapter{chap}_audio", f"ch{str(chap).zfill(2)}_sh{str(shlok).zfill(2)}.m4a")
        
        if not os.path.exists(audio_path):
            print(f"  [CRITICAL] Audio Missing: {audio_path}")
            print("  [ACTION] Stopping script.")
            sys.exit(1)

        words = aligner.normalize_text(text)
        
        try:
            # 4. Run Alignment
            res = aligner.align(audio_path, words)
            
            if res:
                all_results[key] = res
                processed_count += 1
                
                # 5. Immediate Save (Safety)
                with open(OUTPUT_PATH, "w") as f:
                    json.dump(all_results, f, indent=2)
                
                # Brief success log
                print(f"  [SUCCESS] {len(res)} words aligned. Saved.")
            else:
                print(f"\n[FAILURE] Could not align {key}")
                print("  [ACTION] Stopping script as requested.")
                sys.exit(1)

        except KeyboardInterrupt:
            print("\n[USER] Script interrupted by user.")
            sys.exit(0)
        except Exception as e:
            print(f"\n[EXCEPTION] Error on {key}: {e}")
            sys.exit(1)

    # 6. Final Summary
    total_time = time.time() - start_time
    print("\n" + "="*60)
    print("   PROCESSING COMPLETE")
    print("="*60)
    print(f"Total Shlokas in DB : {total_count}")
    print(f"Skipped (Pre-existing): {skipped_count}")
    print(f"Newly Processed     : {processed_count}")
    print(f"Time Taken          : {total_time:.1f}s")
    print(f"Output File         : {OUTPUT_PATH}")
    print("="*60)
    
    conn.close()

if __name__ == "__main__":
    main()