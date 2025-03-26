-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2025-03-21 14:43:49.134

-- tables
-- Table: category
CREATE TABLE category (
    code varchar(4)  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT category_pk PRIMARY KEY (code)
);

-- Table: correction
CREATE TABLE correction (
    code varchar(10)  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT correction_pk PRIMARY KEY (code)
);

-- Table: correction1
CREATE TABLE correction1 (
    correction_code varchar(10)  NOT NULL,
    iwc_abundances_table_id varchar(50)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT correction1_pk PRIMARY KEY (id)
);

-- Table: evaluation
CREATE TABLE evaluation (
    extent int  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT evaluation_pk PRIMARY KEY (extent)
);

-- Table: iwc_abundances_table
CREATE TABLE iwc_abundances_table (
    id varchar(50)  NOT NULL,
    year int  NULL,
    startyear int  NULL,
    endyear int  NULL,
    estimate int  NOT NULL,
    cv real  NULL,
    se real  NULL,
    cvav real  NULL,
    lci real  NULL,
    uci real  NULL,
    notes text  NULL,
    pl int  NULL,
    pu int  NULL,
    season varchar(150)  NULL,
    gnull real  NULL,
    areacoverage varchar(100)  NULL,
    sd real  NULL,
    cvcalc real  NULL,
    dateadded date  NULL,
    datemodified date  NULL,
    regions_code varchar(4)  NOT NULL,
    species_code varchar(30)  NOT NULL,
    category_code varchar(4)  NULL,
    evaluation_extent int  NULL,
    subareas_id int  NOT NULL,
    timeseries_code varchar(10)  NULL,
    CONSTRAINT iwc_abundances_table_pk PRIMARY KEY (id)
);

-- Table: method
CREATE TABLE method (
    code varchar(15)  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT method_pk PRIMARY KEY (code)
);

-- Table: method1
CREATE TABLE method1 (
    method_code varchar(15)  NOT NULL,
    iwc_abundances_table_id varchar(50)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT method1_pk PRIMARY KEY (id)
);

-- Table: references
CREATE TABLE "references" (
    refid varchar(50)  NOT NULL,
    ref varchar(250)  NOT NULL,
    fullref text  NOT NULL,
    iwcref varchar(150)  NULL,
    CONSTRAINT references_pk PRIMARY KEY (refid)
);

-- Table: references1
CREATE TABLE references1 (
    iwc_abundances_table_id varchar(50)  NOT NULL,
    references_refid varchar(250)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT references1_pk PRIMARY KEY (id)
);

-- Table: regions
CREATE TABLE regions (
    code varchar(4)  NOT NULL,
    fullname varchar(60)  NULL,
    CONSTRAINT regions_pk PRIMARY KEY (code)
);

-- Table: regions1
CREATE TABLE regions1 (
    regions_code varchar(4)  NOT NULL,
    references_refid varchar(250)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT regions1_pk PRIMARY KEY (id)
);

-- Table: species
CREATE TABLE species (
    code varchar(30)  NOT NULL,
    faocode varchar(30)  NULL,
    scientificname varchar(250)  NOT NULL,
    commonname varchar(250)  NOT NULL,
    alternativename varchar(250)  NULL,
    iucn varchar(30)  NULL,
    CONSTRAINT species_pk PRIMARY KEY (code)
);

-- Table: species2
CREATE TABLE species2 (
    references_refid varchar(250)  NOT NULL,
    species_code varchar(30)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT species2_pk PRIMARY KEY (id)
);

-- Table: subareas
CREATE TABLE subareas (
    id int  NOT NULL,
    subarea varchar(250)  NOT NULL,
    accuracy varchar(250)  NOT NULL,
    source text  NOT NULL,
    geometry geometry  NOT NULL,
    species_code varchar(30)  NOT NULL,
    regions_code varchar(4)  NOT NULL,
    survey_programme varchar(250)  NULL,
    CONSTRAINT subareas_pk PRIMARY KEY (id)
);

-- Table: survey
CREATE TABLE survey (
    programme varchar(250)  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT survey_pk PRIMARY KEY (programme)
);

-- Table: survey1
CREATE TABLE survey1 (
    survey_programme varchar(250)  NOT NULL,
    iwc_abundances_table_id varchar(50)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT survey1_pk PRIMARY KEY (id)
);

-- Table: timeseries
CREATE TABLE timeseries (
    id int  NOT NULL,
    code varchar(10)  NOT NULL,
    estimate int  NOT NULL,
    cv int  NULL,
    se int  NULL,
    sd int  NULL,
    year int  NOT NULL,
    lci int  NULL,
    uci int  NULL,
    notes text  NULL,
    CONSTRAINT timeseries_pk PRIMARY KEY (id)
);

-- Table: timeseries1
CREATE TABLE timeseries1 (
    iwc_abundances_table_id varchar(50)  NOT NULL,
    timeseries_id int  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT timeseries1_pk PRIMARY KEY (id)
);

-- Table: trials
CREATE TABLE trials (
    usage varchar(8)  NOT NULL,
    description text  NOT NULL,
    CONSTRAINT trials_pk PRIMARY KEY (usage)
);

-- Table: trials1
CREATE TABLE trials1 (
    trials_usage varchar(8)  NOT NULL,
    iwc_abundances_table_id varchar(50)  NOT NULL,
    id int  NOT NULL,
    CONSTRAINT trials1_pk PRIMARY KEY (id)
);

-- foreign keys
-- Reference: Table_17_references (table: species2)
ALTER TABLE species2 ADD CONSTRAINT Table_17_references
    FOREIGN KEY (references_refid)
    REFERENCES "references" (refid)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Table_17_species (table: species2)
ALTER TABLE species2 ADD CONSTRAINT Table_17_species
    FOREIGN KEY (species_code)
    REFERENCES species (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: correction1_correction (table: correction1)
ALTER TABLE correction1 ADD CONSTRAINT correction1_correction
    FOREIGN KEY (correction_code)
    REFERENCES correction (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: correction1_iwc_abundances_table (table: correction1)
ALTER TABLE correction1 ADD CONSTRAINT correction1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: iwc_abundances_table_category (table: iwc_abundances_table)
ALTER TABLE iwc_abundances_table ADD CONSTRAINT iwc_abundances_table_category
    FOREIGN KEY (category_code)
    REFERENCES category (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: iwc_abundances_table_evaluation (table: iwc_abundances_table)
ALTER TABLE iwc_abundances_table ADD CONSTRAINT iwc_abundances_table_evaluation
    FOREIGN KEY (evaluation_extent)
    REFERENCES evaluation (extent)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: iwc_abundances_table_regions (table: iwc_abundances_table)
ALTER TABLE iwc_abundances_table ADD CONSTRAINT iwc_abundances_table_regions
    FOREIGN KEY (regions_code)
    REFERENCES regions (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: iwc_abundances_table_species (table: iwc_abundances_table)
ALTER TABLE iwc_abundances_table ADD CONSTRAINT iwc_abundances_table_species
    FOREIGN KEY (species_code)
    REFERENCES species (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: iwc_abundances_table_subareas (table: iwc_abundances_table)
ALTER TABLE iwc_abundances_table ADD CONSTRAINT iwc_abundances_table_subareas
    FOREIGN KEY (subareas_id)
    REFERENCES subareas (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: method1_iwc_abundances_table (table: method1)
ALTER TABLE method1 ADD CONSTRAINT method1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: method1_method (table: method1)
ALTER TABLE method1 ADD CONSTRAINT method1_method
    FOREIGN KEY (method_code)
    REFERENCES method (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: references1_iwc_abundances_table (table: references1)
ALTER TABLE references1 ADD CONSTRAINT references1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: references1_references (table: references1)
ALTER TABLE references1 ADD CONSTRAINT references1_references
    FOREIGN KEY (references_refid)
    REFERENCES "references" (refid)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: regions1_references (table: regions1)
ALTER TABLE regions1 ADD CONSTRAINT regions1_references
    FOREIGN KEY (references_refid)
    REFERENCES "references" (refid)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: regions1_regions (table: regions1)
ALTER TABLE regions1 ADD CONSTRAINT regions1_regions
    FOREIGN KEY (regions_code)
    REFERENCES regions (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: subareas_regions (table: subareas)
ALTER TABLE subareas ADD CONSTRAINT subareas_regions
    FOREIGN KEY (regions_code)
    REFERENCES regions (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: subareas_species (table: subareas)
ALTER TABLE subareas ADD CONSTRAINT subareas_species
    FOREIGN KEY (species_code)
    REFERENCES species (code)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;
-- Reference: subareas_surveys (table: subareas)
ALTER TABLE subareas ADD CONSTRAINT subareas_survey
    FOREIGN KEY (survey_programme)
    REFERENCES survey (programme)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: survey1_iwc_abundances_table (table: survey1)
ALTER TABLE survey1 ADD CONSTRAINT survey1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: survey1_survey (table: survey1)
ALTER TABLE survey1 ADD CONSTRAINT survey1_survey
    FOREIGN KEY (survey_programme)
    REFERENCES survey (programme)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: timeseries1_iwc_abundances_table (table: timeseries1)
ALTER TABLE timeseries1 ADD CONSTRAINT timeseries1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: timeseries1_timeseries (table: timeseries1)
ALTER TABLE timeseries1 ADD CONSTRAINT timeseries1_timeseries
    FOREIGN KEY (timeseries_id)
    REFERENCES timeseries (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: trials1_iwc_abundances_table (table: trials1)
ALTER TABLE trials1 ADD CONSTRAINT trials1_iwc_abundances_table
    FOREIGN KEY (iwc_abundances_table_id)
    REFERENCES iwc_abundances_table (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: trials1_trials (table: trials1)
ALTER TABLE trials1 ADD CONSTRAINT trials1_trials
    FOREIGN KEY (trials_usage)
    REFERENCES trials (usage)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- End of file.

