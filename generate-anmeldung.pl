#!/usr/bin/perl
use utf8;
use Getopt::Long;

sub geburtsjahroptionen
{
    my ($von, $bis) = @_;
    my $gbjopt;

    for $j ($von..$bis )
    {
	if( $j==1974 )
	{
	    $gbjopt.="\t<option selected value=\"".$j."\">".$j."</option>\n";	}
	else
	{
	    $gbjopt.="\t<option value=\"".$j."\">".$j."</option>\n";
	}
    }
    return $gbjopt;
}

my $jahr = 2016;

my ($sec,$min,$hour,$mday,$mon,$thisyear,$wday,$yday,$isdst) =
                                                localtime(time);
$jahr=$thisyear+1900;


my $berglauf = -1;
my $laufkurs = 0;
my $result = GetOptions ("jahr=i" => \$jahr, # numeric
			 "berglauf:i" =>\$berglauf,
			 "laufkurs:i" =>\$laufkurs,
			 "dbuser=s" => \$dbuser,
			 "dbpasswd=s" => \$dbpasswd,
			 "dbname=s" => \$dbname);


print "Jahr ".$jahr."\n";

$gbjopt=geburtsjahroptionen($jahr-102, $jahr-2);

sub instantiate_templates
{
    my ($infile, $outfile) = @_;
    open(TEMPLATE,"<".$infile) || die("can't open file: $!");
    open(RESULTS,">".$outfile) || die("can't open file: $!");

    $n=$jahr-2008;
    if($berglauf!=-1)
    {
	$titel=$n.". Altenberger Berglauf";
	$startadresscmt="  /*\n";
	$endadresscmt="  */\n";
    }
    else
    {
	$titel="Laufkurs $jahr";
    }
    while(<TEMPLATE>)
    {
	s/VERANSTALTUNGSTITEL/$titel/g;
	s/ERSETZEJAHR/$jahr/g;
       	s/ERSETZEN/$n/g;
	s/ERSETZEGBJOPR/$gbjopt/g;
	s/ERSETZEDBNAME/$dbname/g;
	s/ERSETZEDBUSER/$dbuser/g;
	s/ERSETZEDBPASSWD/$dbpasswd/g;
	s/ADRESSESTART/$startadresscmt/g;
	s/ADRESSEENDE/$endadresscmt/g;
	print RESULTS;
    }
    close TEMPLATE;
    close RESULTS;
}

my $mandatorycolumns=" NOT NULL";
if($berglauf!=-1)
{
    $mandatorycolumn="";   
    print "Erzeuge Berglauf-Anmeldeseite...\n";
    instantiate_templates("berglauf-index.html.tmpl", "anmeldung.html");
    instantiate_templates("ergebnisse.php.tmpl","ergebnisse.php");
    instantiate_templates("teilnehmer.php.tmpl","teilnehmer.php");
    instantiate_templates("urkunden/urkunde.php.tmpl","urkunden/urkunde.php");
}
else
{
    print "Erzeuge Laufkurs-Anmeldeseite...\n";
    instantiate_templates("laufkurs-index.html.tmpl", "index.html");
}

instantiate_templates("meld.php.tmpl","meld.php");
instantiate_templates("adm/sortierteliste.php.tmpl","adm/sortierteliste.php");
instantiate_templates("adm/csvdownload.php.tmpl","adm/csvdownload.php");
instantiate_templates("lib/laufab.php.tmpl","lib/laufab.php");


print "Erzeuge initdb-$dbname.sql\n";
open(INITDB,">initdb-".$dbname.".sql") || die("can't open file: $!");
print INITDB "create database $dbname CHARACTER SET utf8;\n";
print INITDB "create table $dbname.meldenummern
       (
        meldeid INT AUTO_INCREMENT PRIMARY KEY
       ) ENGINE=INNODB;

create table $dbname.teilnehmer
       (
        meldeid INT,
        vorname TINYTEXT NOT NULL,
        nachname TINYTEXT NOT NULL,
        plz int NOT NULL,
        ort TINYTEXT $mandatorycolumn,
        strasse TINYTEXT $mandatorycolumn,
        hausnr TINYTEXT $mandatorycolumns,
        geburtsjahr YEAR(4) NOT NULL,
        geschlecht ENUM('m','w') CHARACTER SET utf8 NOT NULL,
        telefon TINYTEXT $mandatorycolumn,
        verein TEXT,
        email VARCHAR(255) CHARACTER SET utf8,
        tus BOOL NOT NULL,
        schnellsteraltenberger BOOL NOT NULL,
        meldezeitpunkt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        altersklasse CHAR(10),
        geloescht BOOL NOT NULL,
        INDEX meldeid_idx (meldeid),
        FOREIGN KEY (meldeid) REFERENCES $dbname.meldenummern(meldeid) ON DELETE CASCADE
        ) ENGINE=INNODB;

create table $dbname.teilnahme
       (
        meldeid INT,
        laufnummer INT,
        INDEX meldeid_idx (meldeid),
        FOREIGN KEY (meldeid) REFERENCES $dbname.meldenummern(meldeid) ON DELETE CASCADE
        ) ENGINE=INNODB;


create table $dbname.startnummern
       (
        meldeid INT,
        startnummer INT,
        INDEX meldeid_idx (meldeid),
        FOREIGN KEY (meldeid) REFERENCES $dbname.meldenummern(meldeid) ON DELETE CASCADE
        ) ENGINE=INNODB;

# Alle Veranstaltungen
create table $dbname.laeufe
       (
        laufnummer INT PRIMARY KEY,
        titel TINYTEXT NOT NULL,
        kuerzel TINYTEXT NOT NULL,
        startgeld FLOAT NOT NULL
        ) ENGINE=INNODB;


create table $dbname.zeiten
       (
        meldeid INT, 
        laufnummer INT,
        zeit TIME,

        CONSTRAINT pk_Zeiten PRIMARY KEY (meldeid, laufnummer),
        INDEX meldeid_idx (meldeid),
        FOREIGN KEY (meldeid) REFERENCES $dbname.meldenummern(meldeid) ON DELETE CASCADE,
        INDEX laufnr_idx (laufnummer),
        FOREIGN KEY (laufnummer) REFERENCES $dbname.laeufe(laufnummer) ON DELETE CASCADE
        ) ENGINE=INNODB;

create table $dbname.orgamail
       (
         email VARCHAR(255) CHARACTER SET utf8
       );

/*
GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON $dbname.* TO '$dbuser';

CREATE FUNCTION $dbname.altersklasse( geburtsjahr YEAR(4), geschlecht ENUM('m','w') )
RETURNS CHAR(10) DETERMINISTIC
RETURN CONCAT(UPPER(geschlecht), CASE 
  WHEN $jahr-geburtsjahr<8 THEN 'KU8'
  WHEN $jahr-geburtsjahr<10 THEN 'KU10'
  WHEN $jahr-geburtsjahr<12 THEN 'KU12'
  WHEN $jahr-geburtsjahr<14 THEN 'JU14'
  WHEN $jahr-geburtsjahr<16 THEN 'JU16'
  WHEN $jahr-geburtsjahr<18 THEN 'JU18'
  WHEN $jahr-geburtsjahr<20 THEN 'JU20'
  WHEN $jahr-geburtsjahr<23 THEN 'U23'
  WHEN $jahr-geburtsjahr>=85 THEN '85'
  WHEN $jahr-geburtsjahr>=80 THEN '80'
  WHEN $jahr-geburtsjahr>=75 THEN '75'
  WHEN $jahr-geburtsjahr>=70 THEN '60'
  WHEN $jahr-geburtsjahr>=65 THEN '55'
  WHEN $jahr-geburtsjahr>=60 THEN '60'
  WHEN $jahr-geburtsjahr>=55 THEN '55'
  WHEN $jahr-geburtsjahr>=50 THEN '50'
  WHEN $jahr-geburtsjahr>=45 THEN '45'
  WHEN $jahr-geburtsjahr>=40 THEN '40'
  WHEN $jahr-geburtsjahr>=35 THEN '35'
  WHEN $jahr-geburtsjahr>=30 THEN '30'
  ELSE ''
  END );
*/

insert into $dbname.laeufe VALUE (0, 'Bambini U6 665m', 'Bambini', 0);
insert into $dbname.laeufe VALUE (1, 'Kinder U10 1,3km', 'Kinder U10', 2);
insert into $dbname.laeufe VALUE (2, 'Kinder U14 2,0km', 'Kinder U14', 2);
insert into $dbname.laeufe VALUE (3, '5,0km ab 14J', '5km', 4);
insert into $dbname.laeufe VALUE (4, '10,0km ab 14J', '10km', 6);
insert into $dbname.laeufe VALUE (5, 'Nordic Walking 5km', 'NW 5km', 4);
insert into $dbname.laeufe VALUE (6, 'Anfängerlaufkurs', 'Laufkurs', 20);

insert into $dbname.orgamail VALUE ('mkatzer@gmx.de');
insert into $dbname.orgamail VALUE ('wurm@gmxxx.de');


GRANT INSERT,UPDATE on $dbname.teilnehmer to '$dbuser';
GRANT INSERT on $dbname.teilnahme to '$dbuser';
GRANT SELECT,INSERT on $dbname.meldenummern to '$dbuser';

GRANT SELECT on $dbname.teilnehmer to '$dbuser';
GRANT SELECT on $dbname.teilnahme to '$dbuser';
GRANT SELECT on $dbname.meldenummern to '$dbuser';
GRANT SELECT,INSERT on $dbname.zeiten to '$dbuser';
GRANT SELECT on $dbname.laeufe to '$dbuser';
GRANT CREATE TEMPORARY TABLES on $dbname.* to '$dbuser';
GRANT SELECT,INSERT on $dbname.* to '$dbuser';
GRANT SELECT,INSERT on $dbname.orgamail to '$dbuser';
";


#print INITDB "";
close INITDB;

# Zufallsdaten erzeugen
open(FILLDB,">filldb-".$dbname.".sql") || die("can't open file: $!");

@nachnamen = ( "Wachsmann", "Klose", "B&ouml;dding", "Grabowski", "Varavir", "Herding", "Geuker", "Leutermann",
"Kveak","Viefhues","Lembeck","Friedrich","Bohl", "Schleuter","Rockmann","Pabst","Wenning-K&uuml;nne","Schult",
"&Ouml;zt&uuml;rk","Horstmann","Baumeister","Overkamp","Roters","Hoffmeister","Lenzen","Hamsen","Schramm","Haman",
"Timmermann","Grahl","Toebe","Pferdehirt","Herbert","Treuenfels","Sommer","Diepenbrock",
"Grond","Laubrock","Lueg","Huke","Hettwei","Kr&uuml;ger","Brinkmann","Reef","Reinke","M&uuml;ller","M&ouml;llemann");

@vornamen = ("Heinz", "Emil", "Josef", "Maria", "Chantal", "Kurt", "Karin", "Leonie", "Dietmar","Ahmed",
	     "Markus","Renate","Laura","Robert","Anke","Wolfgang","Anton","Lisa", "Werner", "Jochen",
    "Hilmar", "Elisa");

@orte = ("Altenberge", "Nordwalde","Osnabr&uuml;ck", "Tirana", "Dublin", "Wien", "Ottensen", "Bad Oldesloe",
	 "Steinfurt","Holthausen","Coesfeld","Waltrup", "Kr&uuml;sel");

@vereine = ("TuS Altenberge", "LSF M&uuml;nster", "Bergziegen", "FC Nordwalde");

for( $z=0; $z<127; ++$z )
{
    $nachname = @nachnamen[ rand @nachnamen ];
    $vorname = @vornamen[ rand @vornamen ];


    $plz = int rand 99999;
    $ort = @orte[ rand @orte ];

    $strasse = "Keine Strasse";
    $hausnr = 0;

    $geburtsjahr = $jahr-2-int(rand 90);

    if( rand 1 >= 0.5 )
    {
	$geschlecht = "w";
    }
    else
    {
	$geschlecht = "m";
    }
    $telefon = int(rand 999999);
    $verein = @vereine[ rand @vereine ];

    $email = "info@tus-altenberge.de";

    #print $nachname."\n\n";

    $tus=int(rand(2));
    $schnellster=int(rand(2));
    $meldeid=$z+2;
    print FILLDB "insert into meldenummern values ($meldeid);\n";
    print FILLDB "INSERT INTO $dbname.teilnehmer(meldeid,vorname, nachname, plz, ort, strasse, hausnr, geburtsjahr, geschlecht, telefon, verein, email, tus, schnellsteraltenberger) VALUES ( $meldeid, '$vorname', '$nachname', $plz, '$ort', '$strasse', $hausnr, $geburtsjahr, '$geschlecht', $telefon, '$verein', '$email', $tus, $schnellster);\n";

    print FILLDB "UPDATE teilnehmer SET altersklasse = $dbname.altersklasse($geburtsjahr, '$geschlecht') WHERE meldeid = $meldeid;";

    $dj=2016;
    if( $geburtsjahr >= $dj-6 )
    {
	$laufnummer = 0;
	$zeit = rand 5*60;
    }
    elsif ($geburtsjahr >= $dj-10 )
    {
	$laufnummer = 1;
	$zeit = rand 6*60;
    }
    elsif ($geburtsjahr >= $dj-14 )
    {
	$laufnummer = 2;
	$zeit = rand 10*60;
    }
    else 
    {
	$laufnummer = 3+int(rand(2));
	$zeit = (rand 6*60)*($laufnummer-2)*5;
    }

    $zeitH=int($zeit/3600);
    $zeitM=int(($zeit-$zeitH*3600)/60);
    $zeitS=int($zeit-$zeitH*3600-$zeitM*60);
    
    print FILLDB "INSERT INTO $dbname.teilnahme(meldeid, laufnummer) VALUES ( $meldeid, $laufnummer );\n";
	
    print FILLDB "INSERT INTO $dbname.zeiten(meldeid, laufnummer, zeit) VALUES ( $meldeid, $laufnummer,\'$zeitH:$zeitM:$zeitS\' );\n";

}
close FILLDB;
