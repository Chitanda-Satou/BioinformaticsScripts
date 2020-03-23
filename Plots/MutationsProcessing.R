library(maftools)
library(tidyverse)

# Make MAF from ANNOVAR's TXTs ----------------------------------------------------------------------
annovar.f <- list.files(path='annovar', full.names=TRUE)
annovar.maf.df <- annovarToMaf(annovar.f)
annovar.maf <- read.maf(annovar.maf.df)

# If clincial data given: ----------------------------------------------------------------------
annovar.f <- list.files(path='annovar', full.names=TRUE)
annovar.maf.df <- annovarToMaf(annovar.f)
annovar.maf <- read.maf(annovar.maf.df, clinicalData=clinic.df)

# Oncoprint ----------------------------------------------------------------------
oncoplot(annovar.maf, clinicalFeatures=c("Gender", "Location", "Surgery")
         , showTumorSampleBarcodes=TRUE, draw_titv=TRUE
         , top=50)

# titv --------------------------------------------------------------------


total.titv <- titv(annovar.maf, useSyn=TRUE)

total.titv.df <- total.titv$fraction.contribution
total.titv.df <- gather(total.titv.df, key='Mutation', value='Fractions', -Tumor_Sample_Barcode)
# Add some group factors, just like:
total.titv.df$Group <- str_remove(total.titv.df$Tumor_Sample_Barcode, '.+_')
total.titv.df$Group <- if_else(total.titv.df$Group == 'T1', 'Pre', 'Post')
total.titv.df$Group <- factor(total.titv.df$Group, levels=c('Pre', 'Post'))

# Make a specific order, just like:
total.titv.df %>% arrange(Mutation, desc(Fractions))
total.titv.df %>% arrange(Mutation, desc(Fractions)) %>% filter(Group == 'Pre')
total.titv.df %>% arrange(Mutation, desc(Fractions)) %>% filter(Group == 'Pre') %>% .$Tumor_Sample_Barcode
total.titv.df %>% 
    arrange(Mutation, desc(Fractions)) %>% 
    filter(Group == 'Pre') %>% 
    .$Tumor_Sample_Barcode %>%
    as.character() %>% 
    unique() -> tmp.pre.order

tmp.pre.order %>% str_replace('_T1', "_T2") -> tmp.post.order

total.titv.df$Tumor_Sample_Barcode <- factor(
  total.titv.df$Tumor_Sample_Barcode
  , levels=c(tmp.pre.order, tmp.post.order)
)

p <- ggbarplot(
  total.titv.df
  , x='Tumor_Sample_Barcode'
  , y='Fractions'
  , ylab='Fractions (%)'
  , fill='Mutation'
  , color='Mutation'
  , x.text.angle=90
  , palette='Set2'
  , font.x=15, font.y=15, font.tickslab=10
)

pdf('figures/01.titv.pdf', width=6, height=8)
facet(p, nrow=2, facet.by='Group', scales='free_x')
dev.off()

pdf('figures/01.titv.mean.pdf', width=5, height=8)
ggbarplot(
  total.titv.df %>% group_by(Group, Mutation) %>% summarise(Fractions=mean(Fractions))
  , x='Group'
  , y='Fractions'
  , ylab='Fractions (%)'
  , fill='Mutation'
  , color='Mutation'
  , palette='Set2'
  , font.x=15, font.y=15, font.tickslab=10
)
dev.off()

