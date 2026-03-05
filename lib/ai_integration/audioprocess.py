import os
import warnings
import librosa
import json
from datetime import datetime
import matplotlib.pyplot as plt
import numpy as np

# Suppress future warnings for deprecated features
warnings.filterwarnings("ignore", category=FutureWarning)

# Step 1: Load and Split Audio
def load_audio(file_path, frame_duration_sec=1, sr=44100):
    """Load an audio file and split it into frames."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Audio file not found: {file_path}")

    try:
        y, sr = librosa.load(file_path, sr=sr)
        frame_size = int(frame_duration_sec * sr)
        frames = [y[i:i + frame_size] for i in range(0, len(y), frame_size)]
        return frames, sr, y
    except Exception as e:
        raise RuntimeError(f"Error loading audio file: {e}")

# Step 2: Extract Features
def extract_features(frames, sr):
    """Extract audio features such as tempo, MFCC, spectral centroid, and bandwidth."""
    emission_data = []
    for idx, frame in enumerate(frames):
        if len(frame) == 0:
            print(f"Skipping empty frame {idx}")
            continue
        try:
            features = {
                "tempo": float(librosa.beat.tempo(frame, sr=sr)[0]),
                "mfcc": librosa.feature.mfcc(y=frame, sr=sr, n_mfcc=13).mean(axis=1).tolist(),
                "spectral_centroid": float(librosa.feature.spectral_centroid(y=frame, sr=sr).mean()),
                "spectral_bandwidth": float(librosa.feature.spectral_bandwidth(y=frame, sr=sr).mean()),
                "rms": float(librosa.feature.rms(y=frame).mean())  # RMS energy as a feature
            }
            print(f"Frame {idx}: Features extracted successfully.")
            emission_data.append(features)
        except Exception as e:
            print(f"Error extracting features from frame {idx}: {e}")
    return emission_data

# Step 3: Map Features to Mood and Command
def map_features_to_mood(emission_data):
    """Map audio features to mood and corresponding commands based on multiple features."""
    def determine_mood(tempo, spectral_centroid, spectral_bandwidth, rms):
        """
        Determine mood based on multiple audio features:
        - Tempo
        - Spectral Centroid
        - Spectral Bandwidth
        - RMS (Root Mean Square) Energy
        """
        if tempo > 120 and spectral_centroid > 3000 and spectral_bandwidth > 2000 and rms > 0.05:
            return "excited", 1
        elif spectral_centroid < 2000 and spectral_bandwidth < 1500 and rms < 0.03:
            return "calm", 2
        elif 80 <= tempo <= 120 and 2000 <= spectral_centroid <= 3000:
            return "happy", 3
        elif rms < 0.01:
            return "relaxed", 4
        else:
            return "neutral", 0

    result = []
    for features in emission_data:
        try:
            mood, command = determine_mood(
                tempo=features["tempo"],
                spectral_centroid=features["spectral_centroid"],
                spectral_bandwidth=features["spectral_bandwidth"],
                rms=features["rms"]
            )
            result.append({
                "tempo": features["tempo"],
                "mood": mood,
                "command": command,
                "features": features
            })
        except KeyError as e:
            print(f"Missing feature in emission data: {e}")
    return result

# Step 4: Save JSON File Safely
def save_as_json_atomic(emission_data, output_file="emission_data.json"):
    """Save processed emission data to a JSON file safely by writing to a temporary file first."""
    temp_file = output_file + ".tmp"
    data = {
        "timestamp": datetime.utcnow().isoformat(),
        "frames": emission_data
    }
    try:
        # Write to a temporary file first
        with open(temp_file, "w") as f:
            json.dump(data, f, indent=4)
        # Replace the old file with the new file
        os.replace(temp_file, output_file)
        print(f"JSON file replaced with new data: '{output_file}'")
    except Exception as e:
        print(f"Error saving JSON file: {e}")
        # Clean up the temporary file if there's an error
        if os.path.exists(temp_file):
            os.remove(temp_file)

# Step 5: Plot Audio Waveform
def plot_waveform(y, sr):
    """Plot the audio waveform for visualization."""
    plt.figure(figsize=(12, 4))
    librosa.display.waveshow(y, sr=sr)
    plt.title("Audio Waveform")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.show()

# Step 6: Read and Display JSON Data
def read_json_file(file_path):
    """Read and display data from a JSON file."""
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
            print("\nProcessed Emission Data:")
            print(json.dumps(data, indent=4))  # Pretty print JSON data
    except Exception as e:
        print(f"Error reading JSON file: {e}")

# Summarize Moods and Commands
def summarize_moods_and_commands(processed_data):
    """Summarize and print the number of moods and commands."""
    mood_counts = {}
    commands = []

    for entry in processed_data:
        mood = entry["mood"]
        command = entry["command"]

        # Count moods
        mood_counts[mood] = mood_counts.get(mood, 0) + 1
        commands.append(command)

    print("\nMood Summary:")
    for mood, count in mood_counts.items():
        print(f"Mood: {mood}, Count: {count}")

    print("\nCommands Issued:")
    print(commands)

# Full Pipeline
def main():
    """Main function to process audio and save emission data."""
    audio_file = r"lib\ai_integration\audios\mixkit-heavy-rain-2403.wav"  # Provide the full path if needed
    output_file = "emission_data.json"

    try:
        print(f"Processing file: {audio_file}")
        frames, sr, y = load_audio(audio_file)
        print(f"Audio loaded successfully. Sampling rate: {sr}, Total frames: {len(frames)}")

        # Plot waveform for visualization
        plot_waveform(y, sr)

        emission_data = extract_features(frames, sr)
        print(f"Features extracted from {len(emission_data)} frames.")

        processed_data = map_features_to_mood(emission_data)
        print(f"Mapped features to mood and commands.")

        # Save as JSON using atomic method
        save_as_json_atomic(processed_data, output_file=output_file)

        # Summarize moods and commands
        summarize_moods_and_commands(processed_data)

        # Read and display JSON data
        read_json_file(output_file)

    except FileNotFoundError as fnf_error:
        print(f"File error: {fnf_error}")
    except RuntimeError as runtime_error:
        print(f"Runtime error: {runtime_error}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    main()
