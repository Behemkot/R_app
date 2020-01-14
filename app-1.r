library(shiny)
library(shinythemes)
library(topsis)
library(clusterSim)
library(DT)
library(psych)

variables <- c()

ui <- fluidPage(theme = shinytheme("cyborg"),
  includeCSS("./style/table.css"),
  titlePanel("Projekt IE"),
  navbarPage("MENU",inverse = T,
    tabPanel("OPIS",
            sidebarPanel(
            selectInput("method","METODA:",choices = c("HELLWIG","TOPSIS","STANDARYZOWANYCH SUM","RANG"))
            ),
            mainPanel(
              textOutput("description") #tu przydzielić opisy metod w zależności od wyboru
            )),
    
    tabPanel("DANE",
             sidebarPanel(
               tabPanel("WYBÓR",
                        checkboxGroupInput("header", "Zmienne:", choices = variables), #w variables mają być nazwy zmiennych, a z headera wybieramy zmienne
                        actionButton("selectall","Zaznacz wszystkie"), 
                        checkboxGroupInput("ch_test", "Wybierz stymulanty", choices = variables),
                        actionButton("selectall2","Zaznacz wszystkie")
                      )
             ),
            mainPanel(
              fileInput(inputId = "file", "Wybierz plik", 
                        accept=c('text/csv','text/comma-separated-values,text/plain','.csv')), #wczytuje dane do "file"
              dataTableOutput("data_view") #tu przydzielić tabelke z danymi po wczytaniu
            )),
    tabPanel("STATYSTYKI",
             mainPanel(
               dataTableOutput("stats") #statystyki opisowe
             )
            ),
   
    tabPanel("RANKING",
             navbarPage("METODA",
              tabPanel("HELLWIG",
                       dataTableOutput("hellwig_rank"),
                       downloadButton("save_h", "Zapisz")
                       ),
              tabPanel("TOPSIS",
                       dataTableOutput("topsis_rank"),
                       downloadButton("save_t", "Zapisz")
                       ),
              tabPanel("STANDARYZOWANYCH SUM",
                       dataTableOutput("stand_rank"),
                       downloadButton("save_s", "Zapisz") 
                       ),
              tabPanel("RANG",
                       dataTableOutput("rank_rank"),
                       downloadButton("save_r", "Zapisz") 
                       )
              ))
 
   ))


Hellwig_func <- function(data, w, ch) {
  data <- data.Normalization(data, normalization = "n1")
  data <- data*w
  wz <- c()
  
  for(i in 1:dim(data)[2]){
    if(identical(ch[i], "+")){
      wz <- c(wz, max(data[,i]))
    }
    else if(identical(ch[i], "-")){
      wz <- c(wz, min(data[,i]))
    }
  }
  
  di0 <- c()
  l = dim(data)[1]
  for(i in 1:l){
    tmp = rbind(data[i,], wz)
    di0[i] = dist(tmp)
  }
  d0 <- mean(di0) + 2*sd(di0)
  h <- round(1 - di0/d0, 2)
  names(h) <- rownames(data)
  rank <- l - rank(h) +1 
  h <- as.data.frame(h)
  h["ranking"] <- rank
  colnames(h)[1] <- "wskaznik"
  #h <- cbind(h, 1:20)
  #h <- h[,2]
  return(h)
}

funcTopsis <- function(data, w, ch) {
  
  dane_topsis <- as.matrix(data)
  wynik_topsis <- as.data.frame(topsis(dane_topsis, w, ch))
  
  rownames(wynik_topsis) <- rownames(data)
  wynik_topsis <- wynik_topsis[, -1]
  wynik_topsis["wskaznik"] <- round(wynik_topsis$score, 2)
  wynik_topsis["ranking"] <- wynik_topsis$rank
  wynik_topsis <- cbind(wynik_topsis["wskaznik"], wynik_topsis["ranking"])
  return(wynik_topsis)
}

metodaStandSum <- function(dane, wagi, charakter) {
  
  l_wierszy <- dim(dane)[1]
  l_kol = dim(dane)[2]
  
  dane_sum <- as.data.frame(matrix(NA, nrow = l_wierszy, ncol = 0))
  
  # zamiana na stymulanty
  for (i in 1:l_kol) {
    kolumna <- as.data.frame(dane[,i])
    colnames(kolumna) <- colnames(dane)[i]
    ch <- charakter[i]
    
    if (identical(ch, "+")){
      # jesli kolumna jest stymulanta
    } else if(identical(ch, "-")) {
      # jesli kolumna jest destymulanta
      kolumna <- (-1)*kolumna
    }
    dane_sum <- cbind(dane_sum, kolumna)
  }
  # ważenie zmiennych 
  dane_sum <- as.data.frame(dane_sum)
  rownames(dane_sum) <- rownames(dane)
  dane_sum <- dane_sum*wagi
  
  # standaryzacja
  dane_sum <- data.Normalization(dane_sum, type = "n6", normalization = "column")
  
  # wyznaczanie wystandaryzowanej sumy
  # chyba błąd w apply ale nie jestem pewien # todo
  dane_sum["srednia"] <- apply(dane_sum, 1, mean)
  dane_sum["wskaznik"] <- data.Normalization(dane_sum["srednia"], type = "n4")
  dane_sum["ranking"] <- (l_wierszy - rank(dane_sum["wskaznik"]) + 1)
  
  # dane_sum <- dane_sum[order(dane_sum$wskaznik, decreasing = TRUE),]
  dane_sum <- cbind(dane_sum["wskaznik"], dane_sum["ranking"])
  return(dane_sum)
}

metodaRang <- function(dane, wagi, charakter){
  
  l_wierszy <- dim(dane)[1]
  l_kol = dim(dane)[2]
  
  dane_rangowane <- matrix(NA, nrow = l_wierszy, ncol = 0)
  rangi <- matrix(data = NA, nrow = l_wierszy, ncol = 0)
  # każdej kolumnie przypisuje rangi
  for (i in 1:l_kol){
    # rangowanie kolumny
    kolumna <- as.data.frame(dane[,i])
    colnames(kolumna) <- colnames(dane)[i]
    charakter <- as.matrix(charakter)
    ch <- charakter[i]
    
    
    if (identical(ch, "+")){
      # jesli kolumna jest stymulanta
      # im mniejsza wartosc tym mniejsza ranga
      ranga <- l_wierszy - rank(kolumna) +1
      rangi <- cbind(rangi, ranga)
    } else if(identical(ch, "-")) {
      # jesli kolumna jest destymulanta
      ranga <- rank(kolumna)
      rangi <- cbind(rangi, ranga)
    }
    
    dane_rangowane <- cbind(dane_rangowane, kolumna, ranga)
  }
  rangi <- as.data.frame(rangi)
  rangi <- rangi*wagi
  
  rangi["srednia"] <- as.data.frame(apply(rangi, 1, mean))
  rangi["ocena"] <- rank(rangi["srednia"])
  dane_rangowane <- cbind(dane_rangowane, rangi["srednia"], rangi["ocena"])
  dane_rangowane <- as.data.frame(dane_rangowane)
  rownames(dane_rangowane) <- rownames(dane)
  dane_rangowane <- cbind(dane_rangowane["srednia"], dane_rangowane["ocena"])
  colnames(dane_rangowane) <- c("wskaznik", "ranking")
  return(dane_rangowane)
}

server <- function(input, output, session) {
  
  #Opisy metod
  output$description<-renderText(
    if(input$method=="HELLWIG"){
      "Metoda Hellwiga jest jedną z powszechnie stosowanych metod taksonomicznych. Oblicza się ją jako syntetyczny wskaźnik taksonomicznej odległości wybranego obiektu od teoretycznego wzorca rozwoju. Przy wykorzystaniu odpowiednich wzorów wyznaczyć można wskaźnik syntetyczny dla każdego obiektu. Miernik ten przyjmuje wartości z przedziału [0,1]. Im wyższa wartość miernika tym obiekt jest bardziej zbliżony do wzorca, natomiast im niższa wartość tym obiekt jest bardziej od niego oddalony."
    }else if(input$method=="TOPSIS"){
      "Idea metody TOPSIS polega na określeniu odległości rozpatrywanych obiektów od rozwiązania idealnego i antyidealnego. Końcowym rezultatem analizy jest wskaźnik syntetyczny tworzący ranking badanych obiektów. Za najlepszy obiekt uważa się ten, który ma najmniejszą odległość od rozwiązania idealnego i jednocześnie największą od rozwiązania antyidealnego."
    }else if(input$method=="STANDARYZOWANYCH SUM"){
      "Metoda standaryzowanych sum jest popularną techniką bezwzorcowego porządkowania liniowego. Punktem wyjścia jest standaryzacja zmiennych, które następnie sumuję w ramach kolejnych obserwacji uwzględniając podane wagi poszczególnych cech. Na koniec stosuję wzór, który syntetyczny wskaźnik „przesuwa” w przedział [0,1], gdzie wartość 1 otrzymuje najlepsza w rankingu obserwacja, a 0 najgorsza."
    }else if(input$method=="RANG"){
      "Metoda sumy rang polega na wyznaczeniu rang obiektów ze względu na każdą z cech, a następnie wyznaczeniu ich sumy bądź średniej. Gdy dana wartość zmiennej występuje w więcej niż jednym obiekcie, przyporządkowujemy im jednakową rangę będącą średnią arytmetyczną z przysługujących im rang. Uwaga: Ta metoda nie działa najlepiej dla zmiennych, które są zadane na skali przedziałowej."
    }
  )
  
  
  values <- reactiveValues()
  
  # wczytywanie danych
  values$data <- reactive({
    infile <- input$file
    if(is.null(infile)){
      return(data.frame())
    }
    read.csv(infile$datapath, sep = ';', dec = ',', row.names = 1, header = TRUE, encoding = "utf-8")
  })
  
  
  # wybór zmiennych
  observeEvent(input$selectall, {
    data <- values$data()
    variables <- colnames(data)
    if(input$selectall == 0) return(NULL) 
    else if (input$selectall%%2 == 0){
      updateCheckboxGroupInput(session,"header",choices = variables)
    }
    else{
      updateCheckboxGroupInput(session,"header",choices = variables,selected = variables)
    }
  })
  
  observeEvent(values$data(), {
    data <- values$data()
    variables <- colnames(data)
    updateCheckboxGroupInput(session, "header", choices = variables)
  })
  
  values$filtered <- reactive({
    data <- values$data()
    data <- data[as.vector(input$header)]
  })
  
  observeEvent(values$filtered(), {
    data <- values$filtered()
    var <- colnames(data)
    updateCheckboxGroupInput(session, "ch_test", choices = var)
  })
  
  observeEvent(input$selectall2, {
    data <- values$filtered()
    var <- colnames(data)
    if(input$selectall2 == 0) return(NULL) 
    else if (input$selectall2%%2 == 0){
      updateCheckboxGroupInput(session,"ch_test",choices = var)
    }
    else{
      updateCheckboxGroupInput(session,"ch_test",choices = var,selected = var)
    }
  })
  
  values$character <- reactive({
    all_val <- colnames(values$filtered())
    selected <- as.vector(input$ch_test)
    print(selected)
    out <- c()
    for (i in 1:length(all_val)){
      if(is.element(all_val[i], selected)){
        out <- c(out, "+")
      }
      else {
        out <- c(out, "-")
      }
    }
    out
  })
  
  # todo
  values$weights <- reactive({
    data <- values$filtered()
    w <- c()
    
    for(i in 1:dim(data)[2]){
      w <- c(w, 1)
    }
    w
  })
  

  # skrypty ogarniające ranking
  values$HELLWIG <- reactive({
    data <- values$filtered()
    w <- as.vector(values$weights())
    ch <- as.vector(values$character())
    
    data <- Hellwig_func(data, w, ch)
    data <- data[order(data$ranking),]
    data
  })
  
  values$TOPSIS <- reactive({
    data <- values$filtered()
    w <- as.vector(values$weights())
    ch <- as.vector(values$character())
    
    data <- funcTopsis(data, w, ch)
    data <- data[order(data$ranking),]
    data
  })
  
  values$STAND <- reactive({
    data <- values$filtered()
    w <- as.vector(values$weights())
    ch <- as.vector(values$character())
    
    data <- metodaStandSum(data, w, ch)
    data <- data[order(data$ranking),]
    data
  })
  
  values$RANG <- reactive({
    data <- values$filtered()
    w <- as.vector(values$weights())
    ch <- as.vector(values$character())
    
    data <- metodaRang(data, w, ch)
    data <- data[order(data$ranking),]
    data
  })
  
  
  # podgląd danych
  output$data_view <- DT::renderDataTable({
    datatable(values$filtered(), rownames = TRUE)
  })
  
  # statystyki opisowe
  output$stats <- DT::renderDataTable({
    datatable(describeBy(values$filtered(), rownames = T))
    })
  
  
  # wyświetlanie rankingów
  output$hellwig_rank <- renderDataTable({values$HELLWIG()})
  output$topsis_rank <- renderDataTable({values$TOPSIS()})
  output$stand_rank <- renderDataTable({values$STAND()})
  output$rank_rank <- renderDataTable({values$RANG()})
  
  # zapis rankingów do plików
  
  # todo: ustawienie domyslnego katalogu zapisu
  values$data_to_save <- reactive({values$filtered()})
  output$save_h <- downloadHandler(
    filename = function(){"ranking_hellwig.csv"},
    content = function(fname){
      write.csv(as.data.frame(values$HELLWIG()), fname)
    }
  )
  values$data_to_save <- reactive({values$TOPSIS()})
  output$save_t <- downloadHandler(
    filename = function(){"ranking_topsis.csv"},
    content = function(fname){
      write.csv(as.data.frame(values$TOPSIS()), fname)
    }
  )
  values$data_to_save <- reactive({values$STAND()})
  output$save_s <- downloadHandler(
    filename = function(){"ranking_sum.csv"},
    content = function(fname){
      write.csv(as.data.frame(values$STAND()), fname)
    }
  )
  values$data_to_save <- reactive({values$RANK()})
  output$save_r <- downloadHandler(
    filename = function(){"ranking_rang.csv"},
    content = function(fname){
      write.csv(as.data.frame(values$RANG()), fname)
    }
  )

}


shinyApp(ui = ui, server = server)

