################################################################################################################################################
#################################### Criando um índice de incerteza econômica com base nas atas do Copom #######################################

## Setup:

library(tidyselect)
library(tidytext)
library(dplyr)
library(quanteda)
library(topicmodels)
library(tm)
library(tidyr)
library(rvest)
library(rprojroot)
library(RSelenium)
library(netstat)
library(robotstxt)
library(pdftools)
library(stm)
library(wordcloud)
library(coreNLP)
library(syuzhet)
library(textdata)
library(ldatuning)
library(sidrar)
library(xtable)
library(vars)
library(GetBCBData)
library(forecast)
library(readr)
library(readxl)
library(tidyverse)
library(ggplot2)
library(xts)
library(lubridate)
library(timetk)
library(zoo)
library(ggpubr)
library(tinytex)
library(rbcb)
library(httr)
library(magrittr)
library(data.table)
library(RCurl)
library(usethis)

## Obtendo as listas das atas do COPOM via API:

listas_atas_raw <- httr::GET(url = "https://www.bcb.gov.br/api/servico/sitebcb/copom/atas?quantidade=100",
                      accept_json(),
                      add_headers('Accept: application/json'))

## Obtendo as listas das atas do COPOM via API:

listas_atas_content <- httr::content(listas_atas_raw,type = "application/json")

## Transformando em data.frame:

listas_atas_df <- purrr::map(listas_atas_content,as.data.table) %>%
  rbindlist(fill = TRUE, idcol = FALSE) %>%
  t() %>%
  as.data.frame() %>%
  dplyr::rename_with(~c("NUM_REUNIAO","DATA_REF","DATA_PUBLIC","TITULO")) %>%
  dplyr::mutate(DATA_REF = lubridate::ymd(DATA_REF),
                DATA_PUBLIC = lubridate::ymd(DATA_PUBLIC))

## URL com número das reuniões:

url_conteudo <- paste0("https://www.bcb.gov.br/api/servico/sitebcb/copom/atas_detalhes?nro_reuniao=",listas_atas_df$NUM_REUNIAO)

## Conteúdo das atas:

listas_conteudo <- RCurl::getURI(url = url_conteudo, .opts=curlOptions(followlocation=TRUE),.encoding = "CE_LATIN1")

## Juntando a listagem com o conteúdo das atas:

atas_conteudo_join <- cbind(listas_atas_df,listas_conteudo)

## Função para remover código HTML:

addspace <- tm::content_transformer(function(x, pattern) {
  return(gsub(pattern, " ", x))
})

## Criando um Corpus:

corpus_atas <- tm::Corpus(tm::VectorSource(listas_conteudo)) %>%
  tm::tm_map(addspace,"<.*?>") %>%
  tm::tm_map(removeWords, stopwords("pt")) %>%
  tm::tm_map(removePunctuation) %>%
  tm::tm_map(stripWhitespace)

## Vendo os dados e as alterações sobre:

writeLines(head(strwrap(corpus_atas[[100]]), 15)) 
