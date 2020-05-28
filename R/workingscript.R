## BETA DIVERSITY (NMDS AND PERMANOVA)


## READ IN AND PREPARE DATA
if(!require(ggordiplots)) {
  require(devtools)
  devtools::install_github("jfq3/ggordiplots")
  require(ggordiplots)
}
require(vegan)
require(tidyr)
require(dplyr)
require(phyloseq)
require(pairwiseAdonis)
# load locally for now since the GitHub file is huge
load("C:/Users/emily/OneDrive - The Pennsylvania State University/Research/git/soils-micro/data/phyloseq16S_ITS.RData")

set.seed(123)

#### ---- ITS -----

# Add EEA C cycling
# also make sure ADONIS variables are factors
sdITS18 <- sdITS18 %>% 
  mutate(Ccycl = AG + BG + BX + CBH,
         Ncycl = NAG + LAP,
         CNrat = Ccycl / Ncycl,
         Plot = as.factor(Plot),
         Block = as.factor(Block))

## conglomerate OTUs by Phyla and add to metadata
# agglomerate data by Phyla
tg <- tax_glom(psITS18, taxrank = rank_names(psITS18)[2], NArm = TRUE)
# name the phyla
taxa_names(tg) <- tg@tax_table@.Data[,2]
# make a dataframe
df <- as.data.frame(otu_table(tg))
# create relative abundance of Phyla for each sample
dc <- decostand(df, method = "total", MARGIN = 1)
# combine with sample data
sdITS18 <- cbind(dc, sdITS18) 
# remove Plot and Block (not interested in differences)
sdITS18$Plot <- NULL
sdITS18$Block <- NULL
# make sure GrazeTime is ordered
sdITS18$GrazeTime <- factor(sdITS18$GrazeTime, ordered = TRUE,
                            levels = c("PRE", "24H", "1WK", "4WK"))

# statistical testing
dis <- distance(psb, method = "bray")
adonis(dis ~ Treatment * GrazeTime,
       data = sdb, permutations = 999) # all are significant except Interactions
 pairwise.adonis2(dis ~  Treatment * GrazeTime,
                             data = sdb,
                             p.adjust.m = "bon", perm = 1000)

# ordinate
ord <- ordinate(psITS18T, method = "NMDS", distance = "bray", k = 2, 
                trymax = 1000, previousBest = TRUE) 
stressplot(ord, dis) #OK with 2 dimensions
eft <- envfit(ord, env = sdITS18, perm = 1000, na.rm = TRUE)
eft #BG, PEROX, Ascomycota, Basidiomycota, factors: Plot, Block, Treatment


## 1.  get NMDS coordinates from ordination object
coords <- as.data.frame(scores(ord, display = "sites")) %>% 
  # and add grouping variable
  mutate(Treatment = sdITS18$Treatment,
         Time = sdITS18$GrazeTime)

## 2.  get significant envfit objects to plot as arrows
spp <- as.data.frame(scores(eft, display = "vectors")) 
spp$species <- rownames(spp)
# subset to only p < 0.05 vectors to de-clutter 
sigs <- data.frame(eft$vectors$arrows[eft$vectors$pvals < 0.05,])
sigspecies <- rownames(sigs)
# subset
sigspecies <- spp %>% filter(species %in% sigspecies)

## 3. Pull ellipse information using gg_ordiplot package
# save gg_ordiplot object to get ellipse values
plot <-  gg_ordiplot(ord, groups = sdITS18$Treatment, label = FALSE, plot = FALSE)
# get ellipse coordinates
df_ell <- plot$df_ellipse
# get label coordinates for ellipse centers
NMDS.mean <- plot$df_mean.ord
# pull NMDS coordinates
ord.data <- plot$df_ord 

## 4. PLOT BY TREATMENT
## create in ggplot2
ggplot(data = coords, aes(x = NMDS1, y = NMDS2)) + # label axises automatically
  # ELLIPSES
  geom_path(data = df_ell, aes(x = x, y = y, color = Group), show.legend = FALSE) +
  # ORDINATION POINTS
  geom_point(data = coords, aes(x = NMDS1, y = NMDS2, shape = Time, color = Treatment), size = 1) +
  # GROUP NAMES AT ELLIPSE CENTER 
  annotate("text",x = NMDS.mean$x, y = NMDS.mean$y,label=NMDS.mean$Group, size = 5) +
  # ENVFIT ARROWS
  geom_segment(data = si,
               aes(x = 0, xend = NMDS1, y = 0, yend = NMDS2),
               arrow = arrow(length = unit(0.25, "cm")), colour = "grey") +
  # ARROW TEXT
  geom_text(data = si, aes(x = NMDS1, y = NMDS2, label = species),
            size = 3) +
  # SCALE CORRECTLY
  coord_fixed() +
  # THEME
  theme_bw() +
  # CHANGE LEGEND TITLE
  labs(color = "Treatment", shape = "Time")

## 5. PLOT BY GRAZETIME
# save gg_ordiplot object to get ellipse values
plot <-  gg_ordiplot(ord, groups = sdITS18$GrazeTime, label = FALSE, plot = FALSE)
# get ellipse coordinates
df_ell <- plot$df_ellipse
# get label coordinates for ellipse centers
NMDS.mean <- plot$df_mean.ord
# pull NMDS coordinates
ord.data <- plot$df_ord 

## create in ggplot2
ggplot(data = coords, aes(x = NMDS1, y = NMDS2)) + # label axises automatically
  # ELLIPSES
  geom_path(data = df_ell, aes(x = x, y = y, color = Group), show.legend = FALSE) +
  # ORDINATION POINTS
  geom_point(data = coords, aes(x = NMDS1, y = NMDS2, shape = Treatment, color = Time), size = 1) +
  # GROUP NAMES AT ELLIPSE CENTER 
  annotate("text",x = NMDS.mean$x, y = NMDS.mean$y,label=NMDS.mean$Group, size = 5) +
  # ENVFIT ARROWS
  geom_segment(data = si,
               aes(x = 0, xend = NMDS1, y = 0, yend = NMDS2),
               arrow = arrow(length = unit(0.25, "cm")), colour = "grey") +
  # ARROW TEXT
  geom_text(data = si, aes(x = NMDS1, y = NMDS2, label = species),
            size = 3) +
  # SCALE CORRECTLY
  coord_fixed() +
  # THEME
  theme_bw() +
  # CHANGE LEGEND TITLE
  labs(color = "Time", shape = "Treatment")


