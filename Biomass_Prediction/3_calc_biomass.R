#!/usr/bin/Rscript

require("ggplot2")

DPI <- 300
#WIDTH <- 8.33
#HEIGHT <- 5.53
WIDTH <- 6.5
HEIGHT <- 4
load("tree_data.Rdata")

trees <- cbind(trees, CBH=pi*trees$DBH)
trees <- cbind(trees, basal_area=pi*(trees$DBH/2)^2)

# Source: B. S. Rana, S. P. Singh, and R. P. Singh, “Biomass and Productivity 
# of Central Himalayan Sal (Shorea robusta) Forest,” Tropical Ecology 29, no. 
# 2 (1988): 1-7.
# In this source, CBH was measured at 1.37 meters
# Bole biomass = -2.832 + 1.976*CBH
trees <- cbind(trees, kg_bole=exp(-2.832 + 1.976*log(trees$CBH)))
# Branch biomass = -2.037 + 2.501*CBH
# TODO: These coefficients are taken directly from the paper, but they are 
# clearly wrong. For now use only the total biomass equation, as it appears to 
# be correct.
trees <- cbind(trees, kg_branch=exp(-2.037 + 2.501*log(trees$CBH)))
# Twig biomass = -2.688 + 1.463*CBH
trees <- cbind(trees, kg_twig=exp(-2.688 + 1.463*log(trees$CBH)))
# Foliage biomass = -1.736 + 1.175*CBH
trees <- cbind(trees, kg_foliage=exp(-1.736 + 1.175*log(trees$CBH)))
# Total biomass = -1.789 + 1.892*CBH
trees <- cbind(trees, kg_total=exp(-1.789 + 1.892*log(trees$CBH)))
plot_biomass_rana <- with(trees, aggregate(kg_total,
        by=list(ID_Plot=ID.Plot, ID.Strata=ID.Strata, ID.Row=ID.Row), sum))
# Convert plot_biomass from kg per plot into metric tons per ha
plot_biomass_rana$x <- plot_biomass_rana$x * (1/1000) * (10000/(20*20))
names(plot_biomass_rana)[4] <- "biomass"

# This calculation is from Table 1 in: Sundriyal, R. C. et al. 1994. Tree 
# structure, regeneration and woody biomass removal in a sub-tropical forest of 
# Mamlay watershed in the Sikkim Himalaya.  Plant Ecology 113 (1):53-63.
trees <- cbind(trees, kg_wood_sundriyal=exp(-1.768 + .945*log((trees$DBH^2)*trees$Height)))
plot_biomass_sundriyal <- with(trees, aggregate(kg_wood_sundriyal,
        by=list(ID_Plot=ID.Plot, ID.Strata=ID.Strata, ID.Row=ID.Row), sum))
# Convert plot_biomass from kg per plot into metric tons per ha
plot_biomass_sundriyal$x <- plot_biomass_sundriyal$x * (1/1000) * (10000/(20*20))
names(plot_biomass_sundriyal)[4] <- "biomass"

#TODO: Choose an allometric equation! For now use Sundriyal et al.
plot_biomass <- plot_biomass_sundriyal

plot_basal_area <- with(trees, aggregate(basal_area, by=list(ID.Plot=ID.Plot, ID.Strata=ID.Strata, ID.Row=ID.Row), sum))
# Convert basal area from sq cm per plot (20 x 20 m) into square meters per ha
plot_basal_area$x <- plot_basal_area$x * (1/10000) * (10000/(20*20))
names(plot_basal_area)[4] <- "basal_area"

plot_results <- merge(plot_basal_area, plot_biomass)

# Add the coordinates of each plot to the plot_results dataframe
plot_locations <- read.csv("averaged_plot_coordinates.csv")
plot_results <- merge(plot_results, plot_locations)

qplot(basal_area, geom="histogram", data=plot_results,
        xlab=expression("Basal Area (m"^2~"ha"^-1*")"))
ggsave("basal_area.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(biomass, geom="histogram", data=plot_results,
        xlab=expression("Live Woody Biomass (metric tons ha"^-1*")"),
        ylab="Frequency")
ggsave("biomass.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Strata, biomass, geom="boxplot", data=plot_results,
        ylab=expression("Live Woody Biomass (metric tons ha"^-1*")"),
        xlab="Strata")
ggsave("biomass_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Strata, basal_area, geom="boxplot", data=plot_results,
        ylab=expression("Basal Area (m"^2~"ha"^-1*")"),
        xlab="Strata")
ggsave("basal_area_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Row, biomass, geom="boxplot", data=plot_results,
        ylab=expression("Live Woody Biomass (metric tons ha"^-1*")"),
        xlab="Row")
ggsave("biomass_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Row, basal_area, geom="boxplot", data=plot_results,
        ylab=expression("Basal Area (m"^2~"ha"^-1*")"),
        xlab="row")
ggsave("basal_area_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)

# Before saving, add in the zero biomass plots hand-digitized from the imagery.
no_biomass_plots <- read.csv("Zero_Woody_Biomass_Plots.csv")
plot_results <- rbind(no_biomass_plots, plot_results)
write.csv(plot_results, file="processed_plot_results.csv", row.names=F)
