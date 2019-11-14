library(shiny)
library(shinythemes)
library(topsis)
library(clusterSim)

variables <- c()

ui <- fluidPage(theme = shinytheme("cyborg"),
   
  titlePanel("Projekt IE"),
  navbarPage("MENU",inverse = T,
    tabPanel("OPIS",
            sidebarPanel(
            selectInput("method","METODA:",choices = c("HELLWIG","TOPSIS","STANDARYZOWANYCH SUM","RANG","GŁÓWNYCH SKŁADOWYCH"))
            ),
            mainPanel(
              textOutput("description"), #tu przydzielić opisy metod w zależności od wyboru
            )),
    
    tabPanel("DANE",
             sidebarPanel(
               tabPanel("WYBÓR",
                        checkboxGroupInput("header", "Zmienne:", choices = variables), #w variables mają być nazwy zmiennych, a z headera wybieramy zmienne
                        actionButton("selectall","Zaznacz wszystkie")
                      )
             ),
            mainPanel(
              fileInput(inputId = "file", "Wybierz plik", 
                        accept=c('text/csv','text/comma-separated-values,text/plain','.csv')), #wczytuje dane do "file"
              dataTableOutput("data_view"), #tu przydzielić tabelke z danymi po wczytaniu
            )),
   
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
                       ),
              tabPanel("GŁÓWNYCH SKŁADOWYCH",
                       dataTableOutput("main_rank"),
                       downloadButton("save_m", "Zapisz") 
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
  dane_topsis <-as.matrix(data)
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

# todo
metodaGlownejSkladowej <- function(dane, wagi, charakter) {
  return(dane)
}

server <- function(input, output, session) {
  
  values <- reactiveValues()
  
  # wczytywanie danych
  values$data <- reactive({
    infile <- input$file
    if(is.null(infile)){
      return(data.frame())
    }
    
    read.csv(infile$datapath, sep = ';', row.names = 1, header = TRUE, encoding = "utf-8")
  })
  
  # wybór zmiennych
  observe({
    data <- values$data()
    variables <- colnames(data)
    updateCheckboxGroupInput(session, "header", choices = variables)
    
    if(input$selectall == 0) return(NULL) 
    else if (input$selectall%%2 == 0){
      updateCheckboxGroupInput(session,"header",choices = variables)
    }
    else{
      updateCheckboxGroupInput(session,"header",choices = variables,selected = variables)
    }

    
  })
  
  values$filtered <- reactive({
    data <- values$data()
    data <- data[,as.vector(input$header) ] # todo
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
  
  # todo
  values$character <- reactive({
    data <- values$filtered()
    ch <- c()
    for(i in 1:dim(data)[2]){
      ch <- c(ch, "+")
    }
    ch
  })
  
  # podgląd danych
  # todo: nie wyswietlją się nazwy wierszy
  #       nie wyswietla podglad jesli wybierzemy tylko jedna kolumne
  output$data_view <- renderDataTable({
      values$filtered()
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
  
  # todo
  values$MAIN <- reactive({
    data <- values$filtered()
    w <- as.vector(values$weights())
    ch <- as.vector(values$character())
    
    data <- metodaGlownejSkladowej(data, w, ch)
    data
  })
  
  # wyświetlanie rankingów
  output$hellwig_rank <- renderDataTable({values$HELLWIG()})
  output$topsis_rank <- renderDataTable({values$TOPSIS()})
  output$stand_rank <- renderDataTable({values$STAND()})
  output$rank_rank <- renderDataTable({values$RANG()})
  output$main_rank <- renderDataTable({values$MAIN()})
  
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
  values$data_to_save <- reactive({values$MAIN})
  output$save_m <- downloadHandler(
    filename = function(){"ranking_g_skladowa.csv"},
    content = function(fname){
      write.csv(as.data.frame(values$MAIN()), fname)
    }
  )

}


shinyApp(ui = ui, server = server)

