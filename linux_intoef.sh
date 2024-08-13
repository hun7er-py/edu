#!/bin/bash

#--------------------------------------------------------------------------------------
#--------------- GLOBAL VARIABLES DECLARATION + INITIALISATION ------------------------
#--------------------------------------------------------------------------------------

DEPART_NAME="$1"
VOORNAAM=""
ROOT_DIR=""

#--------------------------------------------------------------------------------------
#--------------------------------------- END ------------------------------------------
#--------------------------------------------------------------------------------------


#Check of user voldoende privileges heeft
if [ $(id -u) -ne 0 ]; then 
    echo "Please run this script as root or using sudo!"
    echo "Press enter to continue..."
    read
  exit 1
fi

#Maak terminal leeg
clear

#Check argument, als er geen arugument is, exit code 1
if [ -z "$DEPART_NAME" ]; then
    echo "Error, geen afdelingsnaam gevonden. Gebruik het script als volgt :"
    echo "./script.sh <afdelingsnaam>"
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
    echo "Afdelingsnaam is $DEPART_NAME"

:'    
    


#Maak een directory met de naam van de variabele "naam" in de root directory
$ROOT_DIR= "/$VOORNAAM"
mkdir /$VOORNAAM
echo "Hoofddirectory $ROOT_DIR is aangemaakt."

#Maak binnen de nieuwe directory twee nieuwe subdirectories
mkdir -p $ROOT_DIR/$DEPART_NAME-docs
mkdir -p $ROOT_DIR/$DEPART_NAME-rodocs
echo "Subdirectories $DEPART_NAME-docs en $DEPART_NAME-rodocs zijn aangemaakt in $ROOT_DIR."

#Vervang de lijn met "GID_MIN" in het bestand /etc/login.defs door "GID_MIN 3000"
cp /etc/login.defs /etc/login.defs.bak  # Maak een back-up
sed -i 's/^GID_MIN.*/GID_MIN 3000/' /etc/login.defs
echo "GID_MIN is vervangen door 3000 in /etc/login.defs."

#Maak een nieuwe groep met de naam <argument>-verkoop
GROUP_NAME="$DEPART_NAME-verkoop"
groupadd $GROUP_NAME
echo "Groep $GROUP_NAME is aangemaakt."

#Echo de gid en de naam van de nieuwe groep
GID=$(getent group $GROUP_NAME | cut -d: -f3)
echo "GID van de groep $GROUP_NAME is $GID."

# set UID_MIN 2500
cp /etc/login.defs /etc/login.defs.bak  # Maak een back-up
sed -i 's/^UID_MIN.*/UID_MIN 2500/' /etc/login.defs
# make 2 users 
USER1="${1}-user1"
USER2="${1}-user2"
useradd -m -g $GROUP_NAME -s /bin/bash $USER1
useradd -m -g $GROUP_NAME -s /bin/bash $USER2

echo "Stel een wachtwoord in voor $USER1:"
passwd $USER1
chage -d 0 -M 40 $USER1

echo "Stel een wachtwoord in voor $USER2:"
passwd $USER2
chage -d 0 -M 40 $USER2

echo "Gebruikers $USER1 en $USER2 zijn aangemaakt en zijn leden van $GROUP_NAME."

#Maak 1 admin user
ADMIN="${1}-admin"
useradd -m -g $GROUP_NAME -s /bin/sh $ADMIN

echo "Stel een wachtwoord in voor $ADMIN:"
passwd $ADMIN
chage -d 0 -M 40 $ADMIN

echo "Admin gebruiker $ADMIN is aangemaakt en is lid van $GROUP_NAME."

echo "Script voltooid."
