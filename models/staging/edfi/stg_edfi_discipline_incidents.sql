
WITH latest_extract AS (

    SELECT
        school_year,
        MAX(date_extracted) AS date_extracted
    FROM {{ source('staging', 'base_edfi_discipline_incidents') }}
    WHERE is_complete_extract IS TRUE
    GROUP BY 1

),

records AS (

    SELECT base_table.*
    FROM {{ source('staging', 'base_edfi_discipline_incidents') }} base_table
    LEFT JOIN latest_extract ON base_table.school_year = latest_extract.school_year
    WHERE
        base_table.date_extracted >= latest_extract.date_extracted
        AND id IS NOT NULL

)


SELECT
    date_extracted                                                              AS date_extracted,
    school_year                                                                 AS school_year,
    id                                                                          AS id,
    JSON_VALUE(data, '$.incidentIdentifier')                                    AS incident_identifier,
    JSON_VALUE(data, '$.caseNumber')                                            AS case_number,
    CAST(JSON_VALUE(data, '$.incidentCost') AS float64)                         AS incident_cost,
    PARSE_DATE('%Y-%m-%d', JSON_VALUE(data, '$.incidentDate'))                  AS incident_date,
    JSON_VALUE(data, '$.incidentDescription')                                   AS incident_description,
    SPLIT(JSON_VALUE(data, '$.incidentLocationDescriptor'), '#')[OFFSET(1)]     AS incident_location_descriptor,
    JSON_VALUE(data, '$.incidentTime')                                          AS incident_time,
    CAST(JSON_VALUE(data, '$.reportedToLawEnforcement') AS BOOL)                AS reported_to_law_enforcement,
    SPLIT(JSON_VALUE(data, '$.reporterDescriptionDescriptor'), '#')[OFFSET(1)]  AS reporter_description_descriptor,
    JSON_VALUE(data, '$.reporterName')                                          AS reporter_name,
    STRUCT(
        JSON_VALUE(data, '$.schoolReference.schoolId') AS school_id
    )                                                                           AS school_reference,
    STRUCT(
        JSON_VALUE(data, '$.staffReference.staffUniqueId') AS staff_unique_id
    )                                                                           AS staff_reference,
    ARRAY(
        SELECT AS STRUCT 
            SPLIT(JSON_VALUE(behaviors, '$.behaviorDescriptor'), '#')[OFFSET(1)] AS behavior_descriptor,
            JSON_VALUE(behaviors, "$.behaviorDetailedDescription") AS behavior_detailed_description
        FROM UNNEST(JSON_QUERY_ARRAY(data, "$.behaviors")) behaviors 
    )                                                                           AS behaviors,
    ARRAY(
        SELECT AS STRUCT 
            SPLIT(JSON_VALUE(external_participants, '$.disciplineIncidentParticipationCodeDescriptor'), '#')[OFFSET(1)] AS discipline_incident_participation_code_descriptor,
            JSON_VALUE(external_participants, "$.firstName") AS first_name,
            JSON_VALUE(external_participants, "$.lastSurname") AS last_surname
        FROM UNNEST(JSON_QUERY_ARRAY(data, "$.externalParticipants")) external_participants 
    )                                                                           AS external_participants,
FROM records
WHERE
    extract_type = 'records'
    AND id NOT IN (SELECT id FROM records WHERE extract_type = 'deletes') 
QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id
        ORDER BY date_extracted DESC) = 1
