#' @title Generate Interactive Studio with Explanations for the Model
#'
#' @description
#' This tool uses your model, data and new observations, to provide local
#' and global explanations. It generates plots and descriptions in the form
#' of the serverless HTML site, that supports animations and interactivity made with D3.js.
#'
#' Find more details about plots in \href{https://pbiecek.github.io/PM_VEE/}{Predictive Models: Explore, Explain, and Debug}
#'
#' @param object An \code{explainer} created with function \code{DALEX::explain()} or a model to be explained.
#' @param new_observation A new observation with columns that correspond to variables used in the model.
#' @param new_observation_y True label for \code{new_observation}.
#' @param facet_dim Dimensions of the grid. Default is \code{c(2,2)}.
#' @param time Time in ms. Set animation length. Default is \code{500}.
#' @param max_features Maximum number of features to be included in Break Down and SHAP Values plots. Default is \code{10}.
#' @param N Number of observations used for calculation of partial dependency profiles. Default is \code{400}.
#' @param B Number of random paths used for calculation of SHAP values. Default is \code{15}.
#' @param show_info Verbose progress bar on the console. Default is \code{TRUE}.
#' @param parallel Speed up the computation using \code{parallelMap::parallelMap()}.
#' See \href{https://modeloriented.github.io/modelStudio/articles/vignette_modelStudio.html#parallel-computation}{\bold{vignette}}.
#' @param viewer Default is \code{external} to display in an external RStudio window.
#' Use \code{browser} to display in an external browser or
#' \code{internal} to use the RStudio internal viewer pane for output.
#' @param options Customize \code{modelStudio}. See \code{\link{modelStudioOptions}} and
#' \href{https://modeloriented.github.io/modelStudio/articles/vignette_modelStudio.html#plot-options}{\bold{vignette}}.
#' @param ... Other parameters.
#' @param data Validation dataset, will be extracted from \code{object} if it is an explainer.
#' NOTE: It is best when target variable is not present in the \code{data}.
#' @param y True labels for \code{data}, will be extracted from \code{object} if it is an \code{explainer}.
#' @param predict_function Predict function, will be extracted from \code{object} if it is an \code{explainer}.
#' @param label A name of the model, will be extracted from \code{object} if it is an \code{explainer}.
#'
#' @return An object of the \code{r2d3} class.
#'
#' @importFrom utils head tail setTxtProgressBar txtProgressBar installed.packages
#' @importFrom stats aggregate predict quantile
#' @importFrom grDevices nclass.Sturges
#'
#' @references
#'
#' \itemize{
#'   \item Wrapper for the function is implemented in \href{https://modeloriented.github.io/DALEX/}{\bold{DALEX}}
#'   \item Feature Importance, Ceteris Paribus, Partial Dependency and Accumulated Dependency plots
#' are implemented in \href{https://modeloriented.github.io/ingredients/}{\bold{ingredients}}
#'   \item Break Down and SHAP Values plots are implemented in \href{https://modeloriented.github.io/iBreakDown/}{\bold{iBreakDown}}
#' }
#'
#' @seealso
#' Python wrappers and more can be found in \href{https://modeloriented.github.io/DALEXtra/}{\bold{DALEXtra}}
#'
#' @examples
#' library("modelStudio")
#'
#' # ex1 classification
#'
#' model_titanic_glm <- glm(survived ~.,
#'                          data = DALEX::titanic_imputed,
#'                          family = "binomial")
#'
#' explain_titanic_glm <- DALEX::explain(model_titanic_glm,
#'                                       data = DALEX::titanic_imputed[,-8],
#'                                       y = DALEX::titanic_imputed[,8],
#'                                       label = "glm",
#'                                       verbose = FALSE)
#'
#' new_observations <- DALEX::titanic_imputed[1:2,]
#' rownames(new_observations) <- c("Lucas","James")
#'
#' modelStudio(explain_titanic_glm, new_observations,
#'             N = 100, B = 10, show_info = FALSE)
#'
#' \donttest{
#' # ex2 regression
#'
#' model_apartments <- glm(m2.price ~. ,
#'                         data = DALEX::apartments)
#'
#' explain_apartments <- DALEX::explain(model_apartments,
#'                                      data = DALEX::apartments[,-1],
#'                                      y = DALEX::apartments[,1],
#'                                      verbose = FALSE)
#'
#' new_apartments <- DALEX::apartments[1:2,]
#' rownames(new_apartments) <- c("ap1","ap2")
#'
#' modelStudio(explain_apartments, new_apartments,
#'             facet_dim = c(2, 3), time = 1000,
#'             show_info = FALSE)
#'
#' modelStudio(explain_apartments, show_info = FALSE)
#' modelStudio(explain_apartments, new_observation = new_apartments,
#'                                 new_observation_y = DALEX::apartments[1:2, 1],
#'                                 show_info = FALSE)
#' }
#'
#' @export
#' @rdname modelStudio
modelStudio <- function(object, ...) {
  UseMethod("modelStudio")
}

#' @export
#' @rdname modelStudio
modelStudio.explainer <- function(object,
                                  new_observation = NULL,
                                  new_observation_y = NULL,
                                  facet_dim = c(2,2),
                                  time = 500,
                                  max_features = 10,
                                  N = 400,
                                  B = 15,
                                  show_info = TRUE,
                                  parallel = FALSE,
                                  options = modelStudioOptions(),
                                  viewer = "external",
                                  ...) {

  explainer <- object

  modelStudio.default(object = explainer$model,
                      data = explainer$data,
                      y = explainer$y,
                      predict_function = explainer$predict_function,
                      label = explainer$label,
                      new_observation = new_observation,
                      new_observation_y = new_observation_y,
                      facet_dim = facet_dim,
                      time = time,
                      max_features = max_features,
                      N = N,
                      B = B,
                      show_info = show_info,
                      parallel = parallel,
                      options = options,
                      viewer = viewer,
                      ...)
}

#' @export
#' @rdname modelStudio
modelStudio.default <- function(object,
                                data,
                                y,
                                predict_function = predict,
                                label = class(model)[1],
                                new_observation = NULL,
                                new_observation_y = NULL,
                                facet_dim = c(2,2),
                                time = 500,
                                max_features = 10,
                                N = 400,
                                B = 15,
                                show_info = TRUE,
                                parallel = FALSE,
                                options = modelStudioOptions(),
                                viewer = "external",
                                ...) {

  model <- object

  if (is.null(new_observation)) {
    message("`new_observation` argument is NULL. Observations needed to calculate local explanations are taken at random from the data.")
    new_observation <- ingredients::select_sample(data, 3)
  }

  ## safeguard
  new_observation <- as.data.frame(new_observation)
  data <- as.data.frame(data)

  ## get proper names of features that arent target
  is_y <- sapply(data, function(x) identical(x, y))
  potential_variable_names <- names(is_y[!is_y])
  variable_names <- intersect(potential_variable_names, colnames(new_observation))
  ## get rid of target in data
  data <- data[!is_y]


  obs_count <- dim(new_observation)[1]
  obs_data <- new_observation
  obs_list <- list()

  ## later update progress bar after all explanation functions
  if (show_info) pb <- txtProgressBar(0, obs_count + 5, style = 3)

  ## count only once
  fi <- try_catch(
    ingredients::feature_importance(
        model, data, y, predict_function, variables = variable_names, B = B),
    "ingredients::feature_importance", "", show_info)

  if (show_info) setTxtProgressBar(pb, 1)

  which_numerical <- sapply(data[,, drop = FALSE], is.numeric)

  ## because aggregate_profiles calculates numerical OR categorical
  if (all(which_numerical)) {
    pd_n <- try_catch(
      ingredients::partial_dependency(
          model, data, predict_function, variable_type = "numerical", N = N),
      "ingredients::partial_dependency", "numerical", show_info)
    if (show_info) setTxtProgressBar(pb, 2)
    pd_c <- NULL
    ad_n <- try_catch(
      ingredients::accumulated_dependency(
          model, data, predict_function, variable_type = "numerical", N = N),
      "ingredients::accumulated_dependency", "numerical", show_info)
    if (show_info) setTxtProgressBar(pb, 4)
    ad_c <- NULL
  } else if (all(!which_numerical)) {
    pd_n <- NULL
    pd_c <- try_catch(
      ingredients::partial_dependency(
          model, data, predict_function, variable_type = "categorical", N = N),
      "ingredients::partial_dependency", "categorical", show_info)
    if (show_info) setTxtProgressBar(pb, 3)
    ad_n <- NULL
    ad_c <- try_catch(
      ingredients::accumulated_dependency(
          model, data, predict_function, variable_type = "categorical", N = N),
      "ingredients::accumulated_dependency", "categorical", show_info)
    if (show_info) setTxtProgressBar(pb, 5)
  } else {
    pd_n <- try_catch(
      ingredients::partial_dependency(
        model, data, predict_function, variable_type = "numerical", N = N),
      "ingredients::partial_dependency", "numerical", show_info)
    if (show_info) setTxtProgressBar(pb, 2)
    pd_c <- try_catch(
      ingredients::partial_dependency(
        model, data, predict_function, variable_type = "categorical", N = N),
      "ingredients::partial_dependency", "categorical", show_info)
    if (show_info) setTxtProgressBar(pb, 3)
    ad_n <- try_catch(
      ingredients::accumulated_dependency(
        model, data, predict_function, variable_type = "numerical", N = N),
      "ingredients::accumulated_dependency", "numerical", show_info)
    if (show_info) setTxtProgressBar(pb, 4)
    ad_c <- try_catch(
      ingredients::accumulated_dependency(
        model, data, predict_function, variable_type = "categorical", N = N),
      "ingredients::accumulated_dependency", "categorical", show_info)
    if (show_info) setTxtProgressBar(pb, 5)
  }

  fi_data <- prepare_feature_importance(fi, max_features, ...)
  pd_data <- prepare_partial_dependency(pd_n, pd_c, variables = variable_names)
  ad_data <- prepare_accumulated_dependency(ad_n, ad_c, variables = variable_names)
  fd_data <- prepare_feature_distribution(data, y, variables = variable_names)
  at_data <- prepare_average_target(data, y, variables = variable_names)

  if (parallel) {
    parallelMap::parallelStart()
    parallelMap::parallelLibrary(packages = loadedNamespaces())

    f <- function(i, model, data, predict_function, label, B, ...) {
      new_observation <- obs_data[i,]

      bd <- try_catch(
        iBreakDown::local_attributions(
          model, data, predict_function, new_observation, label = label),
        "iBreakDown::local_attributions", i, show_info)
      sv <- try_catch(
        iBreakDown::shap(
          model, data, predict_function, new_observation, label = label, B = B),
        "iBreakDown::shap", i, show_info, FALSE)
      cp <- try_catch(
        ingredients::ceteris_paribus(
          model, data, predict_function, new_observation, label = label),
        "ingredients::ceteris_paribus", i, show_info, FALSE)

      bd_data <- prepare_break_down(bd, max_features, ...)
      sv_data <- prepare_shap_values(sv, max_features, ...)
      cp_data <- prepare_ceteris_paribus(cp, variables = variable_names)

      list(bd_data, cp_data, sv_data)
    }

    obs_list <- parallelMap::parallelMap(f, 1:obs_count,
                                         more.args = list(
                                           model = model,
                                           data = data,
                                           predict_function = predict_function,
                                           label = label,
                                           B = B,
                                           ...
                                         ))

    parallelMap::parallelStop()

    if (show_info) setTxtProgressBar(pb, 5 + obs_count)
  } else {
    ## count once per observation
    for(i in 1:obs_count){
      new_observation <- obs_data[i,]

      bd <- try_catch(
        iBreakDown::local_attributions(
          model, data, predict_function, new_observation, label = label),
        "iBreakDown::local_attributions", i, show_info)
      sv <- try_catch(
        iBreakDown::shap(
          model, data, predict_function, new_observation, label = label, B = B),
        "iBreakDown::shap", i, show_info, FALSE)
      cp <- try_catch(
        ingredients::ceteris_paribus(
          model, data, predict_function, new_observation, label = label),
        "ingredients::ceteris_paribus", i, show_info, FALSE)

      if (show_info) setTxtProgressBar(pb, 5 + i)

      bd_data <- prepare_break_down(bd, max_features, ...)
      sv_data <- prepare_shap_values(sv, max_features, ...)
      cp_data <- prepare_ceteris_paribus(cp, variables = variable_names)

      obs_list[[i]] <- list(bd_data, cp_data, sv_data)
    }
  }

  names(obs_list) <- rownames(obs_data)

  between <- " - "
  if (is.null(new_observation_y)) new_observation_y <- between <- ""
  drop_down_data <- as.data.frame(cbind(rownames(obs_data),
                                        paste0(rownames(obs_data), between, new_observation_y)))
  colnames(drop_down_data) <- c("id", "text")

  footer_text <- paste0("Site built with modelStudio v", installed.packages()["modelStudio","Version"],
                        " on ", format(Sys.time(), usetz = FALSE))

  options <- c(list(time = time,
                    model_name = label,
                    variable_names = variable_names,
                    facet_dim = facet_dim,
                    footer_text = footer_text,
                    drop_down_data = jsonlite::toJSON(drop_down_data)
                    ), options)

  temp <- jsonlite::toJSON(list(obs_list, fi_data, pd_data, ad_data, fd_data, at_data))

  sizing_policy <- r2d3::sizingPolicy(padding = 10, browser.fill = TRUE)

  model_studio <- r2d3::r2d3(
                    data = temp,
                    script = system.file("d3js/modelStudio.js", package = "modelStudio"),
                    dependencies = list(
                      system.file("d3js/hackHead.js", package = "modelStudio"),
                      system.file("d3js/myTools.js", package = "modelStudio"),
                      system.file("d3js/d3-tip.js", package = "modelStudio"),
                      system.file("d3js/d3-simple-slider.min.js", package = "modelStudio"),
                      system.file("d3js/d3-interpolate-path.min.js", package = "modelStudio"),
                      system.file("d3js/generatePlots.js", package = "modelStudio"),
                      system.file("d3js/generateTooltipHtml.js", package = "modelStudio")
                    ),
                    css = system.file("d3js/modelStudio.css", package = "modelStudio"),
                    options = options,
                    d3_version = "4",
                    viewer = viewer,
                    sizing = sizing_policy,
                    width = facet_dim[2]*(options$w + options$margin_left + options$margin_right),
                    height = 100 + facet_dim[1]*(options$h + options$margin_top + options$margin_bottom)
                  )

  model_studio$x$script <- remove_file_paths(model_studio$x$script, "js")
  model_studio$x$style <- remove_file_paths(model_studio$x$style, "css")

  model_studio
}

#' @noRd
#' @title remove_file_paths
#'
#' @description \code{r2d3} adds comments in html file with direct file paths to dependencies.
#' This function removes them.
#'
#' @param text string
#' @param type js or css to remove other paths

remove_file_paths <- function(text, type = NULL) {

  if (is.null(type)) stop("error in remove_file_paths")

  if (type == "js") {
    text <- gsub(system.file("d3js/modelStudio.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/hackHead.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/myTools.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/d3-tip.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/d3-simple-slider.min.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/d3-interpolate-path.min.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/generatePlots.js", package = "modelStudio"), "", text, fixed = TRUE)
    text <- gsub(system.file("d3js/generateTooltipHtml.js", package = "modelStudio"), "", text, fixed = TRUE)
  } else if (type == "css") {
    text <- gsub(system.file("d3js/modelStudio.css", package = "modelStudio"), "", text, fixed = TRUE)
  }

  text
}

#' @noRd
#' @title try_catch
#'
#' @description This function evaluates expression and returns its value.
#' It returns \code{NULL} and prints \code{warning} if an error occurred.
#'
#' @param expr function
#' @param function_name string
#' @param i iteration/type
#' @param show_info show message about what is calculated
#'
#' @return Valid object or \code{NULL}

try_catch <- function(expr, function_name, i = 1, show_info = TRUE, new = TRUE) {
  tryCatch({
    if(show_info) message(paste0(ifelse(new,"\n",""), "Function ", function_name, " is beeing calculated. (", i, ")"))
    expr
    },
    error = function(e) {
      warning(paste0("Error occurred in ", function_name, " function: ", e$message))
      NULL
  })
}
