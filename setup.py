#!/usr/bin/env python3
"""
HyprSupreme-Builder Setup Script
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read the contents of README file
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

# Read version from VERSION file
version = (this_directory / "VERSION").read_text().strip()

# Read requirements
requirements = []
requirements_file = this_directory / "requirements.txt"
if requirements_file.exists():
    requirements = requirements_file.read_text().splitlines()
    # Filter out comments and empty lines
    requirements = [req.strip() for req in requirements if req.strip() and not req.startswith('#')]

setup(
    name="hyprsupreme-builder",
    version=version,
    author="HyprSupreme Team",
    author_email="contact@hyprsupreme.dev",
    description="The ultimate Hyprland configuration suite with advanced community features",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/GeneticxCln/HyprSupreme-Builder",
    project_urls={
        "Bug Tracker": "https://github.com/GeneticxCln/HyprSupreme-Builder/issues",
        "Documentation": "https://github.com/GeneticxCln/HyprSupreme-Builder/blob/main/README.md",
        "Source Code": "https://github.com/GeneticxCln/HyprSupreme-Builder",
        "Community": "https://github.com/GeneticxCln/HyprSupreme-Builder/discussions",
    },
    packages=find_packages(where=".", include=["tools*", "gui*", "community*", "modules*"]),
    package_dir={"": "."},
    package_data={
        "": ["*.md", "*.txt", "*.json", "*.yml", "*.yaml", "*.sh"],
        "community": ["templates/*.html", "static/*"],
        "modules": ["**/*"],
        "tools": ["*.py"],
        "gui": ["*.py"],
    },
    include_package_data=True,
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: X11 Applications",
        "Environment :: Console",
        "Environment :: Web Environment",
        "Intended Audience :: End Users/Desktop",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Shell",
        "Topic :: Desktop Environment",
        "Topic :: System :: Installation/Setup",
        "Topic :: Utilities",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "flake8>=5.0.0",
            "black>=22.0.0",
            "isort>=5.10.0",
            "mypy>=1.0.0",
            "bandit>=1.7.0",
            "safety>=2.0.0",
        ],
        "web": [
            "flask>=2.0.0",
            "flask-cors>=4.0.0",
            "requests>=2.28.0",
        ],
        "gui": [
            "tkinter",
            "pillow>=9.0.0",
        ],
        "all": [
            "flask>=2.0.0",
            "flask-cors>=4.0.0",
            "requests>=2.28.0",
            "tkinter",
            "pillow>=9.0.0",
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "flake8>=5.0.0",
            "black>=22.0.0",
            "isort>=5.10.0",
            "mypy>=1.0.0",
            "bandit>=1.7.0",
            "safety>=2.0.0",
        ]
    },
    # Note: Entry points removed due to hyphen-named files
    # Use direct script execution instead
    scripts=[
        "install.sh",
        "hyprsupreme",
        "launch_web.sh",
        "test_keybindings.sh",
        "finalize_project.sh",
    ],
    zip_safe=False,
    keywords=[
        "hyprland", "wayland", "desktop-environment", "configuration",
        "themes", "customization", "linux", "window-manager",
        "community", "builder", "automation"
    ],
)

