# written by Liangying, 11/22/2022

#install.packages('tidyverse')
#install.packages('R.matlab')
#install.packages("lme4")
#install.packages("broom.mixed")
#install.packages("abind")
#install.packages("lmerTest")
library(R.matlab)
library(lme4)
library(tidyverse)
library(broom.mixed)
library(abind)
library(lmerTest)  # this package help return the p-values from lmer models!

#------------------------------Data Read---------------------------------------------------------
load( "D:/brainbnu/VTC/Data_Regression/Data_Regression_sham.RData")

Behav = unlist(Data_Regression$Regression[1])
EEG = Data_Regression$Regression[2]
EEG = array(unlist(EEG),dim = c(2,4001,675))  # convert to 3D array, need to change
EEG_power_cz = Data_Regression$Regression[5]
EEG_power_cz = array(unlist(EEG_power_cz),dim = c(20,4001,675))
EEG_power_fz = Data_Regression$Regression[6]
EEG_power_fz = array(unlist(EEG_power_fz),dim = c(20,4001,675))
Subs = unlist(Data_Regression$Regression[3])

# delete bad subject and prior-cheps timpoints
Behav_sham = Behav[-(675-40+1) : -675]
Subs_sham = Subs[-(675-40+1) : -675]
EEG_sham = EEG[,-1:-2000,-(675-40+1) : -675]
EEG_power_cz_sham = EEG_power_cz[,-1:-2000,-(675-40+1) : -675]
EEG_power_fz_sham = EEG_power_fz[,-1:-2000,-(675-40+1) : -675]

load( "D:/brainbnu/VTC/Data_Regression/Data_Regression_AI.RData")

Behav_LIFU = unlist(Data_Regression$Regression[1])
Subs_LIFU = unlist(Data_Regression$Regression[3])
EEG = Data_Regression$Regression[2]
EEG_LIFU = array(unlist(EEG),dim = c(2,4001,599))  # convert to 3D array, need to change
EEG_power_cz = Data_Regression$Regression[5]
EEG_power_cz_LIFU = array(unlist(EEG_power_cz),dim = c(20,4001,599))
EEG_power_fz = Data_Regression$Regression[6]
EEG_power_fz_LIFU = array(unlist(EEG_power_fz),dim = c(20,4001,599))

# delete prior-cheps timpoints
EEG_LIFU = EEG_LIFU[,-1:-2000,]
EEG_power_cz_LIFU = EEG_power_cz_LIFU[,-1:-2000,]
EEG_power_fz_LIFU = EEG_power_fz_LIFU[,-1:-2000,]

#------------------------------Data frame---------------------------------------------------------
Subs_LIFU = paste(Subs_LIFU, "LIFU", sep = "_")
Subs_sham = paste(Subs_sham, "sham", sep = "_")
Subs = c(Subs_LIFU, Subs_sham)

Behav = c(Behav_LIFU, Behav_sham)
EEG = abind(EEG_LIFU, EEG_sham, along = 3)
EEG_power_cz = abind(EEG_power_cz_LIFU, EEG_power_cz_sham, along = 3)
EEG_power_fz = abind(EEG_power_fz_LIFU, EEG_power_fz_sham, along = 3)
Group = c(rep(1, length(Subs_LIFU)),rep(0, length(Subs_sham)))

#------------------------------Amplitude - Pain---------------------------------------------------
n_electrode = dim(EEG)[1]   # 直接用dim获取三维矩阵的X y z维度
n_timepoint = dim(EEG)[2]

p_interaction_table = matrix(nrow = n_electrode, ncol = n_timepoint)  # 创建空数组
p_main_table = matrix(nrow = n_electrode, ncol = n_timepoint)  # 创建空数组

for (electrode in 1:n_electrode)
{
  for (timepoint in 1:n_timepoint)
  {
    #electrode = 1;
    #timepoint = 1081;
    
    EEG_electrode_t = EEG[electrode,timepoint,]
    df = data.frame(Behav, EEG_electrode_t, Subs = factor(Subs), Group = factor(Group))
    #head(df)
    
    model = lmer(EEG_electrode_t ~ Behav + Group + Behav:Group + (1 |Subs), df)  # random intercept
    
    p_interaction = anova(model)[3,6]  # interaction effect p value
    p_interaction_table[electrode,timepoint] = p_interaction
    p_main = anova(model)[2,6]  # main effect p value
    p_main_table[electrode,timepoint] = p_main
  }
}


#------------------------------Power - Pain---------------------------------------------------
n_frequency = dim(EEG_power_cz)[1]   
n_timepoint = dim(EEG_power_cz)[2]

p_interaction_table = matrix(nrow = n_frequency, ncol = n_timepoint)  # 创建空数组
p_main_table = matrix(nrow = n_frequency, ncol = n_timepoint)  # 创建空数组

for (frequency in 1:n_frequency)
{
  for (timepoint in 1:n_timepoint)
  {
    #frequency = 18;
    #timepoint = 561;
    
    EEG_frequency_t = EEG_power_cz[frequency,timepoint,]
    df = data.frame(Behav, EEG_frequency_t, Subs = factor(Subs), Group = factor(Group))
    #head(df)
    
    model = lmer(EEG_frequency_t ~ Behav + Group + Behav:Group + (1 |Subs), df)  # random intercept
    
    p_interaction = anova(model)[3,6]  # interaction effect p value
    p_interaction_table[frequency,timepoint] = p_interaction
    p_main = anova(model)[2,6]  # main effect p value
    p_main_table[frequency,timepoint] = p_main
  }
}


p_table = p_interaction_table
p_table = p_main_table
indx = which(p_table == min(p_table[2,]), arr.ind = TRUE)
indx  = which(p_table < 0.001, arr.ind = TRUE)
indx 


# multiple comparison correction
p_table_adjust  <- p.adjust(p_table, method = "fdr", n = length(p_table))
p_table_adjust  = array(p_table_adjust, dim = c(n_frequency,n_timepoint))  

indx  = which(p_table_adjust < 0.05, arr.ind = TRUE)
indx

# Gamma greater than 30(Hz), BETA (13-30Hz), ALPHA (8-12 Hz), THETA (4-8 Hz), and DELTA(less than 4 Hz)

#------------------------------Heatmap p value plot------------------------------------------------

p_table_invert = t(p_table)
p_table_invert = t(p_table_adjust)
p_table_1d = as.vector(p_table_invert)

x_timepoints = rep(1:n_timepoint, time = n_frequency)
y_frequency = replicate(n_timepoint, seq(1,20,1))
y_frequency = as.vector(t(y_frequency))
fill_p = p_table_1d
df_heatmap = data.frame(x_timepoints, y_frequency, fill_p)
options(repr.plot.width = 1, repr.plot.height = 1)

str(df_heatmap)

p_heatmap <- ggplot(data = df_heatmap, mapping = aes(x_timepoints, factor(y_frequency), fill = fill_p))+
  #geom_tile()+
  #scale_fill_gradient(low="red", high="white") 
  geom_raster()+
  scale_fill_distiller(palette = "Spectral", direction = 1, breaks = c(0.05, 0.50, 0.99), labels = c("0.05", "0.50", "1.00"))+
  scale_x_continuous(expand = c(0,0), breaks = c(1,500,1000,1500,2000), labels = c("0", "500", "1000", "1500", "2000"))+
    scale_y_discrete(expand = c(0,0),breaks = c(1,5,10,15,20),labels = c("2","4","10","25","60"))+
  labs(x = "Time(ms)", y = "Frequency", fill = "p value")+
  theme_light()+
  theme(axis.text.x = element_text(size = 10, face = "bold"),
        axis.text.y = element_text(size = 10, face = "bold"),
        # axis.ticks.y = element_blank(),
        axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 7)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
        aspect.ratio = 1 / 2.5)
p_heatmap




#--------------------------------------LME plot----------------------------------------------------------
model_coef = summary(model)
str(model_coef)
coef_fixed = model_coef$coefficients   # fixed effects
Intercept_sham = coef_fixed[1,1]
Intercept_LIFU = coef_fixed[3,1] + Intercept_sham
slope_sham = coef_fixed[2,1]
slope_LIFU = coef_fixed[4,1] + slope_sham

Intercept = c(Intercept_sham, Intercept_LIFU)
slope = c(slope_sham, slope_LIFU)
g = c(0,1)
df_coef_fixed <- data.frame(Intercept, slope, Group = factor(g))     # based on the same Group to facet


#-----------Facet plot is better----------------------

Group_names <- list('0' = "Sham",
                    '1' = "LIFU")
Group_labeller <- function(variable, value)
{
  return(Group_names[value])
}

model_plot <- ggplot(data = df, mapping = aes(Behav, EEG_electrode_t, color = Subs))+
                geom_point()+
                facet_wrap(~ Group, scale = "fixed", labeller = Group_labeller)+
                geom_abline(data = df_coef_fixed, aes(intercept = Intercept, slope = slope) , size = 1, color = "darkcyan")+   
                labs(x = "Pain Score", y = "power")+
                theme(legend.text = element_text(size = 10),
                      legend.title = element_text(size = 11,face = "bold"),
                      axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 7)),
                      axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)),
                      strip.text = element_text(face = "bold", size = 12))

model_plot



model_plot <- ggplot(data = df, mapping = aes(Behav, EEG_electrode_t, color = Group))+ 
  geom_point()+
  geom_abline(data = df_coef_fixed, aes(intercept = Intercept, slope = slope, color = Group))+
  labs(x = "Pain Score", y = "Amplitude", color = "Group")+
  scale_color_manual(labels = c("Sham","LIFU"), values = c("grey", "red"))+
  theme(legend.text = element_text(size = 10),
        legend.title = element_text(size = 11,face = "bold"),
        axis.title.x = element_text(size = 12, face = "bold", margin = margin(t = 7)),
        axis.title.y = element_text(size = 12, face = "bold", margin = margin(r = 10)))

model_plot








