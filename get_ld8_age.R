#!/usr/bin/env Rscript

#
# Usage: get_ld8_age.R 11543_20180626 11570_20180615
#
# outputs tab delmin table with age and sex (+ dob)
# ld8 age   sex   dob
# 11543_20180626 16.06 M  2002-06-03
# 11570_20180615 20.39 F  1998-01-23
# 
# N.B. merge is likely to resort from input order
# if bad date or unfound luna, will spit out "NA"
#

suppressMessages(library(dplyr))

d <- data.frame(ld8=commandArgs(trailingOnly=T)) %>%
 tidyr::separate(sep="_", ld8, c("id", "ymd"), remove=F) %>%
 mutate(vdate=lubridate::ymd(ymd))

# input into sql approprate string. eg " '11523','10931' "
l_in <-
   d$id %>%
   gsub("[^0-9A-Za-z]", "", .) %>% # sanatize
   gsub("^", "'", .) %>%           # add begin quote
   gsub("$", "'", .) %>%           # add ending quote
   paste(collapse=",")             # put commas between

query <- sprintf("
          select *
          from person
          natural join enroll
          where id in (%s)", l_in)

r <- LNCDR::db_query(query)
f <-
   merge(r, d, by="id", all=T) %>%
   mutate(age=round(as.numeric(vdate-dob)/365.25, 2)) %>%
   select(ld8, age, sex, dob)

# spit out results
write.table(f, file=stdout(), row.names=F, sep="\t", quote=F)
