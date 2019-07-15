#' @title Generate interactive studio for your model
#'
#' @description
#' The main goal of this function is to connect two local model explainers: Ceteris Paribus and Break Down.
#' It also shows global explainers for your model such as Partial Dependency and Feature Importance.
#'
#' @param x a model to be explained, or an explainer created with function `DALEX::explain()`.
#' @param new_observation a new observation with columns that correspond to variables used in the model.
#' @param max_features maximal number of features to be included in the BreakDown plot. Default value is 10.
#' @param data validation dataset, will be extracted from `x` if it is an explainer.
#' @param y true labels for `data`, will be extracted from `x` if it's an explainer.
#' @param predict_function predict function, will be extracted from `x` if it's an explainer.
#' @param label name of the model. By default it is extracted from the 'class' attribute of the model.
#' @param ... other parameters.
#'
#' @return an object of the `r2d3` class.
#'
#' @references ingredients \url{https://modeloriented.github.io/ingredients/} iBreakDown \url{https://modeloriented.github.io/iBreakDown/}
#'
#' @examples
#' library("dime")
#' library("DALEX")
#'
#' titanic <- na.omit(titanic)
#' set.seed(1313)
#' titanic_small <- titanic[sample(1:nrow(titanic), 500), c(1,2,3,6,7,9)]
#' model_titanic_glm <- glm(survived == "yes" ~ gender + age + fare + class + sibsp,
#'                          data = titanic_small, family = "binomial")
#' explain_titanic_glm <- explain(model_titanic_glm,
#'                                data = titanic_small[,-9],
#'                                y = titanic_small$survived == "yes",
#'                                label = "glm")
#'
#' modelStudio(explain_titanic_glm, new_observation = titanic_small[1,-6])
#'
#' @export
#' @rdname modelStudio
modelStudio <- function(x, ...)
  UseMethod("modelStudio")

#' @export
#' @rdname modelStudio
modelStudio.explainer <- function(x, new_observation,
                                  max_features = 10,
                                  ...) {

  modelStudio.default(x = x$model,
                      new_observation = new_observation,
                      max_features = max_features,
                      data = x$data,
                      y = x$y,
                      predict_function = x$predict_function,
                      label = x$label,
                      ...)
}

#' @export
#' @rdname modelStudio
modelStudio.default <- function(x,
                                new_observation,
                                max_features = 10,
                                data,
                                y,
                                predict_function = predict,
                                label = NULL,
                                ...) {

  if(is.null(label)) label <- class(x)[1]

  breakDown <- iBreakDown::local_attributions(x, data, predict_function, new_observation, label=label)
  ceterisParibus <- ingredients::ceteris_paribus(x, data, predict_function, new_observation, label=label)
  featureImportance <- ingredients::feature_importance(x, data, y, predict_function, ...)

  bdData <- prepareBreakDown(breakDown, ...)
  cpData <- prepareCeterisParibus(ceterisParibus, variables = bdData$variables)
  fiData <- prepareFeatureImportance(featureImportance, ...)

  options <- list(size = 2, alpha = 1, bar_width = 16,
                  cp_title = "Ceteris Paribus Profiles", bd_title = "Break Down",
                  fi_title = "Feature Importance",
                  model_name = label,
                  show_rugs = TRUE)

  temp <- jsonlite::toJSON(list(bdData, cpData, fiData))

  r2d3::r2d3(
    data = temp,
    script = system.file("d3js/modelStudio.js", package = "dime"),
    dependencies = list(
      system.file("d3js/colorsDrWhy.js", package = "dime"),
      system.file("d3js/tooltipD3.js", package = "dime")
    ),
    css = system.file("d3js/themeDrWhy.css", package = "dime"),
    options = options,
    d3_version = "4"
  )
}