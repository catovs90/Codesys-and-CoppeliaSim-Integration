import subprocess
import sys


def install_pip_modules(modules):
    """Install required pip modules."""
    print("Installing required pip modules...")
    try:
        subprocess.run(['python', '-m', 'pip', 'install', '--upgrade', 'pip'], check=True)  # Upgrade pip first
        subprocess.run(['python', '-m', 'pip', 'install'] + modules, check=True)
        print(f"Successfully installed modules: {modules}")

    except subprocess.CalledProcessError as e:
        print(f"Failed to install pip modules: {modules}. Error: {e}")
        sys.exit(1)

def main():
    """Main function."""
    # Modulene som skal installeres
    required_modules = ['pyModbusTCP', 'cbor2', 'pyzmq']
    
    # Installer moduler
    install_pip_modules(required_modules)

if __name__ == "__main__":
    main()
