## Laufanmeldung ##

<i>This repository contains scripts to create HTML/PHP registration forms for a specific small sports event.</i>

Hier sind Skripte und Vorlagen zum Aufsetzen der Anmeldeseite für Laufkurse und den Berglauf abgelegt.
Die Skripte werden auf der Kommandozeile ausgeführt und benötigen Perl ( nur für die Einrichtung ) und PHP.

Eine neue Anmeldeseite wird mit folgenden Schritten eingerichtet:

1. Eine neue Datenbank auf dem Serversystem anlegen - wie das geht kann je nach Provider verschieden sein.
2. Dieses git-Repository klonieren - am einfachsten gleich auf dem Webserver.
3. HTML- und PHP-Dateien aus den Vorlagen erzeugen.
  Dabei werden der Name der zuvor erzeugten Datenbank und die zugehörigen Zugangsdaten angegeben:
  <pre><code>
  perl ./generate-anmeldung.pl -berglauf -jahr=2016 -dbname=berglauf2016 -dbuser=benutza -dbpasswd="geheimgeheim"
  </code></pre>

Das Skript setzt die Zugangsdaten und die Jahreszahl in die passenden HTML- und PHP-Vorlagen ein. 

4. Verrechtung: der 'adm'-Ordner muss mit Passwort geschützt werden (htpasswd/.htaccess je nach Providervorgabe)

