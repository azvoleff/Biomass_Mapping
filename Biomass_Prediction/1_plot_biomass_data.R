#!/usr/bin/Rscript
# Plots descriptive statistics from the biomass survey data.

library(ggplot2)

DPI <- 300
#WIDTH <- 8.33
#HEIGHT <- 5.53
WIDTH <- 6.5
HEIGHT <- 4

trees <- read.csv("Data/Trees.csv", skip=1)
canopy <- read.csv("Data/Canopy.csv", skip=1)

trees$ID.Plot <- factor(trees$ID.Plot)
trees$ID.Strata <- factor(trees$ID.Strata)
trees$ID.Row <- factor(trees$ID.Row)
save(trees, file="Data/tree_data.Rdata")

qplot(DBH, data=trees)
ggsave("tree_dbh.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(Height, data=trees)
ggsave("tree_height.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Strata, Height, geom="boxplot", data=trees,
    ylab="Height (meters)", xlab="Strata")
ggsave("tree_height_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)
qplot(ID.Row, Height, geom="boxplot", data=trees,
    ylab="Height (meters)", xlab="Row")
ggsave("tree_height_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(ID.Strata, DBH, geom="boxplot", data=trees,
    ylab="Diameter at Breast Height (cm)", xlab="Strata")
ggsave("tree_dbh_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)
qplot(ID.Row, DBH, geom="boxplot", data=trees,
    ylab="Diameter at Breast Height (cm)", xlab="Row")
ggsave("tree_dbh_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)

canopy$ID.Plot <- factor(canopy$ID.Plot)
canopy$ID.Strata <- factor(canopy$ID.Strata)
canopy$ID.Row <- factor(canopy$ID.Row)
save(canopy, file="Data/canopy_data.Rdata")

qplot(ID.Strata, Overstory.Density, geom="boxplot", data=canopy)
ggsave("canopy_density_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)
qplot(ID.Row, Overstory.Density, geom="boxplot", data=canopy)
ggsave("canopy_density_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(Height, DBH, colour=ID.Strata, data=trees)
ggsave("dbh_vs_height.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(Species, geom="histogram", data=trees, ylab="Frequency")
ggsave("tree_species.png", width=WIDTH, height=HEIGHT, dpi=DPI)

p <- qplot(Species, geom="histogram", facets=.~ID.Strata, data=trees,
    ylab="Frequency")
#p + theme(axis.text.x=element_text(size=10))
#ggsave("tree_species_strata.png", width=12, height=5, dpi=DPI)
p + theme(axis.text.x=element_text(size=8))
ggsave("tree_species_strata.png", width=WIDTH, height=HEIGHT, dpi=DPI)

p <- qplot(Species, geom="histogram", facets=.~ID.Row, data=trees,
    ylab="Frequency")
#p + theme(axis.text.x=element_text(angle=90, hjust=1, size=8))
#ggsave("tree_species_row.png", width=12, height=5, dpi=DPI)
p + theme(axis.text.x=element_text(angle=90, hjust=1, size=6))
ggsave("tree_species_row.png", width=WIDTH, height=HEIGHT, dpi=DPI)
