#!/usr/bin/Rscript

require(ggplot2)
require(nnet)

theme_set(theme_grey(base_size=12))
update_geom_defaults("smooth", aes(size=1))
update_geom_defaults("line", aes(size=1))

DPI <- 300
WIDTH <- 9
HEIGHT <- 5.67

# Used to run a multiple regression to predict biomass from IKONOS 
# multispectral data.

load("Data/2010_NDVI_texture_stats_predictors.Rdata")

# Make a table of correlations
# Note that the -2 below is to skip the plot ID column
cor_results <- round(cor(biomass_data)[1,],2)[-2]
cor_tests <- c(1) # biomass is perfectly correlated with itself.
# Start from 3 in below loop to skip the Plot ID and biomass columns
for (variable in biomass_data[3:length(biomass_data)]) {
    cor.signif <- cor.test(biomass_data$biomass, variable)$p.value
    cor_tests <- c(cor_tests, round(cor.signif,4))
}
write.csv(cbind(cor_results, cor_tests), file="Data/cor_data_biomass_with_training.csv")

rescale <- function(data_matrix, starting_col=1) {
    for (col_num in starting_col:length(data_matrix)) {
        col_min <- min(data_matrix[col_num])
        col_range <- max(data_matrix[col_num]) - min(data_matrix[col_num])
        # Store the location of the minimum values so they can be later set to  
        # zero (otherwise they would be NAs due to divide by zero errors
        min_values <- data_matrix[col_num] == col_min
        data_matrix[col_num] <- (data_matrix[col_num] - col_min)/col_range
        data_matrix[col_num][min_values] <- 0
    }
    return(data_matrix)
}

# The function below gives the band math to rescale the spectral data in ENVI 
# so that it can be used to make predictions from the neural network.
rescale_band_math <- function(data_matrix, starting_col=1) {
    band_math_exp <- c()
    n <- 1
    for (col_num in starting_col:length(data_matrix)) {
        col_min <- min(data_matrix[col_num])
        col_range <- max(data_matrix[col_num]) - min(data_matrix[col_num])
        # Add a very small amount to col_min to avoid divide by zero errors
        #col_min <- col_min + .00000001*col_range
        band_math_exp <- c(band_math_exp, paste("(B", n, " - ", col_min, ") / ", col_range, sep=""))
        n <- n + 1
    }
    return(band_math_exp)
}
write.csv(rescale_band_math(biomass_data, starting_col=2), file="Data/rescale_band_math.txt", row.names=FALSE)

num_iter <- 1000
saved_data <- biomass_data
biomass_data <- rescale(biomass_data, starting_col=2)
best_r2 <- 0
best_rmse <- 99999999999
pb <- txtProgressBar(style=3)
for (n in 1:num_iter) {
    setTxtProgressBar(pb, n/num_iter)
    samp <- sample(1:nrow(biomass_data), floor(.75*nrow(biomass_data)))
    training_data <- biomass_data[samp,]
    testing_data <- biomass_data[-samp,]
    nnet_fit <- nnet(biomass ~ ., size=17, data=training_data, maxit=1000,
            linout=TRUE, skip=FALSE, decay=.007, trace=FALSE)
    nnet_fit_pred <- predict(nnet_fit, testing_data, type="raw")
    nnet_fit_pred_resid <- testing_data$biomass - nnet_fit_pred 
    nnet_fit.corr.training <- cor(nnet_fit_pred, testing_data$biomass)
    r2 <- nnet_fit.corr.training**2
    rmse <- round(sqrt(mean(nnet_fit_pred_resid**2)),2)
    #if ((r2 > best_r2) & (sd(nnetfit_pred) > 10) & (min(nnet_fit_pred)>-100) & (max(nnet_fit_pred)<1500)) {
    #if (rmse < best_rmse) {
    if ((rmse < best_rmse) & (min(nnet_fit_pred)>-100) & (max(nnet_fit_pred)<1500)) {
        best_r2 <- r2
        best_rmse <- rmse
        best_nnet_fit <- nnet_fit
        best_nnet_fit_samp <- samp
    }
}
close(pb)

training_data <- biomass_data[best_nnet_fit_samp,]
testing_data <- biomass_data[-best_nnet_fit_samp,]
best_nnet_fit_pred <- predict(best_nnet_fit, testing_data)
best_nnet_fit_pred_resid <- testing_data$biomass - best_nnet_fit_pred 
best_nnet_fit_r2 <- round(cor(best_nnet_fit_pred, testing_data$biomass)**2, 2)
rmse <- round(sqrt(mean(best_nnet_fit_pred_resid**2)),2)
message(paste("Best net r^2 = ", best_nnet_fit_r2, ", rmse = ", rmse, sep=""))

validation.nnet <- data.frame(test=testing_data$biomass,
        pred=predict(best_nnet_fit, testing_data))
validation.nnet <- cbind(validation.nnet,
        Method=rep("Neural Net", length(testing_data$biomass)))
model.lm <- lm(biomass ~ mean_B1 + mean_B2 + mean_B3 + mean_B4 + mean_MSAVI + std_MSAVI,
    data=training_data)
best_nnet_fit_r2int <- round(best_nnet_fit_r2*100, 0)
validation.lm <- data.frame(test=testing_data$biomass,
        pred=predict(model.lm, testing_data))
validation.lm <- cbind(validation.lm,
        Method=rep("Linear Model", length(testing_data$biomass)))
validation <- rbind(validation.nnet, validation.lm)

best_nnet_fit_r2int <- round(best_nnet_fit_r2*100, 0)
save.image(file=paste("biomass_nnet_", best_nnet_fit_r2int, ".Rdata", sep=""))

p <- qplot(test, pred, geom="point", colour=Method, shape=Method, data=validation,
    xlab=expression("Testing Data (metric tons ha"^-1*")"),
    ylab=expression("Predictions (metric tons ha"^-1*")"))
p <- p + geom_smooth(method="lm", fullrange=T, se=F)
p <- p + opts(legend.position="right")
p <- p + geom_abline(intercept=0, slope=1, legend=F)
ggsave(paste("biomass_nnet_", best_nnet_fit_r2int, ".png", sep=""), width=WIDTH, height=HEIGHT, dpi=DPI)

p <- qplot(test, pred-test, geom="point", colour=Method, shape=Method, data=validation,
    xlab=expression("Testing Data (metric tons ha"^-1*")"),
    ylab=expression("Residual (metric tons ha"^-1*")"))
p <- p + geom_smooth()
p <- p + geom_abline(intercept=0, slope=0, legend=F)
p <- p + opts(legend.position="right")
ggsave(paste("biomass_nnet_", best_nnet_fit_r2int, "_resid.png", sep=""), width=WIDTH, height=HEIGHT, dpi=DPI)
