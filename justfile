build-target := "." / ".build"
default:
  just --list
handnotes-pdf:
    make -f scripts/Makefile.xournalpp BASEPATH=./static/handnotes
    make -f scripts/Makefile.xournalpp BASEPATH=./private/static/handnotes
handnotes-pdf-clean:
    make -f scripts/Makefile.xournalpp BASEPATH=./static/handnotes clean
    make -f scripts/Makefile.xournalpp BASEPATH=./private/static/handnotes clean
handnotes-pdf-rebuild: handnotes-pdf-clean handnotes-pdf
_mkdir-build-target:
    mkdir -p {{build-target}}
public-build: _mkdir-build-target
    emanote gen {{build-target}}
    rm -rf {{build-target}}/scripts {{build-target}}/justfile
clean-build-target:
    rm -rf {{build-target}}
serve:
    zk serve
