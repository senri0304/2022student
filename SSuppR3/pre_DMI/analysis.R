# Title     : TODO
# Objective : TODO
# Created by: Mac1
# Created on: 2020/08/05
# List up files

library(ggplot2)

files <- list.files('SSuppR2/pre_DMI/data',full.names=T)
f <- length(files)

si <- gsub(".*(..)DATE.*","\\1", files)
n <- length(table(si))
usi <- unique(si)

# Load data and store
temp2 <- read.csv(files[1], stringsAsFactors = F)
temp2$sub <- si[1]
temp2$sn <- 1
for (i in 2:f) {
  d <- read.csv(files[[i]], stringsAsFactors = F)
  d$sub <- si[i]
  d$sn <- i
  temp2 <- rbind(temp2, d)
}


for (i in usi){
  camp <- subset(temp2, sub==i)
  # The y-axis indicates the visibility probability of the target

  # red (-1) present the cdt of test bar in the left eye
  g <- ggplot(camp, aes(x=0, y=cdt, color=as.character(test_eye))) +
    geom_point(stat='identity') +
    stat_summary(fun=mean, geom='point', color='black') +
    labs(color='test eye', subtitle=i)
  print(g)
}


stderr <- function(x) sd(x)/sqrt(length(x))
a <- aggregate(x=temp2$cdt, by=temp2['sub'], FUN=mean)

# 被験者ごとの平均プロット
g <- ggplot(temp2, aes(x=sub, y=cdt)) +
  stat_summary(fun=mean, geom="point") +
  stat_summary(aes(sub), fun.data=mean_se, geom="errorbar", size=0.5, width=0.1) +
  geom_hline(yintercept=mean(temp2$cdt), color='red', lty='dashed') +
  annotate("rect", xmin=0, xmax=length(si)+1, ymin=mean(temp2$cdt)-stderr(a$x), ymax=mean(temp2$cdt)+stderr(a$x), alpha=.3, fill="red") +
  theme(text = element_text(size = 20))

g
