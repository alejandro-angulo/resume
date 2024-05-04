![Build workflow](https://github.com/alejandro-angulo/resume/actions/workflows/build.yml/badge.svg)

# Resume

This repository generates a PDF of my resume using
[LaTeX](https://www.latex-project.org/). I used [flyx's
article](https://flyx.org/nix-flakes-latex/) to help me create a nix flake to
build a resume generator command (I update my resume infrequently and it's
always a hassle getting my environment set up).

## Why?

This is nice for me to make sure I have the right environment to work on my
resume. It's not very practical, I admit, to have people run a `nix run`
command to generate the latest version of my resume (but it's kinda cool if
you're into reproducibility and stuff). At some point I should have the latest
version served somewhere on my site.

tl;dr I just wanted an excuse to use nix.

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
