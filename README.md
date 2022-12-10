# Resume

This repository generates a PDF of my resume using
[LaTeX](https://www.latex-project.org/). I used
[flyx's article](https://flyx.org/nix-flakes-latex/) to help me create a nix
flake to build a resume generator command.

## Usage

Use the flake!

```bash
env EMAIL='foo@bar.com' PHONENUMBER='(555) 555-5555' nix run github:alejandro-angulo/resume
```

The `EMAIL` and `PHONENUMBER` variables are required because I didn't want to
hardcode those in my tex file. Hopefully this helps prevent spammers from
finding my personal contact information.
