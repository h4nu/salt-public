**ict4tn022-3010**	

Excercises in course:
[h1](https://hanu.org/ict4tn022-3010/h1_hello_master-slave.html) 
[h2](https://hanu.org/ict4tn022-3010/h2_package_file-server.html)
[h3](https://hanu.org/ict4tn022-3010/h3-versionhallinta.html)
[h4](https://hanu.org/ict4tn022-3010/h4-templates.html)
h5
h6

**h4 templates**



Templates. Making a file from a template 
Tiedoston tekeminen orjalle muotista. 
SLS-tilan tekeminen muotista. 
Making SLS state from template. 
Templating SLS modules

Jinja. for-in-endfor. {% for terosVariable in [‘foo’, ‘bar’] %}. {{ terosVariable }}. Apache Name Based Virtual Hosting.

Muotit. Tiedoston tekeminen orjalle muotista. SLS-tilan tekeminen muotista. Jinja. for-in-endfor. {% for terosVariable in [‘foo’, ‘bar’] %}. {{ terosVariable }}. Apache Name Based Virtual Hosting.

b) Modulikimara. Asenna 6 saltin tilaa/modulia. Tässä siis yksi tila/moduli on esimerkiksi Apachen asennus package-file-service rakenteella. Tiloista/moduleista enintään neljä voi olla muiden tekemiä, esimerkiksi verkosta löytyneitä. Muista lähdeviitteet ja lisenssit. Käytä tiloja, joita et ole aiemmin käyttänyt ja joita ei ole käsitelty tunnilla. Tilojen tulee tehdä muutakin kuin pelkästään asentaa yksittäinen paketti, esimerkiksi tehdä sille asetuksia (siis vaikka package-file, ei pelkkä package). Asennettavat ja konfiguroitavat ohjelmat voivat olla mitä vain valitset: palvelimia, graafisen käyttöliittymän ohjelmia, komentorviohjelmia, vapaita, suljettuja... Muista testata lopputulos käyttämällä ohjelmaa sen pääasiallisessa käyttötarkoituksessa. Jos jäät jumiin, tee kaikki mitä osaat ja dokumentoi ongelmat, niin ratkotaan niitä yhdessä.

tarkasta tiedoston oikeudet komennolla stat -c:
stat -c '%A %a %n' /path/filename

aseta tiedosto-oikeudet käyttäen user, group ja mode arvoja:

  file.managed:
    - source: /path/filename
    - user: root
    - group: root
    - mode: 644