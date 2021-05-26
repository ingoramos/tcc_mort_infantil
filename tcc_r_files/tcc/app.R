#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


library(shiny)
library(shinydashboard)

library(ggplot2)
library(ggExtra)

library(d3treeR)
library(collapsibleTree)


pred_mort <- function(bancoTreino, bancoPred){
    
    ##################################################################################
    #Para fazer o desenho da matriz de confusão
    draw_confusion_matrix <- function(cm) {
        layout(matrix(c(1,1,2)))
        par(mar=c(2,2,2,2))
        plot(c(100, 345), c(300, 450), type = "n", xlab="", ylab="", xaxt='n', yaxt='n')
        title('CONFUSION MATRIX', cex.main=2)
        # create the matrix 
        rect(150, 430, 240, 370, col='red')
        text(195, 435, 'Não', cex=1.2)
        rect(250, 430, 340, 370, col='green')
        text(295, 435, 'Sim', cex=1.2)
        text(125, 370, 'Predição', cex=1.3, srt=90, font=2)
        text(245, 450, 'Referência', cex=1.3, font=2)
        rect(150, 305, 240, 365, col='green')
        rect(250, 305, 340, 365, col='red')
        text(140, 400, 'Sim', cex=1.2, srt=90)
        text(140, 335, 'Não', cex=1.2, srt=90)
        # add in the cm results 
        res <- as.numeric(cm$table)
        text(195, 400, res[1], cex=1.6, font=2, col='white')
        text(195, 335, res[2], cex=1.6, font=2, col='white')
        text(295, 400, res[3], cex=1.6, font=2, col='white')
        text(295, 335, res[4], cex=1.6, font=2, col='white')
        # add in the specifics 
        plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", main = "DETALHES", xaxt='n', yaxt='n')
        text(10, 85, names(cm$byClass[1]), cex=1.2, font=2)
        text(10, 70, round(as.numeric(cm$byClass[1]), 3), cex=1.2)
        text(30, 85, names(cm$byClass[2]), cex=1.2, font=2)
        text(30, 70, round(as.numeric(cm$byClass[2]), 3), cex=1.2)
        text(50, 85, names(cm$byClass[5]), cex=1.2, font=2)
        text(50, 70, round(as.numeric(cm$byClass[5]), 3), cex=1.2)
        text(70, 85, names(cm$byClass[6]), cex=1.2, font=2)
        text(70, 70, round(as.numeric(cm$byClass[6]), 3), cex=1.2)
        text(90, 85, names(cm$byClass[7]), cex=1.2, font=2)
        text(90, 70, round(as.numeric(cm$byClass[7]), 3), cex=1.2)
        # add in the accuracy information 
        text(30, 35, names(cm$overall[1]), cex=1.5, font=2)
        text(30, 20, round(as.numeric(cm$overall[1]), 3), cex=1.4)
        text(70, 35, names(cm$overall[2]), cex=1.5, font=2)
        text(70, 20, round(as.numeric(cm$overall[2]), 3), cex=1.4)
    }  
    ##################################################################################
    
    # dados para treino
    train_data <- bancoTreino
    
    # dados para controle do teste
    test_ctrl <- bancoPred
    
    # dados para o teste
    test <- test_ctrl[, -which(names(test_ctrl) %in% c("OBITO"))]
    
    #lista com os métodos de balanceamento
    sampling_methods <- c("down", "up", "smote")
    j <- 1
    sm_index <- 1
    maior_valor <- 0 #usado para verificar qual o modelo com maior valor preditivo negativo.
    
    for(j in length(sampling_methods)){
        
        sm_index <- sm_index + 1
        j <- j + 1
        
        #Create train/test index
        # Create trainControl object: myControl - Deve ser utilizado em todos os modelos para que sejam comparáveis
        myControl <- trainControl(
            method = "repeatedcv", #"repeatedcv" é o método para realizar as repetições # cv cross validation
            number = 5, #number é o número de folds   ##use 10 folds
            repeats = 2, #repeats é o número de repetições para cada fold ##use 5 repeats
            summaryFunction = twoClassSummary,
            classProbs = TRUE, # IMPORTANT!
            verboseIter = FALSE,
            savePredictions = TRUE,
            returnResamp = "all",
            sampling = sampling_methods[sm_index], #balanceamento dos dados
            allowParallel = TRUE
        )
        
        #lista de modelos que serão usados inicialmente 
        # "glm" = Generalized Linear Model, "ranger" = Random Forest, "knn" = k-Nearest Neighbors, 
        #"nnet" = Neural Network, "dnn" = Stacked AutoEncoder Deep Neural Network, 
        #"xgbTree" = eXtreme Gradient Boosting, "gbm" = Stochastic Gradient Boosting, "adaboost" = AdaBoost Classification Trees.
        
        # "glm", "ranger", "knn", "gbm", "nnet", "adaboost", "xgbTree", "dnn"
        #"ranger", "gbm", "nnet"
        modelos <- c("glm")
        
        i <- 1 #indice para atualizar o while
        index <- 1 #indice que retorna o modelo da lista
        #voltar o "maior_valor" para esta posição se der errado ####################################################################
        #espec <- 0 #usado para verificar qual o modelo com maior especificidade.
        
        #lista com os métodos de balanceamentos
        metrics <- c("ROC", "Sens")
        k <- 1
        m_index <- 1
        
        for(k in length(metrics)){
            
            m_index <- m_index + 1
            k <- k + 1
            
            #loop para selecionar o melhor algoritmo
            while(i <= length((modelos))) {
                
                # Fit model
                model <- train(
                    OBITO ~ . , #variável preditiva
                    data = train_data, #banco de treino
                    #preProcess = c("center", "scale"),
                    metric = metrics[m_index], # métrica para comparação dos modelos
                    method = modelos[index], #lista com indice (retorna uma string com o nome do método para cada modelo)
                    trControl = myControl #aplica o controle
                    
                )
                
                #fazendo a matriz de confusão para o banco de treino    
                banco_model <- model$trainingData
                
                banco_model$.outcome <- as.factor(banco_model$.outcome)
                
                cm_t <- confusionMatrix(banco_model$.outcome, sample(banco_model$.outcome))
                
                
                # Print model to console
                model
                
                # Print maximum ROC statistic
                max(model[["results"]][["ROC"]])
                
                #predição dos modelos no banco para matriz de confusão
                predictionsCM <- predict(model, test)
                
                #predição dos modelos no banco para probabilidade
                predictions <- predict(model, test, type = "prob")
                
                #o test_control é usado para comparação com os valores da predição, gerando a matriz de confusão.
                cm <- confusionMatrix(predictionsCM, test_ctrl$OBITO)
                
                #extraindo os resultados da matriz de confusão
                cm_results <- cm$byClass %>% as.list()
                
                #extraindo a sensibilidade
                sens <- cm_results[1] %>% as.data.frame() # [1] para sens [2] para spec
                sens <- sens$Sensitivity #Sensitivity ou sens / Specificity ou spec
                
                
                #verificação do maior valor preditivo negativo, como inicialmente o maior valor está atribuído como 0, o primeiro modelo sempre terá o maior valor, ou seja, sempre que um modelo conseguir alcançar um valor preditivo negativo maior que o armazenado na memória, este passa a ser o instrumento de verificação.
                if(sens > maior_valor){
                    maior_valor <- sens #valor preditivo positivo passa a ser o maior valor
                    resultado <- paste("O melhor modelo foi: ", modelos[index], ", usando o método de balanceamento: ", sampling_methods[sm_index], "com a métrica: ", metrics[m_index], ", com sensibilidade de: ", sens) #mensagem para informar o modelo com melhor resultado
                    cm_melhor <- cm #cm armazena os dados da matriz de confusão (teste) do melhor modelo
                    cm_t_melhor <- cm_t #cm_t armazena os dados da matriz de confusão (treino) do melhor modelo
                    melhor_modelo <- model
                    
                    #colando a coluna da predição para comparar com a real
                    resultados <- cbind(test_ctrl, predictions)
                    
                    #cria uma coluna com a probabilidade em % de OBITO
                    resultados["Prob"] <- resultados$sim * 100
                    
                    modelo <- modelos[index]
                    samp <- sampling_methods[sm_index]
                    metrica <- metrics[m_index]
                    
                }
                else{
                    maior_valor <- maior_valor #caso a verificação falhe, o maior_valor continua sendo ele mesmo ("atual")
                }
                
                #atualiza o indice para o i (while), e index (lista de modelos)
                i <- i + 1
                index <- index + 1
                
            }
        }
    }
    #desenha a matriz de confusão para o cm armazenado com o melhor modelo
    #cm_p <- draw_confusion_matrix(cm_melhor)  
    
    #retorno da função (matriz de confusão de treino (cm_t), mensagem de resultado (resultado), desenho da matriz de confusão de teste (cm_p))
    return(list(melhor_modelo, cm_melhor))
    
}

modeloPred <- pred_mort(final_train, final_test)
conMatrix <- modeloPred[2]
bestModel <- modeloPred[1]

# Define UI for application that draws a histogram
ui <- dashboardPage(
    dashboardHeader(title = "Mortalidade Infantil"),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Correlação", tabName = "corr", icon = icon("sitemap"),
                     menuSubItem("HeatMap", tabName = "corr_1"),
                     menuSubItem("DropOut Loss", tabName = "corr_2"),
                     menuSubItem("Information Value", tabName = "corr_3"),
                     menuSubItem("Boruta (Random Forest", tabName = "corr_4")
            ),
            menuItem("Variáveis Categóricas", tabName = "catVars", icon = icon("chart-pie"),
                     menuSubItem("Gráfico de Barra Circular", tabName = "subCatVars_1"),
                     menuSubItem("Gráfico de Donut", tabName = "subCatVars_2"),
                     menuSubItem("Gráfico de Árvore", tabName = "subCatVars_3")
            ),
            
            menuItem("Variáveis Numéricas", tabName = "numVars", icon = icon("chart-area"),
                     menuSubItem("Gráfico de Dispersão", tabName = "subNumVars_1"),
                     menuSubItem("Gráfico de Bolha", tabName = "subNumVars_2"),
                     menuSubItem("Box Plot com Individuos ", tabName = "subNumVars_3"),
                     menuSubItem("Histograma", tabName = "subNumVars_4")
            ),
            menuItem("Predição", tabName = "pred", icon = icon("baby-carriage"))
        )
    ),
    
    dashboardBody(
        tabItems(
            
            #correlação e seleção de variáveis
            tabItem(tabName = "corr_1",
                    fluidRow(
                        tags$style(type = "text/css", "#heatmapPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("heatmapPlot", height = "100%")
                    )),
            
            tabItem(tabName = "corr_2",
                    fluidRow(
                        tags$style(type = "text/css", "#dolPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("dolPlot", height = "100%")
                    )),
            
            tabItem(tabName = "corr_3",
                    fluidRow(
                        tags$style(type = "text/css", "#ivTable {height: calc(100vh - 80px) !important;}"),
                        tableOutput("ivTable")
                    )),
            
            tabItem(tabName = "corr_4",
                    fluidRow(
                        tags$style(type = "text/css", "#borutaPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("borutaPlot", height = "100%")
                    )),
            
            #variáveis categóricas
            tabItem(tabName = "subCatVars_1",
                    fluidRow(
                        tags$style(type = "text/css", "#circularBarPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("circularBarPlot", height = "100%")
                    )
            ),
            
            tabItem(tabName = "subCatVars_2",
                    fluidRow(
                        selectInput("donutSubset", label = "Selecione a Variável",
                                    choices = list("Escolaridade" = "ESCMAEAGR1_SINASC", "Gravidez" = "GRAVIDEZ_SINASC", 
                                                   "Raça/Cor" = "RACACORMAE_SINASC", "Gestação" = "GESTACAO_SINASC", "Parto" = "PARTO_SINASC",
                                                   "Consultas" = "CONSULTAS_SINASC", "Apgar1" = "APGAR1_SINASC", 
                                                   "Apgar5" = "APGAR5_SINASC", "Anomalia" = "IDANOMAL_SINASC")),
                        tags$style(type = "text/css", "#donutPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("donutPlot", height = "100%")
                    )
            ),
            
            tabItem(tabName = "subCatVars_3",
                    fluidRow(
                        tags$style(type = "text/css", "#treeMapPlot {height: calc(100vh - 80px) !important;}"),
                        collapsibleTreeOutput("treeMapPlot", height = "100%")
                    )
            ),
            
            #variáveis numéricas
            tabItem(tabName = "subNumVars_1",
                    fluidRow(
                        box(width = 3, selectInput("varX", label = "Selecione",
                                                   choices = list("Nº consultas Pré Natal" = "CONSPRENAT_SINASC", "Semanas de Gestação" = "SEMAGESTAC_SINASC",
                                                                  "Quantidade Gestações" = "QTDGESTANT_SINASC", "Idade da Mãe" = "IDADEMAE_SINASC", 
                                                                  "Filhos Vivos" = "QTDFILVIVO_SINASC"))),
                        box(width = 3, selectInput("varY", label = "Selecione",
                                                   choices = list("Semanas de Gestação" = "SEMAGESTAC_SINASC", "Nº consultas Pré Natal" = "CONSPRENAT_SINASC",
                                                                  "Quantidade Gestações" = "QTDGESTANT_SINASC", "Idade da Mãe" = "IDADEMAE_SINASC", 
                                                                  "Filhos Vivos" = "QTDFILVIVO_SINASC"))),
                        box(width = 3, selectInput("varSelect", label = "Selecione a variável", 
                                                   choices = list("Escolaridade" = "ESCMAEAGR1_SINASC", "Gravidez" = "GRAVIDEZ_SINASC", 
                                                                  "Raça/Cor" = "RACACORMAE_SINASC", "Gestação" = "GESTACAO_SINASC", "Parto" = "PARTO_SINASC",
                                                                  "Consultas" = "CONSULTAS_SINASC", "Apgar1" = "APGAR1_SINASC", 
                                                                  "Apgar5" = "APGAR5_SINASC", "Anomalia" = "IDANOMAL_SINASC"))),
                        box(width = 3, selectInput("graphType", label = "Selecione a variável", 
                                                   choices = list( "Densidade" = "density", "Boxplot" = "boxplot", "Histograma" = "histogram"))),
                        
                    ),
                    
                    fluidRow(
                        tags$style(type = "text/css", "#scatterPlot {height: calc(100vh - 80px) !important;}"),
                        plotOutput("scatterPlot", height = "100%")
                    )
            ),
            
            tabItem(tabName = "subNumVars_2",
                    fluidRow(
                        tags$style(type = "text/css", "#bubblePlot {height: calc(100vh - 80px) !important;}"),
                        plotlyOutput("bubblePlot", height = "100%")
                    )
            ),
            
            tabItem(tabName = "subNumVars_3",
                    
                    fluidRow(
                        box(width = 6, selectInput("varYbox", label = "Variável para eixo Y",
                                                   choices = list("Semanas de Gestação" = "SEMAGESTAC_SINASC", "Nº consultas Pré Natal" = "CONSPRENAT_SINASC",
                                                                  "Quantidade Gestações" = "QTDGESTANT_SINASC", "Idade da Mãe" = "IDADEMAE_SINASC", 
                                                                  "Filhos Vivos" = "QTDFILVIVO_SINASC"))),
                        
                        box(width = 6, selectInput("varXbox", label = "Variável para eixo X",
                                                   choices = list("Escolaridade" = "ESCMAEAGR1_SINASC", "Gravidez" = "GRAVIDEZ_SINASC", 
                                                                  "Raça/Cor" = "RACACORMAE_SINASC", "Gestação" = "GESTACAO_SINASC", "Parto" = "PARTO_SINASC",
                                                                  "Consultas" = "CONSULTAS_SINASC", "Apgar1" = "APGAR1_SINASC", 
                                                                  "Apgar5" = "APGAR5_SINASC", "Anomalia" = "IDANOMAL_SINASC")))
                    ),
                    
                    fluidRow(
                        tags$style(type = "text/css", "#boxPlot {height: calc(100vh - 80px) !important;}"),
                        plotlyOutput("boxPlot", height = "100%")
                    )
            ),
            
            tabItem(tabName = "subNumVars_4",
                    fluidRow(
                        box(width = 6, selectInput("varXhist", label = "Variável para eixo X",
                                                   choices = list("Semanas de Gestação" = "SEMAGESTAC_SINASC", "Nº consultas Pré Natal" = "CONSPRENAT_SINASC",
                                                                  "Quantidade Gestações" = "QTDGESTANT_SINASC", "Idade da Mãe" = "IDADEMAE_SINASC", 
                                                                  "Filhos Vivos" = "QTDFILVIVO_SINASC"))),
                        box(width = 6, selectInput("varYhist", label = "Variável para eixo Y",
                                                   choices = list("Escolaridade" = "ESCMAEAGR1_SINASC", "Gravidez" = "GRAVIDEZ_SINASC", 
                                                                  "Raça/Cor" = "RACACORMAE_SINASC", "Gestação" = "GESTACAO_SINASC", "Parto" = "PARTO_SINASC",
                                                                  "Consultas" = "CONSULTAS_SINASC", "Apgar1" = "APGAR1_SINASC", 
                                                                  "Apgar5" = "APGAR5_SINASC", "Anomalia" = "IDANOMAL_SINASC")))
                    ),
                    fluidRow(
                        tags$style(type = "text/css", "#histPlot {height: calc(100vh - 80px) !important;}"),
                        plotlyOutput("histPlot", height = "100%")
                    )
                    
            ),
            
            tabItem(tabName = "pred",
                    fluidRow(
                        box(width = 3, numericInput("idade", label = h4("Idade da Mãe"), value = NA)), #*****
                        box(width = 3, selectInput("gestacao", label = h4("Semanas de Gestação"),
                                                   choices = list("Menos de 22 semanas" = 1, "22 a 27 semanas" = 2, "28 a 31 semanas" = 3, "32 a 36 semanas" = 4, 
                                                                  "37 a 41 semanas" = 5, "42 semanas e mais" = 6, "Ignorado" = 9))), #*****
                        box(width = 3, selectInput("gravidez", label = h6("Tipo de gravidez"), 
                                                   choices = list("Única" = 1, "Dupla" = 2, "Tripla ou mais" = 3, "Ignorado" = 9))), #*****
                        box(width = 3, selectInput("parto", label = h6("Tipo de parto"), 
                                                   choices = list("Vaginal" = 1, "Cesário" = 2, "Ignorado" = 9))) #*****
                    ),
                    
                    fluidRow(
                        box(width = 3, selectInput("consultas", label = h6("Número de consultas de pré‐nata"), 
                                                   choices = list("Nenhuma consulta" = 1, "de 1 a 3 consultas" = 2, "de 4 a 6 consultas" = 3, 
                                                                  "7 e mais consultas" = 4, "Ignorado." = 9))), #*****
                        box(width = 3, numericInput("peso", label = h6("Peso ao nascer em gramas."), value = 1)), #*****
                        box(width = 3, numericInput("apgar1", label = h6("APGAR 1º minuto"), value = 1, max = 10, min = 1)), #*****
                        box(width = 3, numericInput("apgar5", label = h6("APGAR 5º minuto"), value = 1, max = 10, min = 1)) #*****
                    ),    
                    
                    fluidRow(
                        box(width = 3, selectInput("anomalia", label = h6("Anomalia identificada"), 
                                                   choices = list("Sim" = 1, "Não" = 2, "Ignorado" = 9))), #*****
                        box(width = 3, selectInput("escolaridade", label = h6("Escolaridade da Mãe"), 
                                                   choices = list("Sem escolaridade" = 0, "Fundamental I Incompleto" = 1, "Fundamental I Completo" = 2, 
                                                                  "Fundamental II Incompleto" = 3, "Fundamental II Completo" = 4, "Ensino Médio Incompleto" = 5, 
                                                                  "Ensino Médio Completo" = 6, "Superior Incompleto" =  7, "Superior Completo" = 8,
                                                                  "Fundamental I Incompleto ou Inespecífico" = 10, "Fundamental II Incompleto ou Inespecífico" = 11,
                                                                  "Ensino Médio Incompleto ou Inespecífico" = 12,  "Ignorado" = 9))), #*****
                        box(width = 3, selectInput("racacor", label = h6("Raça/Cor da Mãe"), 
                                                   choices = list("Branca" = 1, "Preta" = 2, "Amarela" = 3,
                                                                  "Parda" = 4, "Indígena" = 5, "Ignorado" = 9))),
                        box(width = 3, numericInput("qtdgestant", label = h6("Quantidade de gestações"), value = NA))
                    ),
                    
                    fluidRow(
                        box(width = 3, numericInput("semanagestac", label = h6("Número de semanas de gestação"), value = NA)),
                        box(width = 3, numericInput("consprenat", label = h6("Número de consultas pré Natal"), value = NA)),
                        box(width = 3, numericInput("qtdfilvivo", label = h6("Quantidade filhos vivos"), value = NA)),
                        div(align="center", actionButton("pred", "Predição"))
                    ),
                    
                    fluidRow(
                        div(align="center", h4(textOutput("probs")))
                    )
            )
        )
    )
    
)


# Define server logic required to draw a histogram
server <- function(input, output) {
    
    #correlação e seleção de variáveis
    output$heatmapPlot <- renderPlot({
        
        hm <- ggplot(data = melted_cor_mat_upper, aes(Var2, Var1, fill = value))+
            geom_tile(color = 'white')+
            scale_fill_gradient2(low = 'blue', high = 'red', mid = 'Yellow',
                                 midpoint = 0, limit = c(-1,1), space = 'Lab',
                                 name='Pearson Correlation')+
            theme_minimal()+
            theme(axis.text.x = element_text(angle = 45, vjust = 1,
                                             size = 12, hjust = 1))+
            coord_fixed()
        
        hm
    })
    
    output$dolPlot <- renderPlot({
        plot(rf_imp, lg_imp, svm_imp)+
            ggtitle("Permutation variable Importance", "")
    })
    
    
    output$ivTable <- renderTable({
        df_iv
    })
    
    output$borutaPlot <- renderPlot({
        plot(boruta_output, cex.axis=.7, las=2, xlab="", main="Variable Importance")
    })
    
    
    #plots das variáveis categóricas
    #Donut plot
    subDonut <- reactive({
        input$donutSubset
    })
    
    
    output$donutPlot <- renderPlot({
        
        plotData <- summary(data[, c(subDonut())])
        plotData <- as.data.frame(plotData)
        plotData <- rownames_to_column(plotData, var="var")
        names(plotData) <- c("feature", "value")
        
        plotData$fraction <- plotData$value / sum(plotData$value)
        
        plotData$ymax = cumsum(plotData$fraction)
        
        #para o plot tem que chamar essa funçaõ aqui que chama donutSubset
        #daí vai fazer o subset e plotar
        
        plotData$ymin = c(0, head(plotData$ymax, n=-1))
        
        ggplot(plotData, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=feature)) +
            geom_rect() +
            scale_fill_brewer(palette="Paired")+
            theme_minimal() +
            coord_polar(theta="y") + # Try to remove that to understand how the chart is built initially
            xlim(c(2, 4)) # Try to remove that to see how to make a pie chart
        
    })
    
    output$circularBarPlot <- renderPlot({
        
        cbp <- ggplot(circularBar_data, aes(x=as.factor(id), y=perc, fill=group)) +
            
            geom_bar(stat="identity", alpha=0.5) +
            
            ylim(-100,120) +
            
            scale_fill_brewer(palette = "Set2") +
            theme_minimal() +
            theme(
                axis.text = element_blank(),
                axis.title = element_blank(),
                panel.grid = element_blank(),
                plot.margin = unit(rep(-2,4), "cm")     # This remove unnecessary margin around plot
            ) +
            
            coord_polar(start = 0)+
            
            geom_text(data=label_data, aes(x=id, y=perc+10, label=feature, hjust=hjust), color="black", 
                      fontface="bold",alpha=0.6, size=5.5, angle= label_data$angle, inherit.aes = FALSE )
        
        
        cbp
    })
    
    output$treeMapPlot <- renderCollapsibleTree({
        
        sub_data <- data[, c(4, 7, 10)]
        
        #tentar agrupar os valores de alguma forma e contar a quantidade de dados
        #https://adeelk93.github.io/collapsibleTree/
        tmp <- collapsibleTree(df=sub_data, c('GESTACAO_SINASC', 'CONSULTAS_SINASC', 'IDANOMAL_SINASC'), fill='lightsteelblue', tooltip = TRUE, collapsed = FALSE)
        tmp
    })
    
    
    #variáveis numéricas
    #plot scatter
    output$scatterPlot <- renderPlot({
        #hist(final_train$IDADEMAE_SINASC)
        sub_box <- data[data$CONSPRENAT_SINASC != 99, ]
        
        p <- ggplot(sub_box, aes_string(x=input$varX, y=input$varY, color=input$varSelect)) + #, size="cyl"
            geom_point(size=3) +
            scale_fill_brewer(palette = "Set2") +
            theme_minimal() 
        
        
        
        p1 <- ggMarginal(p, type = input$graphType)
        p1
    })
    
    
    output$bubblePlot <- renderPlotly({
        
        sub_bubble <- data[data$CONSPRENAT_SINASC != 99, ]
        
        sub_bubble$OBITO <- as.factor(sub_bubble$OBITO)
        
        sub_bubble %>%
            arrange(desc(QTDGESTANT_SINASC))
        
        p <- ggplot(data=sub_bubble, aes(x=SEMAGESTAC_SINASC, y=CONSPRENAT_SINASC, size=QTDGESTANT_SINASC, fill=OBITO)) +
            geom_point(alpha=0.5, shape=21, color="black") +
            scale_size(range = c(.1, 24), name='Quantidade Gestações') +
            scale_fill_brewer(palette="Set2")+
            theme_minimal() +
            theme(legend.position="bottom") +
            ylab("Consultas pré Natal") +
            xlab("Semanas de Gestação") +
            theme(legend.position = "none")
        
        p
    })
    
    
    output$boxPlot <- renderPlotly({
        
        box_ind_data <- data[data$CONSPRENAT_SINASC != 99, ]
        
        # Plot
        box_ind_data %>%
            ggplot( aes_string(x=input$varXbox, y=input$varYbox, fill=input$varXbox)) +
            geom_boxplot() +
            scale_fill_brewer(palette="Paired") +
            geom_jitter(color="black", size=0.4, alpha=0.9) +
            theme_minimal() +
            theme(
                legend.position="none",
                plot.title = element_text(size=11)
            ) +
            theme(axis.text.x = element_text(angle = 45, vjust = 1,
                                             size = 12, hjust = 1))+
            ggtitle("BoxPlot com individuos") +
            xlab("")
        
    })
    
    output$histPlot <- renderPlotly({
        
        hist_data <- data
        
        p <- hist_data %>%
            ggplot( aes_string(x=input$varXhist, fill=input$varYhist)) +
            geom_histogram( color="#e9ecef", alpha=0.6, position = 'identity') +
            scale_fill_brewer(palette="Paired") +
            theme_minimal() +
            labs(fill="")
        p
        
    })
    
    
    #predição
    observeEvent( input$pred, {
        
        gestacao <- as.factor(input$gestacao)
        gravidez <- as.factor(input$gravidez)
        parto <- as.factor(input$parto)
        consultas <- as.factor(input$consultas)
        apgar1 <- as.factor(input$apgar1)
        apgar5 <- as.factor(input$apgar5)
        anomalia <- as.factor(input$anomalia)
        escolaridade <- as.factor(input$escolaridade)
        racacor <- as.factor(input$racacor)
        
        qtdgestant <- as.numeric(input$qtdgestant)
        semanagestac <- as.numeric(input$semanagestac)
        idade <- as.numeric(input$idade)
        peso <- as.numeric(input$peso)
        consprenat <- as.numeric(input$consprenat)
        qtdfilvivo <- as.numeric(input$qtdfilvivo)
        
        teste_obito <- cbind.data.frame(gestacao, gravidez, parto, consultas, apgar1, apgar5, anomalia, escolaridade, racacor,
                                        qtdgestant, semanagestac, idade, peso, consprenat, qtdfilvivo)
        
        scaled <- cbind(data.frame(qtdgestant, semanagestac, idade, peso, consprenat, qtdfilvivo))
        scaled <- as.matrix(scaled)
        scaled <- scale(scaled, center = T, scale = T)
        
        teste_obito <- cbind(teste_obito, scaled)
        
        
        names(teste_obito) <- c("GESTACAO_SINASC", "GRAVIDEZ_SINASC", "PARTO_SINASC", "CONSULTAS_SINASC", "APGAR1_SINASC", "APGAR5_SINASC", 
                                "IDANOMAL_SINASC", "ESCMAEAGR1_SINASC", "RACACORMAE_SINASC", 
                                "QTDGESTANT_SINASC", "SEMAGESTAC_SINASC", "IDADEMAE_SINASC", "PESO_SINASC", "CONSPRENAT_SINASC", "QTDFILVIVO_SINASC")
        
        teste_obito$APGAR1_SINASC <- as.numeric(teste_obito$APGAR1_SINASC)
        teste_obito$APGAR5_SINASC <- as.numeric(teste_obito$APGAR5_SINASC)
        
        for(i in 1:nrow(teste_obito)){
            if(teste_obito$APGAR1_SINASC[i] <= 2){teste_obito$APGAR1_SINASC[i] <- "asfixia grave"}
            else if(teste_obito$APGAR1_SINASC[i] >= 3 & teste_obito$APGAR1_SINASC[i] <= 4){teste_obito$APGAR1_SINASC[i] <- "asfixia moderada"}
            else if(teste_obito$APGAR1_SINASC[i] >= 5 & teste_obito$APGAR1_SINASC[i] <= 7){teste_obito$APGAR1_SINASC[i] <- "asfixia leve"}
            else {teste_obito$APGAR1_SINASC[i] <- "sem asfixia"}
        }
        
        teste_obito$APGAR1_SINASC <- as.factor(teste_obito$APGAR1_SINASC)
        
        for(i in 1:nrow(teste_obito)){
            if(teste_obito$APGAR5_SINASC[i] <= 2){teste_obito$APGAR5_SINASC[i] <- "asfixia grave"}
            else if(teste_obito$APGAR5_SINASC[i] >= 3 & teste_obito$APGAR5_SINASC[i] <= 4){teste_obito$APGAR5_SINASC[i] <- "asfixia moderada"}
            else if(teste_obito$APGAR5_SINASC[i] >= 5 & teste_obito$APGAR5_SINASC[i] <= 7){teste_obito$APGAR5_SINASC[i] <- "asfixia leve"}
            else {teste_obito$APGAR5_SINASC[i] <- "sem asfixia"}
        }
        
        teste_obito$APGAR5_SINASC <- as.factor(teste_obito$APGAR5_SINASC)
        
        teste_obito$ESCMAEAGR1_SINASC <- as.factor(teste_obito$ESCMAEAGR1_SINASC)
        teste_obito$GESTACAO_SINASC <- as.factor(teste_obito$GESTACAO_SINASC)
        teste_obito$GRAVIDEZ_SINASC <- as.factor(teste_obito$GRAVIDEZ_SINASC)
        teste_obito$PARTO_SINASC <- as.factor(teste_obito$PARTO_SINASC)
        teste_obito$CONSULTAS_SINASC <- as.factor(teste_obito$CONSULTAS_SINASC)
        teste_obito$IDANOMAL_SINASC <- as.factor(teste_obito$IDANOMAL_SINASC)
        teste_obito$RACACORMAE_SINASC <- as.factor(teste_obito$RACACORMAE_SINASC)
        
        #RESOLVER O PROBLEMA DOS FATORES E SCALE NO DADOS NUMERICOS
        
        
        output$probs <- renderText({
            pred <- function(model, teste){
                
                model <- model
                test <- teste
                
                #predição dos modelos no banco para probabilidade
                predictions <- predict(model, test, type = "prob")
                
                #colando a coluna da predição para comparar com a real
                resultados <- cbind(test, predictions)
                
                #cria uma coluna com a probabilidade em % de OBITO
                resultados["Prob"] <- resultados$sim * 100  
                
                prob <- resultados$Prob
                resultados$Prob <- as.numeric(resultados$Prob)
                
                
                resultados["Probs"] <- NA
                
                for(i in 1:nrow(resultados)){
                    if(resultados$Prob[i] <= 100 & resultados$Prob[i] >= 50){resultados$Probs[i] <- "alta"
                    }
                    else if(resultados$Prob[i] < 50 & resultados$Prob[i] >= 30){resultados$Probs[i] <- "média"
                    }
                    else{resultados$Probs[i] <- "baixa"
                    }
                }
                
                prob <- resultados$Probs
                probNum <- resultados$Prob
                
                #resultado <- probNum
                
                resultado <- paste("Criança com ", prob, " probabilidade de óbito.") #, " Probabilidade num: ", probNum
                
                return(resultado)
                
            }
            
            probs <- pred(bestModel, teste_obito)
            
        })
        
    })
    
    observeEvent( input$corrMax, {
        
        output$corr <- renderPrint({
            
            corr <- conMatrix
            
        })
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)
