# Title     : TODO
# Objective : TODO
# Created by: Mac1
# Created on: 2020/08/05
# List up files

library(ggplot2)
#library(ggpmisc)

files <- list.files('local_stereo/data',full.names=T)
f <- length(files)

si <- gsub(".*(..)DATE.*","\\1", files)
n <- length(table(si))
usi <- unique(si)

# Load data and store
temp <- read.csv(files[1], stringsAsFactors = F)
temp$sub <- si[1]
temp$sn <- 1
for (i in 2:f) {
  d <- read.csv(files[[i]], stringsAsFactors = F)
  d$sub <- si[i]
  d$sn <- i
  temp <- rbind(temp, d)
}

# cndの正負を均す、水平位置は違うがどちらも提示眼の条件によって交差視差となるので
#temp$cnd <- sqrt(temp$cnd^2)

# cndの数値をmin of arcに変換, * 3.6 min
temp$cnd <- temp$cnd*3.6


for (i in usi){
  camp <- subset(temp, sub==i)
  # The y-axis indicates the visibility probability of the target

  #キャンバスを用意して、gに格納
  g <- ggplot(camp, aes(y=cdt, x=cnd)) +
       # 折れ線グラフを描き入れる
       stat_summary(fun=mean, geom="point", colour="black") +
       stat_summary(fun=mean, geom="line", colour="black") +
       # エラーバーの追加
       stat_summary(fun.data=mean_se, geom="errorbar", size=0.5, width=0.5) +
       # 試行ごとのデータを表示, -1が左眼、1が右眼にターゲットを提示
       geom_point(position=position_jitter(width=0.3, height=0), alpha=0.4, shape=21) +
       # 単回帰分析
       stat_smooth(method = "lm", formula = y~x, fullrange = T, se = T,alpha=0.1, mapping=aes(y=cdt, x=cnd)) +
#       stat_poly_eq(formula=y~x, aes(label=paste(stat(eq.label), stat(rr.label), stat(f.value.label), stat(p.value.label), sep = "~~~")), parse = TRUE) +
       # ラベルの整形
       labs(subtitle=i) + ylim(-0.2, 30.2) +
       xlab('disparity') + ylab('stereo loss time') + theme(text = element_text(size = 20))
  print(g)
}


slopes <- data.frame(rep(NA, 5), nrow=1)[numeric(0), ]
for (i in usi) {
  camp <- subset(temp, sub==i)
  b <- lm(cdt~cnd, camp)
  sl <- summary.lm(b)
  slopes <- rbind(slopes, sl$coefficients[2, ])
}
slopes <- cbind(slopes, p.adjust(slopes[, 4], "holm"))
slopes <- cbind(usi, slopes)
colnames(slopes) <- c('ID', 'Estimate', 'Std. Error', 't value', 'Pr(>|t|)', 'adj Pr(>|t|)')


library(gt)
slopes_gt <- subset(slopes, select='ID')
slopes_gt <- cbind(slopes_gt, round(slopes[c('Estimate', 'Std. Error', 't value')], 2))

hoge <- round(slopes[c('Pr(>|t|)', 'adj Pr(>|t|)')], 3)
hoge$`Pr(>|t|)`[which(hoge$`Pr(>|t|)`==0.000)] <- '> 0.001'
hoge$`adj Pr(>|t|)`[which(hoge$`adj Pr(>|t|)`==0.000)] <- '> 0.001'
slopes_gt <- cbind(slopes_gt, hoge)

gt(slopes_gt) %>% tab_source_note(source_note = md("Adjusted by the holm method"))


# 全体平均
g <- ggplot(temp, aes(x=cnd, y=cdt)) +
#  stat_summary(fun=mean, geom="line") +
#  stat_summary(aes(cnd, color=sub),#種類ごとに
#               fun.data=mean_se,#mean_seで標準誤差、#mean_cl_normalで95%信頼区間(正規分布)
#               geom="errorbar",
#               size=0.5,#線の太さ
#               width=0.5, alpha=0.4) +
  stat_summary(aes(color=sub), fun=mean, geom='point', alpha=0.4) +
  xlab('disparity') + ylab('stereo loss time') + theme(text = element_text(size = 24)) +
  stat_summary(aes(color=sub), fun=mean, geom='line', alpha=0.4) + ylim(-0.2, 30.2)

g

library(tidyr)
# ANOVA
df <- aggregate(temp$cdt, by=temp[c('sub', 'cnd')], FUN=mean)
df_shaped <- pivot_wider(df, names_from=cnd, values_from=x)
df_shaped$sub <- NULL

#ANOVA <- aov(x~cnd*eccentricity, df)
#summary(ANOVA)

source('anovakun_486.txt')
capture.output(anovakun(df_shaped, "sA", 4, holm=T, peta=T), file = "output.txt")
