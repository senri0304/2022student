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
temp3$sub <- si[1]
temp3$sn <- 1
for (i in 2:f) {
  d <- read.csv(files[[i]], stringsAsFactors = F)
  d$sub <- si[i]
  d$sn <- i
  temp3 <- rbind(temp3, d)
}

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
            stat_summary(aes(cnd),#種類ごとに
                         fun.data=mean_se,#mean_seで標準誤差、#mean_cl_normalで95%信頼区間(正規分布)
                         geom="errorbar",
                         size=0.5,#線の太さ
                         width=0.1) +
            xlab('disparity') + theme(text = element_text(size = 20)) +
  geom_hline(yintercept=mean(a$x), color='red', lty='dashed') +
  stat_summary(aes(color=sub, label=sub), fun=mean, geom='text', alpha=0.4)

g

# ANOVA
df <- aggregate(temp3$cdt, by=temp3[c('sub', 'cnd')], FUN=mean)
df_shaped <- pivot_wider(df, names_from=cnd, values_from=x)
df_shaped$sub <- NULL

#ANOVA <- aov(x~cnd*eccentricity, df)
#summary(ANOVA)

source('anovakun_485.txt')
ANOVA <- anovakun(df_shaped, 'sA', 5, holm=T, peta=T)


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
