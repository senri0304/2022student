# Title     : TODO
# Objective : TODO
# Created by: Mac1
# Created on: 2020/08/05
# List up files

library(ggplot2)
library(tidyr)

files <- list.files('Stereopsis_supp_Rivalry/data',full.names=T)
f <- length(files)

si <- gsub(".*(..)DATE.*","\\1", files)
n <- length(table(si))
usi <- unique(si)

# Load data and store
temp3 <- read.csv(files[1], stringsAsFactors = F)
temp3$sub <- usi[1]
temp3$sn <- 1
for (i in 2:f) {
  d <- read.csv(files[[i]], stringsAsFactors = F)
  d$sub <- usi[i]
  d$sn <- i
  temp3 <- rbind(temp3, d)
}

#立体視が線形に消失しなかった観察者を除去
temp3 <- subset(temp3, sub!='st')

# cndの正負を均す、水平位置は違うがどちらも提示眼の条件によって交差視差となるので
temp3$cnd <- sqrt(temp3$cnd^2)

# cndの数値をmin of arcに変換, * 3.6 min
temp3$cnd <- temp3$cnd*3.6


#slopes2 <- data.frame(rep(NA, 5), nrow=1)[numeric(0), ]
for (i in usi){
  camp <- subset(temp3, sub==i)
  # The y-axis indicates the visibility probability of the target

  # red symbols (-1) present the cdt of the test bar in the right eye
  g <- ggplot(camp, aes(y=cdt, x=cnd)) +
       # 折れ線グラフを描き入れる
       stat_summary(fun=mean, geom="point", colour="black") +
       stat_summary(fun=mean, geom="line", colour="black") +
       # エラーバーの追加
       stat_summary(fun.data=mean_se, geom="errorbar", size=0.5, width=0.5) +
       # 試行ごとのデータを表示, -1が左眼、1が右眼にターゲットを提示
       geom_point(position=position_jitter(width=0.3, height=0), alpha=0.4, shape=21) +
       # 単回帰分析
#       stat_smooth(method = "lm", formula = y~x, fullrange = T, se = T,alpha=0.1, mapping=aes(y=cdt, x=cnd)) +
#       stat_poly_eq(formula=y~x, aes(label=paste(stat(eq.label), stat(rr.label), stat(f.value.label), stat(p.value.label), sep = "~~~")), parse = TRUE) +
       # グラフの整形
       labs(subtitle=i, color='eye') + ylim(-0.2, max(temp3$cdt)+0.2) + xlim(-0.2, max(temp3$cnd)+0.2)
       xlab('disparity') + theme(text = element_text(size = 20)) +
#       geom_hline(yintercept=a[a$sub==i,2], color='red', lty='dashed')

  print(g)

#  b <- lm(cdt~cnd, camp)
#  sl <- summary.lm(b)
#  slopes2 <- rbind(slopes2, sl$coefficients[2, ])
}

# localで視差が立体視に影響しなかった被験者を除外
##temp3 <- subset(temp3, temp3$sub!=c('kt', 'rh'))
#a <- subset(a, a$sub!=c('kt'))

# 全体平均
g <- ggplot(temp3, aes(x=cnd, y=cdt)) +
            stat_summary(fun=mean, geom="line") +
            stat_summary(fun=mean, geom="point") +
            stat_summary(aes(cnd),#種類ごとに
                         fun.data=mean_se,#mean_seで標準誤差、#mean_cl_normalで95%信頼区間(正規分布)
                         geom="errorbar",
                         size=0.5,#線の太さ
                         width=0.1) +
            xlab('disparity') + theme(text = element_text(size = 20)) +
  stat_summary(aes(color=sub), fun=mean, geom='line', alpha=0.4) +
  stat_summary(aes(color=sub), fun=mean, geom='point', alpha=0.4) +
  geom_hline(yintercept = mean(dat$cdt), size = 0.5, linetype = 1, color = "#5B9BD5") +
  ylim(0, max(dat$cdt)) + ylab('Cumulative disappearance time (sec)')

g


# Mann-Kendall Trend test
library(trend)
library(dplyr)
d.cdt <- arrange(d, cnd)
cdt.ts <- ts(d.cdt$cdt, start=c(1, 1), end=c(6, 5), frequency=6)

x.stl <- stl(cdt.ts,s.window="periodic")
plot(x.stl)

mk <- mk.test(temp3$cdt)

# ANOVA
df <- aggregate(temp3$cdt, by=temp3[c('sub', 'cnd')], FUN=mean)
df_shaped <- pivot_wider(df, names_from=cnd, values_from=x)
df_shaped$sub <- NULL

lm(df_shaped)

#ANOVA <- aov(x~cnd*eccentricity, df)
#summary(ANOVA)

source('anovakun_486.txt')
ANOVA <- anovakun(df_shaped, 'sA', 5, holm=T, peta=T, cm=T)


# 4つの視差条件における立体視の累積消失時間の傾きと多重対応中の単眼像の消失時間の傾きの方向は一致する
# ので，相関係数はプラスになるがはずだが…
colnames(slopes) <- c('Estimate', 'Std. Error', 't value', 'Pr(>|t|)')
colnames(slopes2) <- c('Estimate', 'Std. Error', 't value', 'Pr(>|t|)')
slopes$sub <- si
slopes2$sub <- si
c <- cor(slopes$Estimate, slopes2$Estimate)
plot(slopes$Estimate, slopes2$Estimate,type="n", xlab='立体視の累積消失時間の傾き', ylab='単眼像の累積消失時間の傾き')
text(slopes$Estimate, slopes2$Estimate, labels=slopes$sub)
lines(c(-1, 1), c(0, 0))
lines(c(0, 0), c(-1, 1))


# pre_DMIと0 condition in SSupRのt-test
w <- aggregate(temp3$cdt, by=temp3[c('cnd', 'sub')], FUN=mean)
t_dat <- data.frame(a$x, w$x[w$cnd==0])
colnames(t_dat) <- c('dmi', 'ssup')
t.test(x=t_dat$dmi, y=t_dat$ssup, paired=T)

# effect relative_size
diff <- mean(t_dat$dmi) - mean(t_dat$ssup)
sd_pooled <- (sd(t_dat$dmi) + sd(t_dat$ssup)) / 2
cd <- diff / sd_pooled

# barplot
td <- t_dat %>% pivot_longer(everything(), names_to = c('cnd'))
g <- ggplot(td, aes(x=cnd, y=value)) +
  stat_summary(fun.data=mean_sdl, geom="errorbar", size=0.5, width=0.5) +
  stat_summary(fun=mean, geom='bar')
g


library(tidyr)
tempra <- subset(temp3, select=c('sub', 'cnd', 'cdt'))
tempra2 <- aggregate(cdt ~ sub + cnd, tempra, FUN=mean)
tempra2 <- pivot_wider(tempra2, names_from = 'cnd', values_from = 'cdt')
tempra2 <- subset(tempra2, select=-sub)
library(clinfun)
#jonckheere.test(tempra2, tempra$cnd, alternative="increasing", nperm=1000)

source('anovakun_486.txt')
capture.output(anovakun(tempra2, "sA", 5, holm=T, peta=T, cm=T), file = "Stereopsis_supp_Rivalry/output.txt")


#prediction
plot(x=unique(temp3$cnd),y=c(-2, -2, -2, -2, -2), ylim=c(0, 30), ylab='Cumlative disappearance time (sec)', xlab='disparity (min of arc)', yaxt='n')
abline(a=4, b=0.2)
abline(a=11, b=0, lty='dashed', )


#prediction2
plot(x=unique(temp3$cnd),y=c(-2, -2, -2, -2, -2), ylim=c(0, 30), ylab='Cumlative disappearance time (sec)', xlab='disparity (min of arc)', yaxt='n')
abline(a=11, b=0)


#f ＝√ [(偏相関比の二乗)／(１－(偏相関比の二乗))]
e <- 0.4079
f <- sqrt(((e^2)/(1-e^2)))


# iccは0.1以上だとマルチレベル回帰
# DEが2以上だとマルチレベル回帰
library(lmerTest)
m0 <- lmer(cdt ~ (1|sub), dat=temp3, REML=F)
m0_s <- summary(m0)
ic <- 3.724 / (3.724+5.763)
DE <- 1 + (30 - 1)*ic

# Centering
#temp3$cnd_centered <- temp3$cnd - mean(temp3$cnd)

m1 <- lmer(cdt ~ (1|sub) + cnd, dat=temp3, REML=F)
m1_s <- summary(m1)

m2 <- lmer(cdt ~ (cnd|sub) + cnd, dat=temp3, REML=F)
m2_s <- summary(m2)

m3 <- lmer(cdt ~ (1|sub) + (-1 + cnd|sub) + cnd, dat=temp3, REML=F)
m3_s <- summary(m3)

anova(m0, m1, m2)

g <- ggplot() + ylim(0, max(dat$cdt)) + 
  ylab('Cumulative disappearance time (sec)') + xlab('disparity') + 
  theme(text = element_text(size = 20))
for (i in usi) {
  camp <- subset(temp3, sub==i)
  g <- g + geom_smooth(data=camp, method='lm', alpha=0.2, size=0, span=0.5, mapping=aes(y=cdt, x=cnd, color=sub))
  g <- g + stat_smooth(data=camp, geom='line', method='lm', alpha=0.5, size=0.5, mapping=aes(y=cdt, x=cnd, color=sub))
}
g <- g + geom_abline(intercept=m1@beta[1], slope=m1@beta[2], color="black", linetype=2)
g

g <- ggplot() + ylim(0, max(dat$cdt)) + 
  ylab('Cumulative disappearance time (sec)') + xlab('disparity') + 
  theme(text = element_text(size = 20))
for (i in usi) {
  camp <- subset(temp3, sub==i)
  g <- g + geom_smooth(data=camp, method='lm', alpha=0.2, size=0, span=0.5, mapping=aes(y=cdt, x=cnd, color=sub))
  g <- g + stat_smooth(data=camp, geom='line', method='lm', alpha=0.5, size=0.5, mapping=aes(y=cdt, x=cnd, color=sub))
}
g <- g + geom_abline(intercept=m2@beta[1], slope=m2@beta[2], color="black", linetype=2)
g



library("brms")
m2_sim <- brm(cdt ~ (cnd|sub), data=temp3, prior=NULL, iter=2000, warmup=1000, chains=3)
summary(lph.brm3)
plot(lph.brm3)


# ベースラインと単眼像の消失の差
dat2 <- aggregate(dat$cdt, by=dat[c('sub')], FUN=mean)
dat3 <- subset(temp3, cnd==0.0)
dat3 <- aggregate(dat3$cdt, by=dat3[c('sub')], FUN=mean)
t.test(dat2$x, dat3$x, paired = T)

dat3$x2 <- dat2$x
colnames(dat3) <- c('sub', 'with streo', 'baseline')
dat3 <- pivot_longer(dat3, c('with streo', 'baseline'))
g <- ggplot(dat3, aes(x=name, y=value, group=sub, color=sub)) + 
  geom_point(alpha=0.4) + stat_summary(fun=mean, geom="point") + 
  geom_line() +
  xlab('observer') + ylab('Cumlative disappearance time') + theme(text=element_text(size=14))
g


# 立体視の消失と単眼像の消失の相関
# まず単眼像の消失の傾きを出す
usi2 <- subset(usi, usi!='st')
slopes2 <- data.frame(rep(NA, 5), nrow=1)[numeric(0), ]
for (i in usi2) {
  camp <- subset(temp3, temp3$sub==i)
  b <- lm(cdt~cnd, camp)
  sl <- summary.lm(b)
  slopes2 <- rbind(slopes2, sl$coefficients[2, ])
}
slopes2 <- cbind(slopes2, p.adjust(slopes2[, 4], "holm"))
slopes2 <- cbind(usi2, slopes2)
colnames(slopes2) <- c('ID', 'Estimate', 'Std. Error', 't value', 'Pr(>|t|)', 'adj Pr(>|t|)')

library(gt)
slopes2_gt <- subset(slopes2, select='ID')
slopes2_gt <- cbind(slopes2_gt, round(slopes2[c('Estimate', 'Std. Error', 't value')], 2))

hoge <- round(slopes2[c('Pr(>|t|)', 'adj Pr(>|t|)')], 3)
hoge$`Pr(>|t|)`[which(hoge$`Pr(>|t|)`==0.000)] <- '> 0.001'
hoge$`adj Pr(>|t|)`[which(hoge$`adj Pr(>|t|)`==0.000)] <- '> 0.001'
slopes2_gt <- cbind(slopes2_gt, hoge)

gt(slopes2_gt) %>% tab_source_note(source_note = md("Adjusted by the holm method"))

# slopesとslopes2の傾きの相関
slopes3 <- subset(slopes, ID!='rs'&ID!='st')
cor.test(slopes3$Estimate, slopes2$Estimate)
plot(y=slopes3$Estimate, x=slopes2$Estimate)

