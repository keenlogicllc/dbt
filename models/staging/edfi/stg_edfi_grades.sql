
WITH latest_extract AS (

    SELECT
        school_year,
        MAX(date_extracted) AS date_extracted
    FROM {{ source('staging', 'base_edfi_grades') }}
    WHERE is_complete_extract IS TRUE
    GROUP BY 1

),

records AS (

    SELECT base_table.*
    FROM {{ source('staging', 'base_edfi_grades') }} base_table
    LEFT JOIN latest_extract ON base_table.school_year = latest_extract.school_year
    WHERE
        base_table.date_extracted >= latest_extract.date_extracted
        AND id IS NOT NULL

)


SELECT
    date_extracted                          AS date_extracted,
    school_year                             AS school_year,
    id                                      AS id,
    CAST(JSON_VALUE(data, '$.numericGradeEarned') AS float64) AS numeric_grade_earned,
    JSON_VALUE(data, '$.letterGradeEarned') AS letter_grade_earned,
    SPLIT(JSON_VALUE(data, '$.performanceBaseConversionDescriptor'), '#')[OFFSET(1)] AS performance_base_conversion_descriptor, 
    SPLIT(JSON_VALUE(data, '$.gradeTypeDescriptor'), '#')[OFFSET(1)] AS grade_type_descriptor, 
    JSON_VALUE(data, '$.diagnosticStatement') AS diagnostic_statement,
    STRUCT(
        SPLIT(JSON_VALUE(data, '$.gradingPeriodReference.gradingPeriodDescriptor'), '#')[OFFSET(1)] AS grading_period_descriptor,
        CAST(JSON_VALUE(data, '$.gradingPeriodReference.periodSequence') AS int64) AS period_sequence,
        JSON_VALUE(data, '$.gradingPeriodReference.schoolId') AS school_id,
        CAST(JSON_VALUE(data, '$.gradingPeriodReference.schoolYear') AS int64) AS school_year
    ) AS grading_period_reference,
    STRUCT(
        EXTRACT(DATE FROM PARSE_TIMESTAMP('%Y-%m-%dT%TZ', JSON_VALUE(data, '$.studentSectionAssociationReference.beginDate'))) AS begin_date,
        JSON_VALUE(data, '$.studentSectionAssociationReference.localCourseCode') AS local_course_code,
        JSON_VALUE(data, '$.studentSectionAssociationReference.schoolId') AS school_id,
        CAST(JSON_VALUE(data, '$.studentSectionAssociationReference.schoolYear') AS int64) AS school_year,
        JSON_VALUE(data, '$.studentSectionAssociationReference.sectionIdentifier') AS section_identifier,
        JSON_VALUE(data, '$.studentSectionAssociationReference.sessionName') AS session_name,
        JSON_VALUE(data, '$.studentSectionAssociationReference.studentUniqueId') AS student_unique_id
    ) AS student_section_association_reference
FROM records
WHERE
    extract_type = 'records'
    AND id NOT IN (SELECT id FROM records WHERE extract_type = 'deletes') 
QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id
        ORDER BY date_extracted DESC) = 1
