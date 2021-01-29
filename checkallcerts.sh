#!/bin/bash
source config.txt



#WYBOR SCIEZKI LOKALNYCH CERTYFIKATOW
directory=$loc_dir
if [ -z "$directory" ]
	then directory=$(zenity --file-selection --title="Prosze wybrac sciezke certyfikatow" --file-filter="Desktop" --directory)
fi
cd "$directory"

#DECYZJA O WYSYLANIU POWIADOMIENIA NA MAIL
zenity --question --text "Czy chcesz aby wyslac liste wygasajacych certyfikatow na adres e-mail?"
ifemail=$?

#POBRANIE DOMYSLNEGO MAILA LUB PODANIE WLASNEGO
email=$def_mail
if [ "$ifemail" -eq "0" ]
 	then
	if [ -z "$def_mail" ]
		then
			email=$(zenity --entry --text "Prosze podac adres email dla powiadomienia")
	 		printf "\nWybrany email to: $ifemail\n"
	fi		
fi

#DECYZJA O POWIADOMIENIACH SYSTEMOWYCH
zenity --question --text "Czy chcesz ustawic powiadomienia systemowe o wygasajacych certyfikatach?"
ifnotify=$?

#POBIERANIE LISTY USLUG WWW DO POBRANIA CERTYFIKATOW
websites=$conf_websites
IFS=' ' read -r -a websites_arr <<< "$websites"
printf "Lista uslug WWW do sprawdzenia: \n"
printf '%s\n' "${websites_arr[@]}"

#STWORZENIE KATALOGU NA ZDALNE CERTYFIKATY I PRZEJSCIE DO NIEGO
seconds_now=$(date +"%s")
wwwdirname="RemoteCerts$seconds_now"
mkdir "$wwwdirname"
cd "$wwwdirname"

#POBRANIE NUMERU PORTU Z KONFIGURACJi
port=$conf_port

#POBIERANIE ZDALNYCH CERTYFIKATOW
for www in "${websites_arr[@]}"
	do
		echo | openssl s_client -servername $www -connect $www:$port | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $www.crt
done

#ZDEFINIOWANIE POTENCJALNEJ WIADOMOSCI EMAIL
message="\nLista certyfikatow: \n"
printf "$message"

#ZAMIANA CZASU POWIADOMIEN Z KONFIGURACJI NA DNI
day=86400
rem1= expr $conf_1st_rem / $day
rem2= expr $conf_2nd_rem / $day

#SPRAWDZANIE CERTYFIKATOW ZDALNYCH POD KATEM WAZNOSCI
for x in *.crt ; do
	data=$(openssl x509 -enddate -noout -in ${x} | cut -d'=' -f2-)
	printf "Data wygasniecia certyfikatu $x to: $data"
	orig="$data"
	epoch=$(date -d "${orig}" +"%s")
	expiring="$(($epoch-$(date +%s)))"
	
	printf "\nDaty:\n"
	printf "original = $orig\n"
	printf "epoch conv = $epoch\n"
	printf "expiring = $expiring\n"
	
	if [ $expiring -gt 86400 -a $expiring -lt $conf_1st_rem ]
		then
		zenity --info --width 300 --text "Ten certyfikat wygasa za mniej niz $rem1 dni.\nData wygasniecia certyfikatu $x to: $data\n"
		message="$message\nTen certyfikat wygasa za mniej niz $rem1 dni - $x (Data: $data)\n"	
		if [ "$ifnotify" -eq "0" ]
			then printf 'notify-send' "Certyfikat $x wygasa za $rem1 dni." | at $data
			echo "Utworzono przypomnienie na $data"
		fi	
	fi
	
	if [ $expiring -gt 0 -a $expiring -lt $conf_2nd_rem ]
		then
		zenity --warning --width 300 --text "Uwaga, ten certyfikat wygasa za mniej niz $rem2 dni.\nData wygasniecia certyfikatu $x to:\n $data\n"
		message="$message\nTen certyfikat wygasa za mniej niz $rem2 dni - $x (Data: $data)\n"
		if [ "$ifnotify" -eq "0" ]
			then echo 'notify-send' "Certyfikat $x wygasa za $rem2 dni" | at $data
			printf "Utworzono przypomnienie na $data"
		fi	
	fi
	
	if [ $expiring -lt 0 ]
		then
		zenity --warning --width 300 --text "UWAGA: Ten certyfikat wygasl.\nData wygasniecia certyfikatu $x to: $data\n"
		message="$message\nUWAGA: Ten certyfikat wygasl - $x (Data: $data)\n\n"	
	fi
	printf "\n"

done



#POWROT DO FOLDERU SKRYPTU
cd ..



#SPRAWDZENIE CERTYFIKATOW LOKALNYCH W FOLDERZE POD KATEM WAZNOSCI
for x in *.crt ; do
	data=$(openssl x509 -enddate -noout -in ${x} | cut -d'=' -f2-)
	printf "Data wygasniecia certyfikatu $x to: $data"
	orig="$data"
	epoch=$(date -d "${orig}" +"%s")
	expiring="$(($epoch-$(date +%s)))"
	
	printf "\nDaty:\n"
	printf "original = $orig\n"
	printf "epoch conv = $epoch\n"
	printf "expiring = $expiring\n"
	
	if [ $expiring -gt 86400 -a $expiring -lt $conf_1st_rem ]
		then
		zenity --info --width 300 --text "Ten certyfikat wygasa za mniej niz $rem1 dni.\nData wygasniecia certyfikatu $x to: $data\n"
		message="$message\nTen certyfikat wygasa za mniej niz $rem1 dni - $x (Data: $data)\n"	
		if [ "$ifnotify" -eq "0" ]
			then printf 'notify-send' "Certyfikat $x wygasa za $rem1 dni." | at $data
			echo "Utworzono przypomnienie na $data"
		fi	
	fi
	
	if [ $expiring -gt 0 -a $expiring -lt $conf_2nd_rem ]
		then
		zenity --warning --width 300 --text "Uwaga, ten certyfikat wygasa za mniej niz $rem2 dni.\nData wygasniecia certyfikatu $x to:\n $data\n"
		message="$message\nTen certyfikat wygasa za mniej niz $rem2 dni - $x (Data: $data)\n"
		if [ "$ifnotify" -eq "0" ]
			then echo 'notify-send' "Certyfikat $x wygasa za $rem2 dni" | at $data
			printf "Utworzono przypomnienie na $data"
		fi	
	fi
	
	if [ $expiring -lt 0 ]
		then
		zenity --warning --width 300 --text "UWAGA: Ten certyfikat wygasl.\nData wygasniecia certyfikatu $x to: $data\n"
		message="$message\nUWAGA: Ten certyfikat wygasl - $x (Data: $data)\n\n"	
	fi
	printf "\n"

done

#WYSWIETLENIE I WYSLANIE WIADOMOSCI EMAIL Z CERTYFIKATAMI
printf "$message"
currentdate=$(date)
printf "$email"
echo "$message" | mail -s "CertsFriendlyReminder $currentdate" $email


