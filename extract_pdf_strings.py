import re
import sys

def extract_strings(filename, min_len=4):
    try:
        with open(filename, 'rb') as f:
            content = f.read()
            # Regex to find sequences of printable ASCII characters
            # allowing for some common punctuation
            pattern = re.compile(b'[ -~]{' + str(min_len).encode() + b',}')
            strings = pattern.findall(content)
            
            print(f"--- Extracted Strings from {filename} ---")
            for s in strings:
                try:
                    decoded = s.decode('utf-8')
                    # basic filtering to remove random noise
                    if len(decoded.strip()) > 0:
                        print(decoded)
                except:
                    pass
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        extract_strings(sys.argv[1])
    else:
        print("Usage: python extract_pdf_strings.py <filename>")
