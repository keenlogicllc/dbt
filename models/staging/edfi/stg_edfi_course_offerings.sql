
WITH records AS (

    SELECT *
    FROM {{ source('staging', 'base_edfi_course_offerings') }}
    WHERE date_extracted >= (
        SELECT MAX(date_extracted) AS date_extracted
        FROM {{ source('staging', 'base_edfi_course_offerings') }}
        WHERE is_complete_extract IS TRUE)

)


SELECT
    date_extracted                          AS date_extracted,
    school_year                             AS school_year,
    JSON_VALUE(data, '$.id') AS id,
    JSON_VALUE(data, '$.localCourseCode') AS local_course_code,
    JSON_VALUE(data, '$.localCourseTitle') AS local_course_title,
    STRUCT(
        JSON_VALUE(data, '$.courseReference.courseCode') AS course_code,
        JSON_VALUE(data, '$.courseReference.educationOrganizationId') AS education_organization_id
    ) AS course_reference,
    STRUCT(
        JSON_VALUE(data, '$.schoolReference.schoolId') AS school_id
    ) AS school_reference,
    STRUCT(
        JSON_VALUE(data, '$.sessionReference.schoolId') AS school_id,
        CAST(JSON_VALUE(data, '$.sessionReference.schoolYear') AS int64) AS school_year,
        JSON_VALUE(data, '$.sessionReference.sessionName') AS session_name
    ) AS session_reference,
FROM records
WHERE
    extract_type = 'records'
    AND id NOT IN (SELECT id FROM records WHERE extract_type = 'deletes') 
QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id
        ORDER BY date_extracted DESC) = 1
