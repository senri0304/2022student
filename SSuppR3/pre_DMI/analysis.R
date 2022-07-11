# Title     : TODO
# Objective : TODO
# Created by: Mac1
# Created on: 2020/08/05
# List up files

files <- list.files('pre_DMI/data',full.names=T)
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

dat <- subset(temp2, sn!=c(4, 5))
dat <- subset(dat, sn!=c(4, 5))
dat <- subset(dat, sn!=c(4, 5))
g <- ggplot(dat, aes(sub, cdt)) + 
  geom_point(alpha=0.4) + stat_summary(fun=mean, geom="point", color='red') + 
  geom_hline(yintercept = mean(dat$cdt), size = 0.5, linetype = 1, color = "#5B9BD5") +
  xlab('observer') + ylab('Cumlative disappearance time') + theme(axis.title=element_text(size=14))
g
