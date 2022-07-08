# Title     : TODO
# Objective : TODO
# Created by: Mac1
# Created on: 2020/08/05
# List up files

files <- list.files('SSuppR3/pre_DMI/data',full.names=T)
f <- length(files)

si <- gsub(".*(..)DATE.*","\\1", files)
n <- length(table(si))
usi <- unique(si)

# Load data and store
temp2 <- read.csv(files[1], stringsAsFactors = F)
temp2$sub <- si[1]
temp2$sn <- 1
m <- data.frame(mean(temp2$cdt), si[1])
for (i in 2:f) {
  d <- read.csv(files[[i]], stringsAsFactors = F)
  d$sub <- si[i]
  d$sn <- i
  temp2 <- rbind(temp2, d)
  
  m <- rbind(m, c(mean(d$cdt), si[i]))
}

library(ggplot2)

g <- ggplot(temp2, aes(sub, cdt)) + geom_point() + stat_summary(fun=mean, geom="point", colour="red")
g
