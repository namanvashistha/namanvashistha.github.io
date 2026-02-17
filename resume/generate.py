import json
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional
from jinja2 import Environment, FileSystemLoader

# Configuration
BASE_DIR = Path(__file__).parent
PROFILES_DIR = BASE_DIR / "profiles"
OUTPUT_DIR = BASE_DIR / "output"  # Intermediate files (.tex, .aux, .log)
PUBLIC_DIR = BASE_DIR.parent / "dist"  # Final PDFs go directly to dist/
TEMPLATE_FILE = "template.tex.j2"


def latex_escape(text: str) -> str:
    """
    Escape special LaTeX characters in a string.
    
    This function handles all special LaTeX characters that would otherwise
    cause compilation errors. It processes text character-by-character to
    avoid double-escaping issues.
    
    Special characters handled:
    - Backslash (\)
    - Ampersand (&)
    - Percent (%)
    - Dollar sign ($)
    - Hash/Pound (#)
    - Underscore (_)
    - Left brace ({)
    - Right brace (})
    - Tilde (~)
    - Caret (^)
    """
    if not isinstance(text, str):
        return text
    
    # Character-by-character processing to avoid conflicts
    result = []
    for char in text:
        if char == '\\':
            result.append(r'\textbackslash{}')
        elif char == '&':
            result.append(r'\&')
        elif char == '%':
            result.append(r'\%')
        elif char == '$':
            result.append(r'\$')
        elif char == '#':
            result.append(r'\#')
        elif char == '_':
            result.append(r'\_')
        elif char == '{':
            result.append(r'\{')
        elif char == '}':
            result.append(r'\}')
        elif char == '~':
            result.append(r'\textasciitilde{}')
        elif char == '^':
            result.append(r'\textasciicircum{}')
        else:
            result.append(char)
    
    return ''.join(result)


def get_output_name(profile_filename: str) -> str:
    """
    Generate output PDF name from profile filename.
    Pattern: <id>_<description>.json -> resume_<id>.pdf
    
    Examples:
        base_main.json -> resume.pdf
        1_backend.json -> resume_1.pdf
        2_fullstack.json -> resume_2.pdf
        base_draft.json -> resume_draft.pdf
    """
    stem = Path(profile_filename).stem  # Remove .json
    parts = stem.split("_", 1)  # Split on first underscore only
    
    if len(parts) == 1:
        # No underscore, use as-is
        resume_id = parts[0]
    else:
        resume_id, description = parts
        # If description contains "draft", append it
        if "draft" in description.lower():
            resume_id = f"{resume_id}_draft"
    
    # Special case: "base" becomes just "resume.pdf"
    if resume_id == "base":
        return "resume.pdf"
    
    return f"resume_{resume_id}.pdf"


def generate_resume(profile_path: Path):
    """Generate resume PDF from a JSON profile."""
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    profile_filename = profile_path.name
    output_pdf_name = get_output_name(profile_filename)
    output_name = Path(output_pdf_name).stem  # Remove .pdf extension for tex file

    output_tex = OUTPUT_DIR / f"{output_name}.tex"
    output_pdf = OUTPUT_DIR / output_pdf_name

    # 1. Load Data
    with open(profile_path, "r") as f:
        data = json.load(f)

    # 2. Calculate years of experience (from August 1, 2021)
    start_date = datetime(2021, 8, 1)
    current_date = datetime.now()
    years_of_experience = (current_date - start_date).days / 365.25
    data['years_of_experience'] = f"{int(years_of_experience)}"

    # 3. Setup Jinja2 Environment
    env = Environment(
        loader=FileSystemLoader(BASE_DIR),
        block_start_string="((*",
        block_end_string="*))",
        variable_start_string="(((",
        variable_end_string=")))",
        comment_start_string="((=",
        comment_end_string="=))",
    )
    
    # Register custom LaTeX escape filter
    env.filters['latex_escape'] = latex_escape
    
    template = env.get_template(TEMPLATE_FILE)

    # 4. Render Template
    rendered_tex = template.render(**data)

    # 5. Write Output
    with open(output_tex, "w") as f:
        f.write(rendered_tex)

    print(f"Generated {output_tex}")

    # 6. Compile PDF
    try:
        subprocess.run(
            ["pdflatex", "-output-directory", str(OUTPUT_DIR), str(output_tex)],
            check=True,
            cwd=BASE_DIR,
        )
        print(f"PDF generated: {output_pdf}")
        
        # 7. Copy PDF to public directory for web access
        PUBLIC_DIR.mkdir(exist_ok=True)
        public_pdf = PUBLIC_DIR / output_pdf_name
        shutil.copy2(output_pdf, public_pdf)
        print(f"Copied to: {public_pdf}")
        
        return output_pdf
    except subprocess.CalledProcessError as e:
        print("Error compiling PDF:", e)
        return None


if __name__ == "__main__":
    if len(sys.argv) > 1:
        profile_path = Path(sys.argv[1])
    else:
        profile_path = PROFILES_DIR / "base.json"
    
    generate_resume(profile_path)
