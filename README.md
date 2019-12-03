# Aplikacja do tworzenia rankingów

## Dokumentacja

### Autorzy

Katarzyna Jędrocha
Szymon Bednarek
Michał Baran
Bartłomiej Kalata


### Projektowanie aplikacji
  Za projektowanie aplikacji odpowiedzialni byli wszyscy członkowie zespołu projektowego. Struktura została zaprojektowana tak aby użytkownik po uruchomieniu przeszedł ścieżkę wskazaną w zakładkach i otrzymał gotowy produkt w postaci rankingu. Aplikacja cechuje się:
  
  * Wyborem i wgraniem własnych danych
  * Wyborem metody matematycznej do utworzenia rankingu
  * Edycją danych wprowadzonych do aplikacji w szczególności: 
    - wyborem czy zmienna jest stymulantą czy destymulantą
    - wyborem czy zmienna powinna zostać zawarta w procesie tworzenia rankingu
    - wyborem wag tzn. nadaniu odpowiedniej liczby wagowej dla zmiennej, gdy użytkownik stwierdzi że dana zmienna ma większą istotność niż pozostałe zmienne
  * Wyborem rankingu który ma zostać zapisany do pliku w celu porównania wyników.
  
### Tworzenie struktury
  Za tworzenie struktury aplikacji odpowiedzialni byli Baran Michał oraz Bartłomiej Kalata.
Struktura aplikacji została podzielona na 3 główne części: 
  
  - OPIS
  - DANE
  - RANKING

### OPIS

Sekcja OPIS stworzona została przez Katarzynę Jędrocha.
W sekcji OPIS znajdują się opisy metod użytych do tworzenia rankingów m.in.: 
Metoda HELLWIGA, TOPSIS, SUMY RANG, STANDARYZOWANYCH SUM.
Dzięki tej sekcji Użytkownik zostaje wprowadzony w metody które zostaną użyte do stworzenia rankingów na podstawie jego danych, w taki sposób, aby mógł dobrać najlepiej pasującą do jego zbioru. W każdym z opisów wymienione są wady i zalety metod oraz ich chrakterystyczne cechy.

### DANE

Sekcja DANE podzielona jest na dwie części: 
    
    - część nawigacyjna
    - część główna
    
#### Część główna

  - Przycisk wczytania danych **Browse...** . Po uruchomieniu ukazuje się okno wyboru pliku źródłowego, w którym należy wybrać dane do stworzenia rankingu.
  - Częścią główną tej sekcji jest podgląd danych. Jest to reaktywna tabela ukazująca podgląd wybranych danych "na żywo". Dzięki temu dane ukazują się tylko w taki sposób, w jaki użytkownik wybrał w sekcji nawigacyjnej.

#### Część nawigacyjna

  - Po lewej stronie w sekcji nawigacyjnej znajduje się **Wybór zmiennych**. W sekcji tej można wybrać tylko te zmienne, które według użytkownika najlepiej pasują do stworzenia rankingu według wybranej metody.
  - Kolejną częścią sekcji nawigacyjnej jest **Wybór stymulant**. Stymulanty to te zmienne które w dodatni lub pozytywny sposób wpływają na pozycję danego obiektu w rankingu. To znaczy, im większa jest zmienna uznana przez użytkownika za stymulantę, tym większe są szanse na wyższą pozycję w rankingu danego obiektu. Część ta jest dostosowywana "na żywo". Oznacza to że wybór czy zmienna może być stymulantą, ukaże się dopiero po wyborze tej zmiennej w powyższej sekcji.
  
### RANKING

W sekcji RANKING znajdują się :
 Każdy z rankingów wyświetlany jest w postaci tabeli. Do wyświetlenia wyników został użyty pakiet DT, pozwala on na swobodne manipulowanie wyglądem, wielkością oraz stylem tabeli. Ponadto umożliwia on wyszukiwanie pozycji w tabeli. Każda z tablei przedstawia:
 
 - nazwę obiektu
 - wartość która została obliczona daną metodą
 - pozycję rankingu
 

- 4 metody w nawigacji, gdzie do wyboru jest podgląd rankingu stworzonego przez daną metodę.
- Przycisk zapisu rankingu do pliku.


### Implikacja Obliczeń

Za tworzenie obliczeń i implikowanie ich do aplikacji odpowiedzialni byli Katarzyna Jędrocha oraz Szymon Bednarek.



### Tworzenie GUI

Za tworzenie GUI odpowiedzialni byli, Michał Baran oraz Bartłomiej Kalata.
GUI zostało stworzone w specjalnie przeznaczonym do tego pakiecie R: SHINY. Pozwala on na tworzenie aplikacji reagujących na żywo. GUI zostało podzielone na 3 główne sekcje tak aby użytkownik mógł przejść przez tzw. "ścieżkę", od wyboru danych, poprzez ich edycję, aż do gotowego produktu jakim jest ranking zapisany do pliku. 

### Testy aplikacji

Za testy aplikacji odpowiedzialni byli wszyscy członkowie zespołu.
Pierwszym z przeprowadzonych testów był test użytkowy. Podczas testowania każdego z elemetów wykazano następujące błędy:

- Tablice w sekcji RANKINGI  nie wyświetlały się w prawidłowy sposób.
- Podczas wybrania tylko jednej zmiennej, podgląd danych w sekcji DANE, nie wyświetlał się prawidłowo.

### Dokumentacja

Dokumentacja została wykonana przez 


