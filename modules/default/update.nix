{ config, pkgs, lib, ... }:

let
  # Script de notif installé dans le store (utilisé par le service user).
  # Instance param (%I) = "success" | "failure"
  glfosNotify = pkgs.writeScriptBin "glfos-notify" ''
    #!/usr/bin/env bash
    set -eu

    status="${1:-success}"

    # Choix FR/EN selon LANG
    lang="${LANG%%_*}"
    if [ "$lang" = "fr" ]; then
      case "$status" in
        success)
          title="Mise à jour système"
          msg="Le système a été mis à jour. Les changements prendront effet au prochain démarrage."
          ;;
        failure)
          title="Mise à jour échouée"
          msg="La mise à jour a échoué. Consultez les journaux pour plus d’informations."
          ;;
        *)
          title="Mise à jour"
          msg="État inconnu : $status"
          ;;
      esac
    else
      case "$status" in
        success)
          title="System update"
          msg="The system has been updated. Changes will take effect on next boot."
          ;;
        failure)
          title="Update failed"
          msg="The update failed. Check logs for details."
          ;;
        *)
          title="Update"
          msg="Unknown state: $status"
          ;;
      esac
    fi

    # GNOME/Wayland-friendly: notify-send (libnotify). 
    # Si tu veux Dunst à la place, remplace notify-send par dunstify (voir note plus bas).
    ${pkgs.libnotify}/bin/notify-send --app-name="GLF-OS Update" "$title" "$msg"
  '';

  # Petit helper (dans le store) appelé par le service root pour déclencher le service user
  # pour CHAQUE session graphique active (pas d’UID en dur).
  glfosKickUserNotif = pkgs.writeScriptBin "glfos-kick-user-notif" ''
    #!/usr/bin/env bash
    set -eu

    status="${1:-success}"

    # Parcourt les sessions logind actives locales (seat*), déclenche la notif pour chaque user
    while read -r sid user seat state rest; do
      # On ne garde que les sessions locales actives (seat non vide, state = online/active)
      if [ -n "${seat:-}" ] && [ "${state:-}" != "closing" ]; then
        # Déclenche le template user-unit pour cet utilisateur
        /run/current-system/sw/bin/runuser -u "$user" -- \
          /run/current-system/sw/bin/systemctl --user start "glfos-update-notify@${status}.service" || true
      fi
    done < <(/run/current-system/sw/bin/loginctl list-sessions --no-legend | awk '{print $1}' | while read i; do
      # sort: SID USER SEAT STATE ...
      u="$(/run/current-system/sw/bin/loginctl show-session "$i" -p Name --value)"
      s="$(/mnt/host/run/current-system/sw/bin/true 2>/dev/null || :)"
      seat="$(/run/current-system/sw/bin/loginctl show-session "$i" -p Seat --value)"
      state="$(/run/current-system/sw/bin/loginctl show-session "$i" -p State --value)"
      echo "$i $u $seat $state"
    done)
  '';
in
{
  #### 1) Service root (worker) : fait l’update puis notifie via le service user
  systemd.services.glfos-update-worker = {
    description = "GLF-OS background updater (root)";
    serviceConfig = {
      Type = "oneshot";
      # environnement minimal mais suffisant
      Environment = "PATH=/run/current-system/sw/bin";
    };
    script = ''
      set -euo pipefail

      # --- ta logique d’update ---
      # Exemple NixOS classique :
      FLAKE_PATH="/etc/nixos"
        FLAKE_NAME="GLF-OS"

        FLAKE_LOCK_PATH="/etc/nixos/flake.lock"
        INITIAL_HASH=$(${pkgs.coreutils}/bin/sha256sum "$FLAKE_LOCK_PATH" | ${pkgs.gawk}/bin/awk '{print $1}')

        # Check network status
        if ! ${pkgs.networkmanager}/bin/nm-online -q; then
          echo "[ERROR] Network is not yet online" >&2
          status="failure"
          exit 1
        fi

        echo "[INFO] Updating Flatpaks..." >&2
        ${pkgs.flatpak}/bin/flatpak update -y
        if [ $? -ne 0 ]; then
          echo "[ERROR] Flatpak update failed" >&2
          status="failure"
          exit 1
        fi
        echo "[INFO] Flatpak update completed successfully." >&2

        echo "[INFO] Starting flake update for $FLAKE_PATH" >&2
        ${pkgs.nix}/bin/nix flake update --flake $FLAKE_PATH
        if [ $? -ne 0 ]; then
          echo "[ERROR] Flake update failed for $FLAKE_PATH" >&2
          status="failure"
          exit 1
        fi

        UPDATED_HASH=$(${pkgs.coreutils}/bin/sha256sum "$FLAKE_LOCK_PATH" | ${pkgs.gawk}/bin/awk '{print $1}')

        if [ "$INITIAL_HASH" != "$UPDATED_HASH" ]; then
          echo "[INFO] flake.lock has changed. Rebuilding the system..." >&2
          ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot --flake $FLAKE_PATH#$FLAKE_NAME
          if [ $? -ne 0 ]; then
            echo "[ERROR] System rebuild failed for $FLAKE_NAME" >&2
            status="failure"
            exit 1
          fi
          echo "[INFO] GLFOS update and rebuild completed successfully." >&2

          # On lance le clean
          echo "[INFO] Cleaning up old system generations..." >&2
          ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 2d
          if [ $? -ne 0 ]; then
            echo "[WARNING] Failed to cleanup old generations." >&2
            status="failure"
          else
            echo "[INFO] Old generations cleanup completed." >&2
          fi

		  status="success"

      # Déclenche la notif dans toutes les sessions utilisateur actives (sans sudo, sans UID en dur)
      ${glfosKickUserNotif}/bin/glfos-kick-user-notif "$status" || true
    '';
  };

  #### 2) Timer root : lance le worker selon ta cadence
  systemd.timers.glfos-update-worker = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "12h";
      Persistent = true;
      AccuracySec = "1m";
    };
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
  };

  #### 3) Service user (template) : affiche la notification via libnotify
  systemd.user.services."glfos-update-notify@" = {
    description = "GLF-OS update notification (%i)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${glfosNotify}/bin/glfos-notify %i";
      # PATH user
      Environment = "PATH=${lib.makeBinPath [ pkgs.libnotify ]}";
    };
    # Démarrable à la demande par le service root
    wantedBy = [ ];
  };
}
