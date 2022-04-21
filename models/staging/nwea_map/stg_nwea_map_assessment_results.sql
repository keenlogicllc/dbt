
select
    district__state_i_d                                      as district_state_id,
    district_name                                            as local_education_agency_name,
    school_name                                              as school_name,
    split(split(term_name, "-")[OFFSET(0)], " ")[OFFSET(0)]  as term_name,
    split(term_name, "-")[OFFSET(1)]                         as school_year,
    student_i_d                                              as student_unique_id,
    student__state_i_d                                       as student_state_id,
    subject                                                  as subject,
    REPLACE(course, 'Math K-12', 'Mathematics')              as course,
    cast(growth_measure_y_n as BOOL)                         as is_growth_measure,
    norms_reference_data	                                 as norms_reference_data,
    test_i_d                                                 as test_id,
    test_type                                                as test_type,
    test_name                                                as test_name,
    cast(parse_date('%m/%d/%Y', test_start_date) as STRING)  as test_start_date,
    SAFE_CAST(test_duration_minutes as int64)                as test_duration_minutes,
    SAFE_CAST(test_r_i_t_score as int64)                     as test_rit_score,
    SAFE_CAST(test_percentile as int64)                      as test_percentile,
    SAFE_CAST(percent_correct as int64)                      as percent_correct,
    SAFE_CAST(fall_to_winter_projected_growth as int64)      as fall_to_winter_projected_growth,
    SAFE_CAST(fall_to_winter_observed_growth as int64)       as fall_to_winter_observed_growth,
    if(
        CONTAINS_SUBSTR(fall_to_winter_met_projected_growth, "Yes"),
        TRUE,
        FALSE
    )                                                        as met_fall_to_winter_projected_growth,
    goal1_name                                               as goal1_name,
    goal1_adjective                                          as goal1_adjective,
    goal1_rit_score                                          as goal1_rit_score,
    goal2_name                                               as goal2_name,
    goal2_adjective                                          as goal2_adjective,
    goal2_rit_score                                          as goal2_rit_score,
    goal3_name                                               as goal3_name,
    goal3_adjective                                          as goal3_adjective,
    goal3_rit_score                                          as goal3_rit_score,
    goal4_name                                               as goal4_name,
    goal4_adjective                                          as goal4_adjective,
    goal4_rit_score                                          as goal4_rit_score
from {{ source('staging', 'base_nwea_map_assessment_results') }}
