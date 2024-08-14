#!/bin/bash

#--------------------------------------------------------------------------------------
#--------------- GLOBAL VARIABLES DECLARATION + INITIALISATION ------------------------
#--------------------------------------------------------------------------------------

DEPART_NAME="$1"
VOORNAAM="Maxim"
ROOT_DIR=""
RO_DIR=""
RW_DIR=""

#--------------------------------------------------------------------------------------
#--------------------------------------- END ------------------------------------------
#--------------------------------------------------------------------------------------


#=================|| Check of user voldoende privileges heeft ||===========================
if [ $(id -u) -ne 0 ]; then     #als de user id van gebruiker niet gelijk is aan 0 (0 is root of sudo)
    echo "Please run this script as root or using sudo!"
    echo "Press enter to continue..."
    read
  exit 1
fi

#===========================|| Maak terminal leeg ||=======================================
clear

#============|| Check argument, als er geen arugument is, exit code 1 ||===================
if [ -z "$DEPART_NAME" ]; then #-z "DEPART_NAME" checks if the string is empty. If empty function will return TRUE
    echo "Error, geen afdelingsnaam gevonden. Gebruik het script als volgt :"
    echo "./maxim-maakafdeling.sh <afdelingsnaam>"
    echo "Press enter to exit..."
    read
    exit 1 
else
    echo "Afdelingsnaam is $DEPART_NAME"
fi



:'controleer alternatief : 

   while [[ -z $DEPART_NAME ]]; do
        echo "Error, geen afdelingsnaam gevonden. Gelieve een naam in te geven :"
        read DEPART_NAME
    done

    DEPART_NAME=$1
    echo "Afdelingsnaam is $DEPART_NAME" '

  

#==================|| Maak een directory in de root directory ||===========================
ROOT_DIR= "/$VOORNAAM"
mkdir /$VOORNAAM
echo "Hoofddirectory $ROOT_DIR is aangemaakt."

#=============|| Maak binnen de nieuwe directory twee nieuwe subdirectories ||=============
RW_DIR="$ROOT_DIR/$DEPART_NAME-docs"
RO_DIR="$ROOT_DIR/$DEPART_NAME-rodocs"
mkdir -p $RW_DIR
mkdir -p $RO_DIR
echo "Subdirectories $RW_DIR en $RO_DIR zijn aangemaakt"

#==|| Vervang de lijn met "GID_MIN" in het bestand /etc/login.defs door "GID_MIN 3000" ||==
cp /etc/login.defs /etc/login.defs.bak  # Maak een back-up
sed -i 's/^GID_MIN.*/GID_MIN 3000/' /etc/login.defs
echo "GID_MIN is vervangen door 3000 in /etc/login.defs."

#===========|| Maak een nieuwe groep met de naam <argument>-verkoop ||=====================
GROUP_NAME="$DEPART_NAME-verkoop"
groupadd $GROUP_NAME
echo "Groep $GROUP_NAME is aangemaakt."

#================|| Echo de gid en de naam van de nieuwe groep ||==========================
GID=$(getent group $GROUP_NAME | cut -d: -f3)
echo "GID van de groep $GROUP_NAME is $GID."

#============================|| set UID_MIN 2500 ||========================================
cp /etc/login.defs /etc/login.defs.bak      # Maak een back-up
sed -i 's/^UID_MIN.*/UID_MIN 2500/' /etc/login.defs #zoek de lijn met UID_MIN en vervang deze met UID_MIN 2500.

#===================|| Maak 2 users en stel wachtwoorden in  ||============================
USER1="$DEPART_NAME-user1"
USER2="$DEPART_NAME-user2"
useradd -m -g $GROUP_NAME -s /bin/bash $USER1   #-m flag creates homedir if it doesnt exist, -g flag sets users inital login group
useradd -m -g $GROUP_NAME -s /bin/bash $USER2   #-s flag sets the default shell for this user

echo "Stel een wachtwoord in voor $USER1:"
passwd $USER1                               #will prompt user for password input
chage -d 0 -M 40 $USER1                     #chage -d --> set to 0 so the system sees the password as expired and will promt user to change it on first login
                                            #chage -m --> mindays, minimum amount of days to change
echo "Stel een wachtwoord in voor $USER2:"
passwd $USER2
chage -d 0 -M 40 $USER2

echo "Gebruikers $USER1 en $USER2 zijn aangemaakt en zijn leden van $GROUP_NAME."

#======================|| Maak 1 admin user ||=============================================
ADMIN="$DEPART_NAME-admin"
useradd -m -g $GROUP_NAME -s /bin/sh $ADMIN

echo "Stel een wachtwoord in voor $ADMIN:"
passwd $ADMIN
chage -d 0 -M 40 $ADMIN
echo "Admin gebruiker $ADMIN is aangemaakt en is lid van $GROUP_NAME."

chown $ADMIN:$GROUP $RW_DIR                 #changeowner 
chown $ADMIN:$GROUP $RO_DIR

chmod 775 $RW_DIR                           # admin: rwx, group: rwx, others: r-x -  is directory dus moet uitvoerbaar zijn
chmod 750 $RO_DIR                           # admin: rwx, group: r--, others: ---    is directory dus moet uitvoerbaar zijn
chmod +t $RW_DIR                            # Sticky bit op RWdocs
chmod +t $RO_DIR                            # Sticky bit op ROdocs

mkdir $ROOT_DIR/$VOORNAAM
touch $ROOT_DIR/$VOORNAAM/demodoc.maxim
echo "This file is created by the script" > $ROOT_DIR/$VOORNAAM/demodoc.maxim
echo "Demodoc created in $ROOT_DIR/$VOORNAAM"

#=====|| Laat de eerste 5 groepen zien uit het groepenbestand in alfabetische volgorde ||=====
echo "De eerste 5 groepen in alfabetische volgorde zijn:"
cut -d: -f1 /etc/group | sort | head -n 5       #cut -d (delimiter is :) -f1 --> field 1 --> piped naar sort (default alfabetisch) piped naar head -n 5 (eerste 5)

#=====|| Toon de laatste 4 gebruikers uit het gebruikersbestand in omgekeerde alfabetische volgorde ||=====
echo "De laatste 4 gebruikers in omgekeerde alfabetische volgorde zijn:"
cut -d: -f1 /etc/passwd | sort -r | tail -n 4   #cut -d (delimiter is :) -f1 --> field 1 --> piped naar sort (default alfabetisch), -r reversed piped naar tail -n 4 (eerste 4)

#===================|| Toon alle gebruikers waarvan de naam begint met "sys" ||============================
echo "Gebruikers waarvan de naam begint met 'sys':"
cut -d: -f1 /etc/passwd | grep '^sys'

#===================|| Toon de lange directory-inhoud van de hoofddirectory ||=============================
echo "Lange directory-inhoud van $ROOT_DIR:"
ls -lsa $ROOT_DIR

#===================|| cleanup and put everything back to default values ||================================
rm -f /etc/login.defs                       #force remove
mv /etc/login.defs.bak /etc/login.defs      #put backup back in place

echo "============================================================================"
echo "====================== Script finished without errors ======================"
echo "============================================================================"
