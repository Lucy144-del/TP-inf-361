#!/bin/bash

# ================================================================= #
# Script : create_users.sh                                          #
# Objectif : Automatiser la création d'utilisateurs Linux à partir  #
#            d'un fichier texte, avec configuration avancée.        #
# Usage : sudo ./create_users.sh <nom_du_groupe>                    #
# Exemple : sudo ./create_users.sh students-inf-361                 #
# ================================================================= #

# -----------------------
# 1. VARIABLES GLOBALES |
# -----------------------
LOG_FILE="creation_journal_$(date +%Y%m%d_%H%M%S).log"  # Fichier de log avec timestamp
INPUT_FILE="users.txt"                                   # Fichier source des utilisateurs
GROUP_NAME=""                                            # Nom du groupe (sera fourni en argument)

# -------------------------------
# 2. FONCTION DE JOURNALISATION |
# -------------------------------
# Écrit un message à la fois dans le terminal et dans le fichier de log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# -----------------------------
# 3. VÉRIFICATIONS PRÉALABLES |
# -----------------------------

# 3.1 Vérifier que le script est exécuté en root (ou avec sudo)
if [[ $EUID -ne 0 ]]; then
    echo "ERREUR : Ce script doit être exécuté en tant que root (ou avec sudo)." | tee -a "$LOG_FILE"
    exit 1
fi

# 3.2 Vérifier qu'un argument (nom du groupe) a été fourni
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <nom_du_groupe>" | tee -a "$LOG_FILE"
    echo "Exemple: $0 students-inf-361" | tee -a "$LOG_FILE"
    exit 1
fi

GROUP_NAME="$1"  # Stocker le premier argument dans la variable GROUP_NAME

log_message "=== DÉBUT DU SCRIPT DE CRÉATION D'UTILISATEURS ==="
log_message "Groupe cible : $GROUP_NAME"
log_message "Fichier d'entrée : $INPUT_FILE"

# ---------------------------------
# 4. CRÉATION DU GROUPE PRINCIPAL |
# ---------------------------------
if ! getent group "$GROUP_NAME" > /dev/null; then
    if groupadd "$GROUP_NAME"; then
        log_message "Groupe créé : $GROUP_NAME"
    else
        log_message "ERREUR: Impossible de créer le groupe $GROUP_NAME"
        exit 1
    fi
else
    log_message "Le groupe $GROUP_NAME existe déjà."
fi

# -------------------------------------
# 5. VÉRIFICATION DU FICHIER D'ENTRÉE |
# -------------------------------------
if [[ ! -f "$INPUT_FILE" ]]; then
    log_message "ERREUR : Le fichier $INPUT_FILE est introuvable."
    exit 1
fi

log_message "Lecture du fichier $INPUT_FILE..."

# Compteur d'utilisateurs
USER_COUNT=0
SUCCESS_COUNT=0
ERROR_COUNT=0

# ------------------------------------
# 6. BOUCLE PRINCIPALE DE TRAITEMENT |
# ------------------------------------
while IFS=';' read -r username password full_name phone email preferred_shell; do
    # 6.1 Ignorer les lignes vides ou les commentaires (commençant par #)
    [[ -z "$username" || "$username" =~ ^# ]] && continue
    
    # 6.2 Validation des champs obligatoires
    if [[ -z "$username" || -z "$password" || -z "$full_name" ]]; then
        log_message "ERREUR: Ligne mal formatée (champs manquants) - ligne ignorée"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi
    
    USER_COUNT=$((USER_COUNT + 1))
    log_message "--- Traitement de l'utilisateur $USER_COUNT : $username ---"

    # --------------------------------------------------
    # 6.3 VÉRIFICATION / INSTALLATION DU SHELL PRÉFÉRÉ |
    # --------------------------------------------------
    SHELL_PATH="$preferred_shell"
    SHELL_NAME="${SHELL_PATH##*/}"
    
    # Vérifier d'abord si le fichier shell existe physiquement
    if [[ -f "$SHELL_PATH" ]]; then
        # Fichier existe, vérifier s'il est dans PATH
        if ! command -v "$SHELL_NAME" > /dev/null; then
            log_message "  Shell '$SHELL_PATH' existe mais n'est pas dans PATH."
        fi
    elif ! command -v "$SHELL_NAME" > /dev/null; then
        # Ni fichier, ni dans PATH -> tentative d'installation
        log_message "  Shell '$preferred_shell' non trouvé. Tentative d'installation..."
        
        # Détection de la distribution
        if command -v apt-get &>/dev/null; then
            if apt-get install -y "$SHELL_NAME" 2>/dev/null; then
                log_message "  Shell $SHELL_NAME installé avec succès."
            else
                log_message "  Échec de l'installation de $SHELL_NAME. Utilisation de /bin/bash."
                SHELL_PATH="/bin/bash"
            fi
        elif command -v yum &>/dev/null; then
            if yum install -y "$SHELL_NAME" 2>/dev/null; then
                log_message "  Shell $SHELL_NAME installé avec succès."
            else
                log_message "  Échec de l'installation de $SHELL_NAME. Utilisation de /bin/bash."
                SHELL_PATH="/bin/bash"
            fi
        elif command -v dnf &>/dev/null; then
            if dnf install -y "$SHELL_NAME" 2>/dev/null; then
                log_message "  Shell $SHELL_NAME installé avec succès."
            else
                log_message "  Échec de l'installation de $SHELL_NAME. Utilisation de /bin/bash."
                SHELL_PATH="/bin/bash"
            fi
        else
            log_message "  Gestionnaire de paquets non reconnu. Utilisation de /bin/bash."
            SHELL_PATH="/bin/bash"
        fi
    fi
    
    # Vérification finale que le shell existe
    if [[ ! -f "$SHELL_PATH" ]] && ! command -v "$SHELL_NAME" > /dev/null; then
        log_message "  ATTENTION: Le shell $SHELL_PATH n'existe pas, utilisation de /bin/bash"
        SHELL_PATH="/bin/bash"
    fi

    # -----------------------------------------------
    # 6.4 CRÉATION OU MODIFICATION DE L'UTILISATEUR |
    # -----------------------------------------------
    if id "$username" &>/dev/null; then
        log_message "  L'utilisateur $username existe déjà. Modification..."
        if usermod -c "$full_name" -s "$SHELL_PATH" "$username"; then
            log_message "  Utilisateur $username modifié."
        else
            log_message "  ERREUR: Impossible de modifier l'utilisateur $username"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            continue
        fi
    else
        log_message "  Création de l'utilisateur $username..."
        if useradd -m -c "$full_name" -s "$SHELL_PATH" "$username"; then
            log_message "  Utilisateur $username créé avec succès."
        else
            log_message "  ERREUR: Impossible de créer l'utilisateur $username"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            continue
        fi
    fi

    # ----------------------------------------------------
    # 6.5 AJOUT DES INFORMATIONS SUPPLEMENTAIRES (GECOS) |
    # ----------------------------------------------------
    # Utilisation correcte de chfn selon le manuel
    if chfn -f "$full_name" -w "$phone" "$username" 2>/dev/null; then
        log_message "  Informations de contact ajoutées (tel: $phone)."
    else
        log_message "  ATTENTION: Impossible de définir les informations GECOS pour $username"
    fi
    
    # Stocker l'email séparément (chfn ne supporte pas bien l'email sur toutes les distribs)
    if [[ -n "$email" ]]; then
        usermod -c "$full_name ($email)" "$username" 2>/dev/null || \
        log_message "  ATTENTION: Impossible d'ajouter l'email aux informations"
    fi

    # ------------------------------------------------------
    # 6.6 GESTION DU MOT DE PASSE (HACHAGE + FORCE CHANGE) |
    # ------------------------------------------------------
    # 6.6.1 Hachage du mot de passe en SHA-512
    if PASSWORD_HASH=$(openssl passwd -6 "$password" 2>/dev/null); then
        # 6.6.2 Appliquer le mot de passe haché (méthode plus robuste)
        if echo "$username:$password" | chpasswd 2>/dev/null; then
            log_message "  Mot de passe défini pour $username (hashé automatiquement)."
        elif usermod -p "$PASSWORD_HASH" "$username" 2>/dev/null; then
            log_message "  Mot de passe défini pour $username (hashé SHA-512)."
        else
            log_message "  ERREUR: Impossible de définir le mot de passe pour $username"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        log_message "  ERREUR: Impossible de hasher le mot de passe pour $username"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    # 6.6.3 Forcer le changement à la première connexion
    if chage -d 0 "$username" 2>/dev/null; then
        log_message "  Changement de mot de passe forcé à la première connexion."
    else
        log_message "  ATTENTION: Impossible de forcer le changement de mot de passe"
    fi

    # -------------------------
    # 6.7 GESTION DES GROUPES |
    # -------------------------
    # 6.7.1 Ajouter l'utilisateur au groupe principal
    if usermod -aG "$GROUP_NAME" "$username" 2>/dev/null; then
        log_message "  Utilisateur ajouté au groupe : $GROUP_NAME"
    else
        log_message "  ERREUR: Impossible d'ajouter $username au groupe $GROUP_NAME"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    # 6.7.2 Ajouter l'utilisateur au groupe sudo
    if usermod -aG sudo "$username" 2>/dev/null; then
        log_message "  Utilisateur ajouté au groupe sudo."
    else
        log_message "  ATTENTION: Impossible d'ajouter $username au groupe sudo"
    fi

    # 6.7.3 Restriction de la commande 'su' pour le groupe
    if ! grep -q "^auth.*su.*$GROUP_NAME" /etc/pam.d/su 2>/dev/null; then
        if echo "auth required pam_deny.so group=$GROUP_NAME" >> /etc/pam.d/su 2>/dev/null; then
            log_message "  Restriction 'su' appliquée pour le groupe $GROUP_NAME."
        else
            log_message "  ATTENTION: Impossible d'appliquer la restriction 'su'"
        fi
    fi

    # ---------------------------------------
    # 6.8 MESSAGE DE BIENVENUE PERSONNALISÉ |
    # ---------------------------------------
    WELCOME_FILE="/home/$username/WELCOME.txt"
    if cat > "$WELCOME_FILE" <<EOF
Bienvenue $full_name !

Votre compte a été créé avec succès sur le serveur $(hostname).
Nom d'utilisateur : $username
Shell par défaut : $SHELL_PATH
Email enregistré : $email
Téléphone : $phone

Veuillez changer votre mot de passe dès votre première connexion.

Cordialement,
Administration Système
EOF
    then
        chown "$username:$username" "$WELCOME_FILE" 2>/dev/null
        chmod 644 "$WELCOME_FILE" 2>/dev/null
        
        # 6.8.3 Configurer l'affichage automatique dans .bashrc (méthode non destructive)
        BASHRC_FILE="/home/$username/.bashrc"
        if [[ ! -f "$BASHRC_FILE" ]] || ! grep -q "WELCOME.txt" "$BASHRC_FILE" 2>/dev/null; then
            # Créer ou modifier .bashrc de manière non destructive
            TEMP_FILE=$(mktemp /tmp/bashrc_XXXXXX)
            
            # Ajouter notre bloc en premier
            cat > "$TEMP_FILE" <<BASHRC_EOF
# === Message de bienvenue automatique (géré par create_users.sh) ===
if [[ -f ~/WELCOME.txt ]]; then
    echo '========================================='
    cat ~/WELCOME.txt
    echo '========================================='
fi

BASHRC_EOF
            
            # Puis ajouter le contenu original s'il existe (sans doublons de notre bloc)
            if [[ -f "$BASHRC_FILE" ]]; then
                grep -v "WELCOME.txt" "$BASHRC_FILE" | grep -v "create_users.sh" >> "$TEMP_FILE" 2>/dev/null
            fi
            
            # Remplacer l'ancien fichier
            mv "$TEMP_FILE" "$BASHRC_FILE" 2>/dev/null
            chown "$username:$username" "$BASHRC_FILE" 2>/dev/null
            chmod 644 "$BASHRC_FILE" 2>/dev/null
        fi
        
        log_message "  Fichier de bienvenue et .bashrc configurés."
    else
        log_message "  ATTENTION: Impossible de créer le fichier de bienvenue"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    # ----------------------------------------------------
    # 6.9 CONFIGURATION DES QUOTAS DISQUE (15 GO LIMITE) |
    # ----------------------------------------------------
    if command -v setquota &>/dev/null; then
        # Vérifier si les quotas sont activés sur /home
        if mount | grep -q "usrquota.*/home" 2>/dev/null || mount | grep -q "quota.*/home" 2>/dev/null; then
            # Vérifier si l'utilisateur n'a pas déjà de quota
            if ! quota -u "$username" 2>/dev/null | grep -q -E "(Limit|[0-9]+)" 2>/dev/null; then
                LIMIT_BLOCKS=$((15 * 1024 * 1024))  # 15 Go en blocs de 1K
                if setquota -u "$username" 0 $LIMIT_BLOCKS 0 $LIMIT_BLOCKS /home 2>/dev/null; then
                    log_message "  Quota disque configuré (15 Go maximum)."
                else
                    log_message "  ERREUR: Impossible de configurer le quota disque."
                fi
            else
                log_message "  INFO: L'utilisateur $username a déjà un quota configuré."
            fi
        else
            log_message "  INFO: Les quotas ne sont pas activés sur /home."
            log_message "  Pour activer: sudo mount -o remount,usrquota /home && sudo quotacheck -cug /home && sudo quotaon /home"
        fi
    else
        log_message "  INFO: L'outil 'setquota' n'est pas installé. Installation: sudo apt-get install quota"
    fi

    # --------------------------------------------
    # 6.10 LIMITATION MÉMOIRE (20% DE LA RAM MAX) |
    # --------------------------------------------
    if command -v systemctl &>/dev/null && systemctl --version &>/dev/null; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
        if [[ -n "$TOTAL_RAM" ]] && [[ "$TOTAL_RAM" =~ ^[0-9]+$ ]]; then
            LIMIT_RAM=$((TOTAL_RAM * 20 / 100))  # 20% de la RAM
            
            USER_SLICE_DIR="/etc/systemd/system/user-${username}.slice.d"
            if mkdir -p "$USER_SLICE_DIR" 2>/dev/null; then
                if cat > "$USER_SLICE_DIR/limits.conf" 2>/dev/null <<EOF
[Slice]
MemoryMax=${LIMIT_RAM}K
MemoryHigh=$((LIMIT_RAM * 90 / 100))K
EOF
                then
                    if systemctl daemon-reload &>/dev/null; then
                        log_message "  Limite mémoire configurée (${LIMIT_RAM}Ko, soit 20% de la RAM)."
                    else
                        log_message "  ATTENTION: Impossible de recharger systemd"
                    fi
                else
                    log_message "  ATTENTION: Impossible de créer le fichier de configuration systemd"
                fi
            else
                log_message "  ATTENTION: Impossible de créer le dossier systemd slice"
            fi
        else
            log_message "  ATTENTION: Impossible de déterminer la RAM totale"
        fi
    else
        log_message "  INFO: Systemd non détecté. Limites mémoire non configurées."
    fi

    # ---------------------------------------------
    # 6.11 FIN DE TRAITEMENT POUR CET UTILISATEUR |
    # ---------------------------------------------
    log_message "  Utilisateur $username traité avec succès."
    echo "" | tee -a "$LOG_FILE"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

done < "$INPUT_FILE"  # Fin de la boucle while (lecture depuis le fichier)

# ------------------
# 7. FIN DU SCRIPT |
# ------------------
log_message "=== SCRIPT TERMINÉ AVEC SUCCÈS ==="
log_message "STATISTIQUES :"
log_message "  - Lignes lues dans $INPUT_FILE : $USER_COUNT"
log_message "  - Utilisateurs créés/modifiés avec succès : $SUCCESS_COUNT"
log_message "  - Erreurs rencontrées : $ERROR_COUNT"
log_message "  - Lignes ignorées (format incorrect) : $((USER_COUNT - SUCCESS_COUNT - ERROR_COUNT))"
log_message ""
log_message "Journal détaillé disponible dans : $LOG_FILE"
log_message ""
log_message "VÉRIFICATIONS RECOMMANDÉES :"
log_message "  1. Vérifier les utilisateurs créés : cat /etc/passwd | grep -E \"$(grep -v '^#' "$INPUT_FILE" | cut -d';' -f1 | tr '\n' '|' | sed 's/|$//')\""
log_message "  2. Vérifier l'appartenance aux groupes : for user in \$(cut -d';' -f1 \"$INPUT_FILE\" | grep -v '^#'); do echo \"\$user : \$(groups \$user 2>/dev/null || echo 'Non trouvé')\"; done"
log_message "  3. Consulter les erreurs : grep -E \"(ERREUR|ATTENTION|INFO:.*[Nn]on.*)\" \"$LOG_FILE\""
log_message "  4. Vérifier les quotas : for user in \$(cut -d';' -f1 \"$INPUT_FILE\" | grep -v '^#'); do echo -n \"\$user: \"; quota -u \$user 2>/dev/null | grep -E \"([0-9]+|none)\" || echo \"Pas de quota\"; done"

exit 0  # Sortie normale
