#!/bin/bash

#Fonction qui indique erreurs de syntaxes et affiches les bonne pratique
afficheErreurs()
{
	echo "Voici la syntaxe du script :"
	echo " "
	echo "----------------------------------------------"
	echo " "
	echo "./TrouveTonIP.sh (@adresse serveur DNS) (Adresse réseau) (Masque) [Nombre d'adresse voulue]"
	echo " "
	echo "----------------------------------------------"
	echo " "
	echo "--> (@adresse serveur DNS) : Paramètre obligatoire qui permet d'indiquer quel serveur DNS. La présence d'un '@' avant l'adresse est obligatoire ex : @10.10.10.10."
	echo "--> (Adresse réseau) : paramètre obligatoire exemple : 10.10.0.0."
	echo "--> (Masque) : paramètre obligatoire, valeur numérique entre 1 et 31."
	echo "--> [Nombre d'adresses voulues] : Paramètre optionel, si il n'est pas utilisé le script affichera par défaut 1 seule adresse. Ce nombre ne peut pas excéder le nombre d'adresse disponible dans le réseau déclaré."
	echo " "
	echo "----------------------------------------------"
	echo " "
	echo "Voici un exemple sans déterminer le nombre d'adresses voulues : ./TrouveTonIp.sh @10.10.10.10 10.100.0.0 16"
	echo " "
	echo "Voici un autre exemple en déterminant le nombre d'adresses voulue à 5 : ./TrouveTonIp.sh @10.10.10.10 10.100.0.0 16 5"
	echo " "
	echo "---------------------------------------------"
	exit
}

#Nombre de paramètres
nb_parametres="$#"

#Adresse du serveur DNS rentrée par l'utilisateur
serveur="$1"

#Réseau rentré en paramètre par l'utilisateur
reseau="$2"

#Masque rentré en parametre par l'utlisateur
masque="$3"

if [ $nb_parametres -eq 4 ]
then
	compteur="$4"
else
	compteur=1
fi

#Je traite les erreurs : Trop ou pas assez de paramètres, masque supérieur à 31 inférieur à 1, en cas d'oubli de '@' pour le serveur DNS
if [ $nb_parametres -lt 3 ] || [ $nb_parametres -gt 4 ] || [ $masque -gt 31 ] || [ $masque -lt 1 ] || [ `echo "$serveur" | grep "^[^@]*$"` ]
then

	afficheErreurs

fi


#Réseau fragmenté en 4, exemple : IP1.IP2.IP3.IP4 1.2.3.4 avec IP1=1, IP2=2, IP3=3, IP4=4
IP1=$(echo "$reseau" | cut -f1 -d'.')
IP2=$(echo "$reseau" | cut -f2 -d'.')
IP3=$(echo "$reseau" | cut -f3 -d'.')
IP4=$(echo "$reseau" | cut -f4 -d'.')

#Je traite les erreurs de frappes sur les adresses IP : Chaque valeur doit être entre 1 et 254
if [ $IP1 -lt 1 ] || [ $IP1 -gt 254 ] || [ $IP2 -lt 0 ] || [ $IP2 -gt 254 ] || [ $IP3 -lt 0 ] || [ $IP3 -gt 254 ] || [ $IP4 -lt 0 ] || [ $IP4 -gt 254 ]
then

	afficheErreurs

fi

#Nombre max d'adresses IP dans le réseau et masque indiqué par l'utilisateur
nb_addr_ip_max=$((2**(32-$masque)))

#Test si il y a trop d'adresses demandés pour le nombre d'adresses possibles dans le réseau
if [ $nb_addr_ip_max -lt $compteur ]
then

	echo "Erreur : Veuillez chercher moins d'adresses ou changer de réseau et masque"
	exit

fi

#Initialisation de i
i=0
#Pour toutes les adresses disponibles on fait le test
while [[ $i -lt $nb_addr_ip_max ]]
do

	i=$(($i+1))
    
    #Condition pour empecher le test IP1.IP2.IP3.255
	if [ $IP4 = "254" ]
	then

		IP4="1"
		IP3=$(($IP3+1))
        
        #Condition pour empecher le test IP1.IP2.255.IP4
		if [ $IP3 = "255" ]			
		then

			IP3=0
			IP2=$(($IP29+1))
            
            #Condition pour empecher le test IP1.255.IP3.IP4
			if [ $IP2 = "255" ]		
			then

				IP2=0
				IP1=$(($IP1+1))

			fi

		fi

	fi

	IP4=$(($IP4+1))

	#Variable utilisée pour tester toutes les IPs afin d'en trouver une disponible
	IPtest="$IP1.$IP2.$IP3.$IP4"


	#Commande de résolution DNS pour le serveur $serveur pour l'ip $IPtest, -x resolution reverse, +short juste le résultat
	cmd=$(dig +short $serveur -x $IPtest)
    
    #Test si adresse dispo
	if [ -z $cmd ]	
	then
    
        #Condition pour s'assurer que $compteur IP disponible soit retourné
		if [[ $compteur = 0 ]]
		then

			exit

		fi
        #si dispo
		echo "L'adresse $IPtest est disponible\n"
		compteur=$(($compteur-1))
	fi

done

#Si pas d'adresse trouvée
echo "Aucune adresse n'est disponible pour ces paramètres"
