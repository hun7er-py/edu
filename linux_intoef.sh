#!/bin/bash

#--------------------------------------------------------------------------------------
#--------------- GLOBAL VARIABLES DECLARATION + INITIALISATION ------------------------
#--------------------------------------------------------------------------------------

DEPART_NAME="$1"
VOORNAAM="Maxim"
ROOT_DIR=""
RO_DIR=""
RW_DIR=""
LOGFILE="$PWD/maxim-log.txt"

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

echo "Welkom bij maxim-maakafdeling. Logbestand : $LOGFILE"
touch $LOGFILE
chmod 770 $LOGFILE

#controleer alternatief : 

#  while [[ -z $DEPART_NAME ]]; do
#       echo "Error, geen afdelingsnaam gevonden. Gelieve een naam in te geven :"
#       read DEPART_NAME
#   done

#   DEPART_NAME=$1
#   echo "Afdelingsnaam is $DEPART_NAME"

  

#==================|| Maak een directory in de root directory ||===========================

ROOT_DIR= "/$VOORNAAM"
echo "$(date -u) : Attempting to make folder $ROOT_DIR" >> $LOGFILE
mkdir /$VOORNAAM
echo "Hoofddirectory $ROOT_DIR is aangemaakt."
echo "$(date -u) : Succesfully created $ROOT_DIR"  >> $LOGFILE

#=============|| Maak binnen de nieuwe directory twee nieuwe subdirectories ||=============
RW_DIR="$ROOT_DIR/$DEPART_NAME-docs"
RO_DIR="$ROOT_DIR/$DEPART_NAME-rodocs"

echo "$(date -u) : attempting to make folder $RW_DIR"  >> $LOGFILE
mkdir -p $RW_DIR
echo "$(date -u) : Succesfully created $RW_DIR"  >> $LOGFILE
echo "$(date -u) : attempting to make folder $RO_DIR"  >> $LOGFILE
mkdir -p $RO_DIR
echo "$(date -u) : Succesfully created $RO_DIR"  >> $LOGFILE
echo "Subdirectories $RW_DIR en $RO_DIR zijn aangemaakt"

#==|| Vervang de lijn met "GID_MIN" in het bestand /etc/login.defs door "GID_MIN 3000" ||==
echo "$(date -u) : Backing up /etc/login.defs --> /etc/login.defs.bak"  >> $LOGFILE
cp /etc/login.defs /etc/login.defs.bak  # Maak een back-up
echo "$(date -u) : Backup succesfully created. Backup file : /etc/login.defs.bak"  >> $LOGFILE
echo "$(date -u) : Attempting changing GID_MIN to 3000"  >> $LOGFILE
sed -i 's/^GID_MIN.*/GID_MIN 3000/' /etc/login.defs
echo "$(date -u) : Successfully changed GID_MIN to 3000"  >> $LOGFILE

#===========|| Maak een nieuwe groep met de naam <argument>-verkoop ||=====================
GROUP_NAME="$DEPART_NAME-verkoop"
echo "$(date -u) : Attempting to create group $GROUP_NAME"  >> $LOGFILE
groupadd $GROUP_NAME
echo "Groep $GROUP_NAME is aangemaakt."
GID=$(getent group $GROUP_NAME | cut -d: -f3)
echo "GID van de groep $GROUP_NAME is $GID." #verbose confirmation of GID
echo "$(date -u) : Succesfully created group $GROUP_NAME with GID : $GID"  >> $LOGFILE


#============================|| set UID_MIN 2500 ||========================================
echo "$(date -u) : Attempting changing UID_MIN to 2500"  >> $LOGFILE
sed -i 's/^UID_MIN.*/UID_MIN 2500/' /etc/login.defs #zoek de lijn met UID_MIN en vervang deze met UID_MIN 2500.
echo "$(date -u) : Successfully changed UID_MIN to 2500"  >> $LOGFILE

#===================|| Maak 2 users en stel wachtwoorden in  ||============================
USER1="$DEPART_NAME-user1"
USER2="$DEPART_NAME-user2"
echo "$(date -u) : Attempting to add $USER1"  >> $LOGFILE
useradd -m -g $GROUP_NAME -s /bin/bash $USER1   #-m flag creates homedir if it doesnt exist, -g flag sets users inital login group
echo "$(date -u) : Successfully added $USER1 : $GROUP_NAME with bash shell"  >> $LOGFILE
echo "$(date -u) : Attempting to add $USER2"  >> $LOGFILE
useradd -m -g $GROUP_NAME -s /bin/bash $USER2   #-s flag sets the default shell for this user
echo "$(date -u) : Successfully added $USER2 : $GROUP_NAME with bash shell"  >> $LOGFILE

echo "$(date -u) : Attempting to set password for $USER1"  >> $LOGFILE
echo "Stel een wachtwoord in voor $USER1:"
passwd $USER1                               #will prompt user for password input
echo "$(date -u) : Succesfully set password for $USER1"  >> $LOGFILE
echo "$(date -u) : Attempting to set password expiration for $USER1"  >> $LOGFILE
chage -d 0 -M 40 $USER1                     #chage -d --> set to 0 so the system sees the password as expired and will promt user to change it on first login
                                            #chage -m --> mindays, minimum amount of days to change
echo "$(date -u) : Succesfully set password expiration for $USER1"  >> $LOGFILE

echo "$(date -u) : Attempting to set password for $USER2"  >> $LOGFILE
echo "Stel een wachtwoord in voor $USER2:"
passwd $USER2
echo "$(date -u) : Succesfully set password for $USER2"  >> $LOGFILE
echo "$(date -u) : Attempting to set password expiration for $USER2"  >> $LOGFILE
chage -d 0 -M 40 $USER2
echo "$(date -u) : Succesfully set password expiration for $USER2"  >> $LOGFILE
echo "Gebruikers $USER1 en $USER2 zijn aangemaakt en zijn leden van $GROUP_NAME."

#======================|| Maak 1 admin user ||=============================================
ADMIN="$DEPART_NAME-admin"
echo "$(date -u) : Attempting to create $ADMIN "  >> $LOGFILE
useradd -m -g $GROUP_NAME -s /bin/sh $ADMIN
echo "$(date -u) : Succesfully added $USER2"  >> $LOGFILE
echo "$(date -u) : Attempting to set password for $ADMIN"  >> $LOGFILE
echo "Stel een wachtwoord in voor $ADMIN:"
passwd $ADMIN
echo "$(date -u) : Succesfully set password for $ADMIN"  >> $LOGFILE
echo "$(date -u) : Attempting to set password expiration for $ADMIN"  >> $LOGFILE
chage -d 0 -M 40 $ADMIN
echo "$(date -u) : Succesfully set password expiration for $ADMIN"  >> $LOGFILE
echo "Admin gebruiker $ADMIN is aangemaakt en is lid van $GROUP_NAME."

#====================|| Verander ownership en rechten op de folders ||=====================
echo "$(date -u) : Attempting to change owernship and permissions on $RW_DIR"  >> $LOGFILE
chown $ADMIN:$GROUP $RW_DIR                 #changeowner 
chmod 775 $RW_DIR                           # admin: rwx, group: rwx, others: r-x -  is directory dus moet uitvoerbaar zijn
chmod +t $RW_DIR                            # Sticky bit op RWdocs
echo "$(date -u) : Succesfully changed owernship and permissions on $RW_DIR"  >> $LOGFILE
echo "$(date -u) : Attempting to change owernship and permissions on $R0_DIR"  >> $LOGFILE
chown $ADMIN:$GROUP $RO_DIR
chmod 750 $RO_DIR                           # admin: rwx, group: r--, others: ---    is directory dus moet uitvoerbaar zijn
chmod +t $RO_DIR                            # Sticky bit op ROdocs
echo "$(date -u) : Succesfully changed owernship and permissions on $R0_DIR"  >> $LOGFILE

#==========================|| Maak folder en demodoc ||====================================
echo "$(date -u) : Attempting to create demofolder and file"  >> $LOGFILE
mkdir $ROOT_DIR/$VOORNAAM
echo "$(date -u) : Succesfully created $ROOT_DIR/$VOORNAAM"  >> $LOGFILE
touch $ROOT_DIR/$VOORNAAM/demodoc.maxim
echo "$(date -u) : Succesfully created $ROOT_DIR/$VOORNAAM/demodoc.maxim"  >> $LOGFILE
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
echo "$(date -u) : Attempting to remove /etc/login.defs"  >> $LOGFILE
rm -f /etc/login.defs                       #force remove
echo "$(date -u) : Succesfully deleted /etc/login.defs"  >> $LOGFILE
echo "$(date -u) : Attempting to put backup as /etc/login.defs"  >> $LOGFILE
mv /etc/login.defs.bak /etc/login.defs      #put backup back in place
echo "$(date -u) : Succesfully put backup as /etc/login.defs"  >> $LOGFILE

echo "$(date -u) : Succesfully executed the script without errors "  >> $LOGFILE

echo "============================================================================"
echo "====================== Script finished without errors ======================"
echo "============================================================================"

# ======= !!!!!!!!!!!!!!!!!!!!  IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!! ==========
# =   Follow these steps to make execute this script :                          =
# =   1) open a terminal and navigate to the folder where the file is located   =
# =   2) type in the following : chmod +x <scriptname.sh>                       =
# =   3) execute the script as follows sudo <scriptname.sh> <departement>       =
# =                                                                             =
# =   A log file will be created                                                =
# ===============================================================================
