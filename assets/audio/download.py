import os
import requests
from tqdm import tqdm
from bs4 import BeautifulSoup

def download_all_chapters():
    shloka_counts = [
        47, 72, 43, 42, 29, 47, 30, 28, 34, 42,
        55, 20, 35, 27, 20, 24, 28, 78
    ]
    main_output_folder = "gita_shlokas"
    if not os.path.exists(main_output_folder):
        os.makedirs(main_output_folder)

    missing_files = []

    for chapter in range(3, 19):
        chapter_folder = os.path.join(main_output_folder, f"ch{chapter:02}")
        if not os.path.exists(chapter_folder):
            os.makedirs(chapter_folder)
        num_shlokas = shloka_counts[chapter - 1]
        print(f"\n--- Processing Chapter {chapter} ({num_shlokas} shlokas) ---")

        for shloka in tqdm(range(1, num_shlokas + 1), desc=f"Chapter {chapter:02}"):
            page_url = f"https://vivekavani.com/b{chapter}v{shloka}/"
            try:
                page = requests.get(page_url, timeout=10)
                page.raise_for_status()
            except Exception as e:
                tqdm.write(f"  -> Could not open page: {page_url} ({e})")
                missing_files.append(f"Chapter {chapter} Shloka {shloka}: Page not found")
                continue

            soup = BeautifulSoup(page.text, "html.parser")
            audio_tag = soup.find("audio", src=True)
            if not audio_tag:
                tqdm.write(f"  -> No mp3 found on page: {page_url}")
                missing_files.append(f"Chapter {chapter} Shloka {shloka}: No mp3 found")
                continue

            mp3_url = audio_tag["src"]
            filename = os.path.basename(mp3_url)
            output_path = os.path.join(chapter_folder, filename)

            try:
                response = requests.get(mp3_url, stream=True, timeout=20)
                response.raise_for_status()
                with open(output_path, "wb") as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
            except Exception as e:
                tqdm.write(f"  -> Failed to download: {mp3_url} ({e})")
                missing_files.append(f"Chapter {chapter} Shloka {shloka}: Download failed")
                continue

    # Write missing files info
    summary_file = os.path.join(main_output_folder, "missing_files.txt")
    with open(summary_file, "w") as f:
        for line in missing_files:
            f.write(line + "\n")

    print("\nDownload complete for all chapters!")
    print(f"Missing or not found files are listed in '{summary_file}'.")

if __name__ == "__main__":
    download_all_chapters()