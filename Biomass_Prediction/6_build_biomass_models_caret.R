#!/usr/bin/Rscript

require(ggplot2)
require(nnet)
require(caret)

theme_update(theme_grey(base_size=24))
theme_update(theme_grey(base_size=12))
update_geom_defaults("smooth", aes(size=1))
update_geom_defaults("line", aes(size=1))

DPI <- 300
WIDTH <- 9
HEIGHT <- 5.67

# Used to run a multiple regression to predict biomass from IKONOS 
# multispectral data.

load("neural_net_predictors_5x5_textures.Rdata")

in_training <- createDataPartition(biomass_data$biomass, p = .75, list = FALSE, times = 1)
training_data <- biomass_data[in_training,]
testing_data <- biomass_data[-in_training,]

training_control <- trainControl(method="cv")
nnet_fit <- train(biomass ~ ., data=training_data, method = "nnet",
        tuneLength = 10, preProcess = "range", skip = FALSE, trace = FALSE,
        maxit = 2000, linout = TRUE, trControl=training_control)

nnet_fit_prediction <- predict(nnet_fit, testing_data)
r2 <- round(cor(nnet_fit_prediction, testing_data$biomass)**2, 2)
print(r2)
r2int <- round(r2*100,0)

save.image(file=paste("caret_biomass_nnet_", r2int, ".Rdata", sep=""))

validation.nnet <- data.frame(test=testing_data$biomass,
        pred=predict(nnet_fit, testing_data))
validation.nnet <- cbind(validation.nnet,
        Method=rep("Neural Net", length(testing_data$biomass)))
model.lm <- lm(biomass ~ mean_B1 + mean_B2 + mean_B3 + mean_B4 + mean_MSAVI + std_MSAVI,
    data=training_data)
validation.lm <- data.frame(test=testing_data$biomass,
        pred=predict(model.lm, testing_data))
validation.lm <- cbind(validation.lm,
        Method=rep("Linear Model", length(testing_data$biomass)))
validation <- rbind(validation.nnet, validation.lm)
p <- qplot(test, pred, geom="point", colour=Method, shape=Method, data=validation,
    xlab=expression("Testing Data (metric tons ha"^-1*")"),
    ylab=expression("Predictions (metric tons ha"^-1*")"))
p <- p + geom_smooth(method="lm", fullrange=T, se=F)
p <- p + opts(legend.position="right")
p <- p + geom_abline(intercept=0, slope=1, legend=F)
ggsave(paste("caret_biomass_nnet_", r2int, ".png", sep=""), width=WIDTH, height=HEIGHT, dpi=DPI)
