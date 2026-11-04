pkg <- c('devtools', 'dplyr', 'tidyr', 'readr', 'ggplot2', 'plotly', 'scales',
'tibble','lme4', 'lmerTest', 'emmeans', 'sjPlot', 'ggeffects', 'DHARMa', 'ordinal',
'purrr', 'broom')

lapply(pkg, require, character.only = TRUE)

# Df information 
# %Column 1: Trial type, 100 FalseLeft, 200 FalseRight, 300 TrueRight, 400 TrueLeft
# %Column 2: Response 100 = 1, 200 = 2, 300 = 3 etc till 700, No resp = NaN
# %Column 3: Feedback 1 = False, 2 = True
# %Column 5: Response time (seconds)
# %Column 4: Fixation to Stim onset (seconds)


mbc <- read_delim("CleanMisinformationBehaviouralData.csv", delim = ";", show_col_types = FALSE)
colnames(mbc) <- tolower(colnames(mbc))

# =====================================================================================
# Have the political oritantion block assignment here so that I can change it if needed
# ===================================================================================== 


mbc <- mbc%>%
    mutate(polgroup_d= case_when(
        politicalorientation <= 5 ~ 'Left',
        politicalorientation >= 6 ~ 'Right'
    )) %>%
    mutate(polgroup_s = case_when(
        politicalorientation <= 2 | politicalorientation >= 9 ~ 'Extreme',
        politicalorientation > 2 & politicalorientation< 9 ~ 'Moderate'
    ))

mbc %>%
  distinct(identity, polgroup_d, polgroup_s) %>%
  count(polgroup_d, polgroup_s)

# =====================================================================================
# Continuous pre-post fake-sharing tendency
# Using original 1-7 response values instead of binarised share/no-share
# =====================================================================================ù

# Here I lose 8 participants because they don't have a valid post, like they didn't do the 
# condition without the EEG. 

colSums(is.na(mbc))

mbc_long <- bind_rows( #stacks datasets vertically 
    mbc %>% transmute(
        identity, time = 'Pre', condition, itemnum, blocknum, response, politicalorientation, polgroup_d, polgroup_s),
    mbc %>% transmute(
        identity, time = 'Post', condition = condition_post, itemnum = itemnum_post, blocknum = blocknum_post, 
        response = response_post, politicalorientation, polgroup_d, polgroup_s)
) %>% 
    mutate(
        response = as.numeric(response),
        response = ifelse(response == 0, NA, response),
        time = factor(time, levels = c("Pre", "Post")),
        truth = case_when(
            condition %in% c("FalseLeft", "FalseRight") ~ "Fake",
            condition %in% c("TrueLeft", "TrueRight") ~ "True"),
        truth = factor(truth, levels = c ("Fake", "True")),
        politicalorientation = as.numeric(politicalorientation),
        polgroup_d = as.factor(polgroup_d),
        polgroup_s = as.factor(polgroup_s)
    )

colSums(is.na(mbc_long))

mbc_model <- mbc_long %>%
  mutate(
    response = ordered(response),
    time = as.factor(time),
    truth = as.factor(truth),
    polgroup_d = as.factor(polgroup_d),
    identity = as.factor(identity),
    itemnum = as.factor(itemnum)
  )

levels(mbc_model$time)
levels(mbc_model$truth)
levels(mbc_model$polgroup_d)

m_full <- lmer(
  response ~ time * truth * polgroup_d +
    (1 + time * truth | identity) +
    (1 | itemnum),
  data = mbc_long
) 

summary(m_full)
anova(m_full)

#Estimate the mean response for each level of Time, separatedly within each level of truth
emmeans(m_full, ~ time | truth)
pairs(emmeans(m_full, ~ time | truth))

#Estimate the mean response for Pre and POst separatedly for every combination of truth and political group
emmeans(m_full, ~ time | truth * polgroup_d)
# Compare pre and post within every combination of truth and political group
pairs(emmeans(m_full, ~ time | truth * polgroup_d))
contrast(emmeans(m_full, ~ time | truth * polgroup_d) , interaction = c("revpairwise", "revpairwise"), by = "truth")



# # =====================================================================================
# # Prepare the bheavioural for eeg analysis
# # ===================================================================================== 
# So what I want to do is to see whether the change in single item scoring can be predicted
# by theta activity in that specific item. Here let's create the diff score. 


# 1. Align the behavioural data 

pre <- mbc %>%
  transmute(
    identity = as.character(identity),
    itemnum = as.integer(itemnum),
    condition_pre = condition,
    response_pre = na_if(as.numeric(response), 0),
    politicalorientation = as.numeric(politicalorientation),
    polgroup_d = factor(polgroup_d)
  )

post <- mbc %>%
  transmute(
    identity = as.character(identity),
    itemnum = as.integer(itemnum_post),
    condition_post = condition_post,
    response_post = na_if(as.numeric(response_post), 0)
  ) %>%
  filter(!is.na(itemnum))

mbc2 <- pre %>% 
    inner_join(post, by = c("identity", "itemnum"), relationship = "one-to-one") %>%
    mutate(delta = response_post - response_pre, 
           condition = coalesce(condition_pre, condition_post)) %>%
    select(identity, itemnum, condition, response_pre, response_post, delta, politicalorientation, polgroup_d)

#check the matching 
mbc2 %>% 
    count(identity, itemnum) %>%
    filter(n > 1) #should return 0 because there is no > 1

ggplot(mbc2, aes(x = politicalorientation, y = delta, colour = condition)) +
  geom_smooth(method = "lm", se = TRUE) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Political orientation",
    y = "Delta",
    colour = "Condition",
    title = "Delta by political orientation and condition"
  )


# # =====================================================================================
# # Add the EEG to the continous behavioural only for one CSV to see it hereeee
# # ===================================================================================== 

# Manual
  threshold = 1
  eeg <- read_csv(
    file.path("WSingleSubj_FCz_Fz_Cz",
              "TrialNumb_Items8040AllSubjects_misinformation_trials_3Channels5_8_0_075_4Morlet.csv"),
    show_col_types = FALSE
  )
  colnames(eeg) <- tolower(colnames(eeg)) 

  eeg2 <- eeg %>%
    transmute(
        identity = as.character(subject),
        itemnum = as.integer(itemnum),
        feedback = as.numeric(feedback),
        response = as.numeric(response / 100),
        power_fcz = as.numeric(power_fcz),
        power_fz = as.numeric(power_fz),
        power_cz = as.numeric(power_cz),
        feedback_label = case_when( feedback == 1 ~ 'Fake', feedback == 2 ~ 'True'),
        mean_power = rowMeans(eeg[, c("power_fz", "power_fcz", "power_cz")], na.rm = TRUE)) %>%
    group_by(identity) %>% 
        mutate( 
      n_trials = n(),
      n_trials_fake = sum(feedback == 1, na.rm = TRUE),
      n_trials_true = sum(feedback == 2, na.rm = TRUE)) %>%
    ungroup()

    eeg2 <- right_join(eeg2, mbc2, by = c('identity', 'itemnum'), relationship = "one-to-one")

eeg2 %>%
  group_by(identity) %>%
  summarise(
    total_rows = n(),
    rows_with_counts = sum(
      !is.na(n_trials_fake) & !is.na(n_trials_true)
    ),
    rows_passing = sum(
      n_trials_fake >= threshold &
      n_trials_true >= threshold,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  filter(rows_passing == 0)


    eeg2 <- eeg2 %>% filter(n_trials_fake >= threshold, n_trials_true >= threshold) %>%
        mutate(
        delta_label = case_when(
        feedback_label == "Fake" & delta < 0 ~ "Effective",
        feedback_label == "True" & delta > 0 ~ "Effective",

        feedback_label == "Fake" & delta > 0 ~ "Not effective",
        feedback_label == "True" & delta < 0 ~ "Not effective",

        delta == 0 ~ "Nothing",
        TRUE ~ NA_character_))

      # Effect coding
    eeg2 <- eeg2 %>%
        mutate(
        feedback_c = case_when(
            feedback_label == "Fake" ~ -0.5,
            feedback_label == "True" ~  0.5,
            TRUE ~ NA_real_
        ),
        polgroup_dc = case_when(
            polgroup_d == "Left" ~ -0.5,
            polgroup_d == "Right" ~  0.5,
            TRUE ~ NA_real_
        )
    )

m <- anova(lmer(mean_power ~ feedback_c * polgroup_dc + (1 | identity), data = eeg2))
 
anova(lmer(delta ~ mean_power + (1 |identity) + (1 |itemnum), data = eeg2))


#Batch 

eeg_file = c("TrialNumb_Items8040AllSubjects_misinformation_trials_3Channels5_8_0_05_4Morlet.csv",
"TrialNumb_Items8040AllSubjects_misinformation_trials_3Channels5_8_0_075_4Morlet.csv",
"TrialNumb_Items8040AllSubjects_misinformation_trials_3Channels5_8_035_075_4Morlet.csv",
"TrialNumb_Items8040AllSubjects_misinformation_trials_3Channels5_8_05_075_4Morlet.csv")


preproc_eeg <- function(eeg_file, threshold){ 
  eeg <- read_csv(
    file.path("WSingleSubj_FCz_Fz_Cz",
              eeg_file),
    show_col_types = FALSE)
   colnames(eeg) <- tolower(colnames(eeg)) 

  eeg2 <- eeg %>%
    transmute(
        identity = as.character(subject),
        itemnum = as.integer(itemnum),
        feedback = as.numeric(feedback),
        response = as.numeric(response / 100),
        power_fcz = as.numeric(power_fcz),
        power_fz = as.numeric(power_fz),
        power_cz = as.numeric(power_cz),
        feedback_label = case_when( feedback == 1 ~ 'Fake', feedback == 2 ~ 'True'),
        mean_power = rowMeans(eeg[, c("power_fz", "power_fcz", "power_cz")], na.rm = TRUE)) %>%
        mutate(mean_power = if_else(is.nan(mean_power), NA_real_, mean_power)) %>%
        filter(!is.na(mean_power)) %>%
    group_by(identity) %>% 
        mutate( 
      n_trials = n(),
      n_trials_fake = sum(feedback == 1, na.rm = TRUE),
      n_trials_true = sum(feedback == 2, na.rm = TRUE)) %>%
    ungroup()

    eeg2 <- right_join(eeg2, mbc2, by = c('identity', 'itemnum'), relationship = "one-to-one")

    eeg2 <- eeg2 %>% filter(n_trials_fake >= threshold, n_trials_true >= threshold) %>%
        mutate(
        delta_label = case_when(
        feedback_label == "Fake" & delta < 0 ~ "Effective",
        feedback_label == "True" & delta > 0 ~ "Effective",

        feedback_label == "Fake" & delta > 0 ~ "Not effective",
        feedback_label == "True" & delta < 0 ~ "Not effective",

        delta == 0 ~ "Nothing",
        TRUE ~ NA_character_))

      # Effect coding
    eeg2 <- eeg2 %>%
        mutate(
        feedback_c = case_when(
            feedback_label == "Fake" ~ -0.5,
            feedback_label == "True" ~  0.5,
            TRUE ~ NA_real_
        ),
        polgroup_dc = case_when(
            polgroup_d == "Left" ~ -0.5,
            polgroup_d == "Right" ~  0.5,
            TRUE ~ NA_real_))

    return(eeg2)

}

results <- lapply(eeg_file, function(file) {
    
    preprocessed <- preproc_eeg(eeg_file = file, threshold = 1)

    model <- lmer(mean_power ~ feedback_label * polgroup_d + (1 | identity), data = preprocessed)
    model2 <- lmer(delta ~ mean_power + (1 |identity) + (1 |itemnum), data = preprocessed)

    cat(
    "\n\n==========================================\n",
    "FILE:", file, 
    "\nParticipants:", n_distinct(preprocessed$identity),
    "\nLeft:", n_distinct(
      preprocessed$identity[preprocessed$polgroup_d == "Left"]
    ),
    "\nRight:", n_distinct(
      preprocessed$identity[preprocessed$polgroup_d == "Right"]
    ),
    "\nTrials:", nrow(preprocessed),
    "\n==========================================\n"
  )
  print(anova(model))  
  anova_model <- anova(model)

  # Extract the P value from the model 
  p_model <- setNames(anova_model[["Pr(>F)"]], rownames(anova_model))

  cat(
    "\n\n==========================================\n",
    "FILE:", file, 
    "\nParticipants:", n_distinct(preprocessed$identity),
    "\nLeft:", n_distinct(
      preprocessed$identity[preprocessed$polgroup_d == "Left"]
    ),
    "\nRight:", n_distinct(
      preprocessed$identity[preprocessed$polgroup_d == "Right"]
    ),
    "\nTrials:", nrow(preprocessed),
    "\n==========================================\n"
  )
  print(anova(model2)) 
  anova_model2 <- anova(model2) 
  p_model2 <- setNames(anova_model2[["Pr(>F)"]], rownames(anova_model2))

  list(file = file, data = preprocessed, model = model, 
       anova_model = anova_model, p_model = p_model, 
       model2 = model2, anova_model2 = anova_model2, p_model2 = p_model2)
})


## MODEL1
#---------------------------------------------------------------------------
# Collect the p values 
p_values_model <- sapply(results, function(x) x$p_model)
colnames(p_values_model) <- sapply(results, function(x) x$file)

# holm correct them 
holm_p_model <- t(apply(p_values_model, 1, p.adjust, method = "holm"))
holm_p_model

# Fit emmeans to the 4 models 

emmeans_results_model <- lapply(results[2:4], function(x) {
  emm <- emmeans(x$model, ~ feedback_label, var"mean_power")

  list(file = x$file, emmeans = emm,
       political_contrasts = pairs(emmeans(x$model, ~ polgroup_d|feedback_label)),
       feedback_contrasts = pairs(emmeans(x$model, ~ feedback_label|polgroup_d))     
       )
})

# print them 
for (x in emmeans_results_model) {

  cat(
    "\n\n==========================================\n",
    "FILE:", x$file,
    "\n==========================================\n"
  )

  cat("\nEstimated marginal means:\n")
  print(x$emmeans)

  cat("\nLeft versus Right within feedback condition:\n")
  print(x$political_contrasts)

  cat("\nFake versus True within political group:\n")
  print(x$feedback_contrasts)
}


# Collect the p values for feedback
# map_dfr applies a function to every element and then stacks the results in a df 
feedback_results <- purrr::map_dfr(emmeans_results_model,
                                  function(x) {as.data.frame(x$feedback_contrasts) %>% # extracts what I want in a df format
                                  mutate(file = x$file, .before = 1)} # puts the name in the first column
)

# holm correct the feedbacks 
feedback_results <- feedback_results %>%
    group_by(polgroup_d) %>%
    mutate(p_holm = p.adjust(p.value, method="holm")) %>%
    ungroup()
feedback_results 

#Plot stuff 
emm_plot_data <- purrr::map_dfr(emmeans_results_model,
                              function(x){as.data.frame(x$emmeans) %>%
                              mutate(file = x$file, .before = 1)})

emm_plot_data <- emm_plot_data %>%
  mutate(
    window = case_when(
      grepl("_0_075_", file) ~ "0–0.75 s",
      grepl("_035_075_", file) ~ "0.35–0.75 s",
      grepl("_05_075_", file) ~ "0.50–0.75 s",
      TRUE ~ file
    ),
    window = factor(
      window,
      levels = c(
        "0–0.75 s",
        "0.35–0.75 s",
        "0.50–0.75 s"
      )
    )
  )


ggplot(emm_plot_data, aes(x = feedback_label,y = emmean, group = polgroup_d, colour = polgroup_d)) +
  geom_line(position = position_dodge(width = 0.12), linewidth = 0.8) +
  geom_point(position = position_dodge(width = 0.12),size = 2.8) +
  geom_errorbar(aes(ymin = asymp.LCL,ymax = asymp.UCL),
    position = position_dodge(width = 0.12),
    width = 0.08
  ) +
  facet_wrap(~ window, nrow = 1) +
  labs(
    x = "Feedback type",
    y = "Estimated theta power",
    colour = "Political group"
  )


## MODEL2
#---------------------------------------------------------------------------
# Collect the p values 
p_values_model2 <- sapply(results, function(x) x$p_model2)
colnames(p_values_model2) <- sapply(results, function(x) x$file)

# holm correct them 
holm_p_model2 <- t(apply(p_values_model2, 1, p.adjust, method = "holm"))
holm_p_model2

# Fit emmeans to the 4 models 


emmeans_results_model2 <- lapply(results[2:4], function(x) {
  theta_slopes <- emtrends(x$model2, ~ feedback_label, var = "mean_power")

    list(file = x$file, theta_slopes = theta_slopes, slope_comparison = pairs(theta_slopes))
  }
)

#Print 
for (x in emmeans_results_model2) {

  cat(
    "\n\n==========================================\n",
    "FILE:", x$file,
    "\n==========================================\n"
  )

  cat("\nTheta-power slope for each feedback condition:\n")
  print(
    test(x$theta_slopes)
  )

  cat("\nDifference between Fake and True slopes:\n")
  print(
    x$slope_comparison
  )
}



