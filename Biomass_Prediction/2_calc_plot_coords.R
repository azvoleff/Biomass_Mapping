#!/usr/bin/Rscript

require("ggplot2")

DPI <- 300
WIDTH <- 8.33
HEIGHT <- 5.53

plots <- read.csv("Data/Biomass_Plots_UTM45N.csv")

# Rename plot ID field to match the field name used in other code
names(plots)[grep("ID_PLOT", names(plots))] <- "ID.Plot"

# One row has coordinates of 0 - eliminate this row. all the UTM45N coordinates 
# should be well over 200000
plots <- plots[plots$X>200000,]
plots <- plots[plots$Y>200000,]
# Also remove rows with questionable data (marked "IGNORE")
plots <- plots[plots$IGNORE!=1,]

###############################################################################
# The location of wach plot was measured up to 5 times (at each corner and in 
# the center).
#
# Convert all the corner measurements to estimates of the center coordinate by 
# adding/subtracting from the UTM45N corner coordinate as necessary.
plots <- cbind(plots, center_X=matrix(0, nrow(plots)), center_Y=matrix(0, nrow(plots)))

NE_rows <- plots$CORNER=="NE"
SE_rows <- plots$CORNER=="SE"
NW_rows <- plots$CORNER=="NW"
SW_rows <- plots$CORNER=="SW"
CE_rows <- plots$CORNER=="CE" # CE is the "center" measurement

plots$center_X[NE_rows] <- plots$X[NE_rows]-10
plots$center_X[SE_rows] <- plots$X[SE_rows]-10
plots$center_X[NW_rows] <- plots$X[NW_rows]+10
plots$center_X[SW_rows] <- plots$X[SW_rows]+10

plots$center_Y[NE_rows] <- plots$Y[NE_rows]-10
plots$center_Y[SE_rows] <- plots$Y[SE_rows]+10
plots$center_Y[NW_rows] <- plots$Y[NW_rows]-10
plots$center_Y[SW_rows] <- plots$Y[SW_rows]+10

plots$center_X[CE_rows] <- plots$X[CE_rows]
plots$center_Y[CE_rows] <- plots$Y[CE_rows]


###############################################################################
# Now calculate the center coordinate of each plot as the mean of all the 
# available estimates.
center_X <- aggregate(plots$center_X, by=list(plots$ID.Plot), mean)
center_Y <- aggregate(plots$center_Y, by=list(plots$ID.Plot), mean)
names(center_X) <- c("ID.Plot", "X")
names(center_Y) <- c("ID.Plot", "Y")
center_coords <- merge(center_X, center_Y)

center_X_range <- aggregate(plots$center_X, by=list(plots$ID.Plot),
        function(X) max(X) - min(X))
center_Y_range <- aggregate(plots$center_Y, by=list(plots$ID.Plot),
        function(Y) max(Y) - min(Y))
center_X_stderr <- aggregate(plots$center_X, by=list(plots$ID.Plot),
        function(X) sd(X)/sqrt(length(X)))
center_Y_stderr <- aggregate(plots$center_Y, by=list(plots$ID.Plot),
        function(Y)  sd(Y)/sqrt(length(Y)))

print(mean(center_X_stderr$x))
print(mean(center_Y_stderr$x))

qplot(center_X_range$x, center_Y_range$x, xlab="Easting Range (meters)", ylab="Northing Range (meters)")
ggsave("plot_position_range.png", width=WIDTH, height=HEIGHT, dpi=DPI)

qplot(center_Y_stderr$x, center_X_stderr$x, xlab="Easting Standard Error (meters)", ylab="Northing Standard Error (meters)")
ggsave("plot_position_stderror.png", width=WIDTH, height=HEIGHT, dpi=DPI)

write.csv(center_coords, file="Data/averaged_plot_coordinates.csv", row.names=F)
