#!/bin/bash

LOG_FILE="/var/log/ufw.log"

while true
do
    CHOICE=$(dialog --clear --backtitle "Linux Firewall Tester" \
        --title "Main Menu" \
        --menu "Choose an option:" 20 60 7 \
        1 "UFW Rules" \
        2 "Block IP Address" \
        3 "Allow Port" \
        4 "Block Port" \
        5 "Ping Host" \
        6 "View Firewall Logs (Traceback)" \
        7 "Exit" \
        3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            SUB_CHOICE=$(dialog --clear --backtitle "UFW Rule Manager" \
                --title "UFW Rules Menu" \
                --menu "Choose an action:" 15 60 3 \
                1 "View Rules" \
                2 "Edit Rule" \
                3 "Delete Rule" \
                3>&1 1>&2 2>&3)

            case $SUB_CHOICE in
                1)
                    sudo ufw status numbered > /tmp/output.txt
                    if [ ! -s /tmp/output.txt ]; then
                        echo "No active UFW rules found or UFW is disabled." > /tmp/output.txt
                    fi
                    dialog --textbox /tmp/output.txt 20 70
                    ;;
                2)
                    sudo ufw status numbered > /tmp/ufw_rules.txt
                    dialog --textbox /tmp/ufw_rules.txt 20 70
                    RULE_NUM=$(dialog --inputbox "Enter rule number to edit:" 8 40 3>&1 1>&2 2>&3)
                    NEW_RULE=$(dialog --inputbox "Enter new rule (e.g., allow 80/tcp):" 8 50 3>&1 1>&2 2>&3)
                    if [[ -n "$RULE_NUM" && -n "$NEW_RULE" ]]; then
                        sudo ufw delete "$RULE_NUM"
                        sudo ufw $NEW_RULE > /tmp/output.txt
                        dialog --msgbox "Rule updated successfully.\n$(cat /tmp/output.txt)" 10 60
                    fi
                    ;;
                3)
                    sudo ufw status numbered > /tmp/ufw_rules.txt
                    dialog --textbox /tmp/ufw_rules.txt 20 70
                    RULE_NUM=$(dialog --inputbox "Enter rule number to delete:" 8 40 3>&1 1>&2 2>&3)
                    if [[ -n "$RULE_NUM" ]]; then
                        sudo ufw delete "$RULE_NUM" > /tmp/output.txt
                        dialog --msgbox "$(cat /tmp/output.txt)" 10 50
                    fi
                    ;;
            esac
            ;;
        2)
            IP=$(dialog --inputbox "Enter IP address to block:" 8 40 3>&1 1>&2 2>&3)
            if [[ -n "$IP" ]]; then
                sudo ufw deny from "$IP" > /tmp/output.txt
                dialog --msgbox "$(cat /tmp/output.txt)" 10 50
            fi
            ;;
        3)
            PORT=$(dialog --inputbox "Enter port number to allow:" 8 40 3>&1 1>&2 2>&3)
            if [[ -n "$PORT" ]]; then
                sudo ufw allow "$PORT"/tcp > /tmp/output.txt
                dialog --msgbox "$(cat /tmp/output.txt)" 10 50
            fi
            ;;
        4)
            BLOCKPORT=$(dialog --inputbox "Enter port number to block:" 8 40 3>&1 1>&2 2>&3)
            if [[ -n "$BLOCKPORT" ]]; then
                sudo ufw deny "$BLOCKPORT"/tcp > /tmp/output.txt
                dialog --msgbox "$(cat /tmp/output.txt)" 10 50
            fi
            ;;
        5)
            HOST=$(dialog --inputbox "Enter host or IP to ping:" 8 40 3>&1 1>&2 2>&3)
            if [[ -n "$HOST" ]]; then
                ping -c 4 "$HOST" > /tmp/output.txt
                dialog --textbox /tmp/output.txt 20 70
            fi
            ;;
        6)
            if [ -f "$LOG_FILE" ]; then
                FILTER_CHOICE=$(dialog --menu "Choose a log filter:" 15 50 3 \
                    1 "View All Logs" \
                    2 "Filter by IP" \
                    3 "Filter by Port" \
                    3>&1 1>&2 2>&3)

                case $FILTER_CHOICE in
                    1)
                        FILTER_CMD="cat \"$LOG_FILE\""
                        ;;
                    2)
                        IP_FILTER=$(dialog --inputbox "Enter IP address to filter:" 8 40 3>&1 1>&2 2>&3)
                        FILTER_CMD="grep \"$IP_FILTER\" \"$LOG_FILE\""
                        ;;
                    3)
                        PORT_FILTER=$(dialog --inputbox "Enter port number to filter:" 8 40 3>&1 1>&2 2>&3)
                        FILTER_CMD="grep \"DPT=$PORT_FILTER\" \"$LOG_FILE\""
                        ;;
                    *)
                        continue
                        ;;
                esac

                eval $FILTER_CMD | awk '/UFW/ {
                    for(i=1;i<=NF;i++) {
                        if ($i ~ /SRC=/) src=$i;
                        if ($i ~ /DST=/) dst=$i;
                        if ($i ~ /PROTO=/) proto=$i;
                        if ($i ~ /SPT=/) spt=$i;
                        if ($i ~ /DPT=/) dpt=$i;
                    }
                    print strftime("%Y-%m-%d %H:%M:%S"), $6, $7, proto, src, dst, spt, dpt;
                }' | tail -n 30 > /tmp/structured_log.txt

                if [ -s /tmp/structured_log.txt ]; then
                    dialog --title "Filtered Firewall Logs" --textbox /tmp/structured_log.txt 20 80
                else
                    dialog --msgbox "No matching logs found." 10 50
                fi
            else
                dialog --msgbox "No UFW logs found at $LOG_FILE" 10 50
            fi
            ;;
        7)
            clear
            exit
            ;;
    esac
done

