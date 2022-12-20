# Resume

This repository generates a PDF of my resume using
[LaTeX](https://www.latex-project.org/). I used
[flyx's article](https://flyx.org/nix-flakes-latex/) to help me create a nix
flake to build a resume generator command.

## Usage

Use the flake!

```bash
❯ nix run github:alejandro-angulo/resume -- -h

Usage: alejandro-resume [-h] [-d] [-e EMAIL] [-p PHONENUMBER]
    -h              Prints this usage message.

    -d              Saves latexmk log file (will be named alejandro_resume.log)

    -e EMAIL        Sets email address used when building document.
                    Can also be set with EMAIL environment variable.

    -p PHONENUMBER  Sets phone number used when building the document.
                    Can also be set with PHONENUMBER environment variable.


❯ nix run github:alejandro-angulo/resume -- -e 'foo@bar.com' -p '(555) 555-5555'
```

The email and phone number parameters are required because I didn't want to
hardcode those in my tex file. Hopefully this helps prevent spammers from
finding my personal contact information.
