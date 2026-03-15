#!/usr/bin/env bash
extract(){
    if [ -f "$1" ] ;then 
        case "$1" in 
            *.tar.bz2)   tar xjf "$1"    ;; 
            *.tar.gz)    tar xzf "$1"    ;; 
            *.bz2)       bunzip2 "$1"    ;; 
            *.dmg)       hdiutil  "$1" ;; 
            *.gz)        gunzip "$1"     ;; 
            *.rar)       unrar x "$1"    ;;
            *.tar)       tar xf "$1"     ;; 
            *.tbz2)      tar xjf "$1"    ;; 
            *.tgz)       tar xzf "$1"    ;; 
            *.zip)       unzip "$1"      ;; 
            *.ZIP)       unzip "$1"      ;; 
            *.pax)       cat "$1" | pax -r ;; 
            *.pax.Z)     uncompress "$1"  ;; 
            *.Z)         uncompress "$1"  ;; 
            *)           echo "'$1' cannot be extracted/ed via extract()" ;; 
        esac 
    else 
        echo "'$1' is not a valid file" 
    fi
}