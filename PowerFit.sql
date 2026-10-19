
-- ============================================================
-- PowerFit Database
-- SQL Server
-- ============================================================

IF DB_ID(N'PowerFitDB') IS NULL
BEGIN
    CREATE DATABASE PowerFitDB;
END;
GO

USE PowerFitDB;
GO

-- ============================================================
-- 1. Person
-- ============================================================

CREATE TABLE dbo.Person
(
    PersonID INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(254) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    BirthDate DATE NULL,
    Role NVARCHAR(10) NOT NULL,

    CONSTRAINT PK_Person PRIMARY KEY (PersonID),
    CONSTRAINT UQ_Person_Email UNIQUE (Email),
    CONSTRAINT UQ_Person_PersonID_Role UNIQUE (PersonID, Role),

    CONSTRAINT CK_Person_FirstName
        CHECK (LEN(TRIM(FirstName)) > 0),

    CONSTRAINT CK_Person_LastName
        CHECK (LEN(TRIM(LastName)) > 0),

    CONSTRAINT CK_Person_Email
        CHECK (
            LEN(TRIM(Email)) > 0
            AND Email LIKE '%_@_%._%'
        ),

    CONSTRAINT CK_Person_PasswordHash
        CHECK (LEN(TRIM(PasswordHash)) > 0),

    CONSTRAINT CK_Person_BirthDate
        CHECK (
            BirthDate IS NULL
            OR BirthDate BETWEEN '19000101' AND CAST(GETDATE() AS DATE)
        ),

    CONSTRAINT CK_Person_Role
        CHECK (Role IN (N'User', N'Admin'))
);
GO

-- ============================================================
-- 2. User
-- ============================================================

CREATE TABLE dbo.[User]
(
    UserID INT IDENTITY(1,1) NOT NULL,
    PersonID INT NOT NULL,
    Role NVARCHAR(10) NOT NULL
        CONSTRAINT DF_User_Role DEFAULT N'User',

    CONSTRAINT PK_User PRIMARY KEY (UserID),
    CONSTRAINT UQ_User_PersonID UNIQUE (PersonID),

    CONSTRAINT CK_User_Role
        CHECK (Role = N'User'),

    CONSTRAINT FK_User_Person
        FOREIGN KEY (PersonID, Role)
        REFERENCES dbo.Person (PersonID, Role)
        ON DELETE NO ACTION
);
GO

-- ============================================================
-- 3. Admin
-- ============================================================

CREATE TABLE dbo.Admin
(
    AdminID INT IDENTITY(1,1) NOT NULL,
    PersonID INT NOT NULL,
    Role NVARCHAR(10) NOT NULL
        CONSTRAINT DF_Admin_Role DEFAULT N'Admin',

    CONSTRAINT PK_Admin PRIMARY KEY (AdminID),
    CONSTRAINT UQ_Admin_PersonID UNIQUE (PersonID),

    CONSTRAINT CK_Admin_Role
        CHECK (Role = N'Admin'),

    CONSTRAINT FK_Admin_Person
        FOREIGN KEY (PersonID, Role)
        REFERENCES dbo.Person (PersonID, Role)
        ON DELETE NO ACTION
);
GO

-- ============================================================
-- 4. Profile
-- ============================================================

CREATE TABLE dbo.Profile
(
    UserID INT NOT NULL,
    Gender NVARCHAR(10) NULL,
    HeightCm INT NULL,
    WeightKg DECIMAL(5,2) NULL,
    Goal NVARCHAR(30) NULL,
    ActivityLevel NVARCHAR(20) NULL,
    ExperienceLevel NVARCHAR(20) NULL,
    TrainingLocation NVARCHAR(20) NULL,
    PreferredDaysPerWeek INT NULL,
    Injuries NVARCHAR(500) NULL,
    DietaryRestrictions NVARCHAR(500) NULL,

    ProfileCompleted BIT NOT NULL
        CONSTRAINT DF_Profile_Completed DEFAULT 0,

    CONSTRAINT PK_Profile PRIMARY KEY (UserID),

    CONSTRAINT FK_Profile_User
        FOREIGN KEY (UserID)
        REFERENCES dbo.[User](UserID)
        ON DELETE CASCADE,

    CONSTRAINT CK_Profile_Gender
        CHECK (
            Gender IS NULL
            OR Gender IN (N'Male', N'Female', N'Other')
        ),

    CONSTRAINT CK_Profile_Height
        CHECK (HeightCm IS NULL OR HeightCm BETWEEN 50 AND 260),

    CONSTRAINT CK_Profile_Weight
        CHECK (WeightKg IS NULL OR WeightKg BETWEEN 20 AND 500),

    CONSTRAINT CK_Profile_Goal
        CHECK (
            Goal IS NULL OR Goal IN
            (N'Muscle Gain', N'Fat Loss', N'Strength', N'Fitness')
        ),

    CONSTRAINT CK_Profile_ActivityLevel
        CHECK (
            ActivityLevel IS NULL OR ActivityLevel IN
            (N'Sedentary', N'Light', N'Moderate', N'Active', N'Very Active')
        ),

    CONSTRAINT CK_Profile_ExperienceLevel
        CHECK (
            ExperienceLevel IS NULL OR ExperienceLevel IN
            (N'Beginner', N'Intermediate', N'Advanced')
        ),

    CONSTRAINT CK_Profile_TrainingLocation
        CHECK (
            TrainingLocation IS NULL
            OR TrainingLocation IN (N'Gym', N'Home', N'Outdoor')
        ),

    CONSTRAINT CK_Profile_DaysPerWeek
        CHECK (
            PreferredDaysPerWeek IS NULL
            OR PreferredDaysPerWeek BETWEEN 1 AND 7
        ),

    CONSTRAINT CK_Profile_Completed
        CHECK (
            ProfileCompleted = 0
            OR (
                Gender IS NOT NULL
                AND HeightCm IS NOT NULL
                AND WeightKg IS NOT NULL
                AND Goal IS NOT NULL
                AND ActivityLevel IS NOT NULL
                AND ExperienceLevel IS NOT NULL
                AND TrainingLocation IS NOT NULL
                AND PreferredDaysPerWeek IS NOT NULL
            )
        )
);
GO

-- ============================================================
-- 5. FitnessPlan
-- ============================================================

CREATE TABLE dbo.FitnessPlan
(
    PlanID INT IDENTITY(1,1) NOT NULL,
    UserID INT NOT NULL,
    LastEditedByAdminID INT NULL,

    Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FitnessPlan_Status DEFAULT N'Draft',

    IsActive AS
        (CONVERT(BIT, CASE WHEN Status = N'Active'
                           THEN 1 ELSE 0 END)) PERSISTED,

    LastEditedAt DATETIME2(0) NULL,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_FitnessPlan_CreatedAt
        DEFAULT SYSUTCDATETIME(),

    UpdatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_FitnessPlan_UpdatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_FitnessPlan PRIMARY KEY (PlanID),

    CONSTRAINT FK_FitnessPlan_User
        FOREIGN KEY (UserID)
        REFERENCES dbo.[User](UserID)
        ON DELETE CASCADE,

    CONSTRAINT FK_FitnessPlan_Admin
        FOREIGN KEY (LastEditedByAdminID)
        REFERENCES dbo.Admin(AdminID)
        ON DELETE SET NULL,

    CONSTRAINT CK_FitnessPlan_Status
        CHECK (Status IN (N'Draft', N'Active', N'Archived')),

    CONSTRAINT CK_FitnessPlan_Dates
        CHECK (
            UpdatedAt >= CreatedAt
            AND (LastEditedAt IS NULL OR LastEditedAt >= CreatedAt)
        )
);
GO

CREATE INDEX IX_FitnessPlan_UserID
    ON dbo.FitnessPlan(UserID);

CREATE INDEX IX_FitnessPlan_LastEditedByAdminID
    ON dbo.FitnessPlan(LastEditedByAdminID);
GO

-- ============================================================
-- 6. ExercisePlan
-- ============================================================

CREATE TABLE dbo.ExercisePlan
(
    ExercisePlanID INT IDENTITY(1,1) NOT NULL,
    PlanID INT NOT NULL,
    DaysPerWeek INT NOT NULL,
    Notes NVARCHAR(500) NULL,

    CONSTRAINT PK_ExercisePlan PRIMARY KEY (ExercisePlanID),
    CONSTRAINT UQ_ExercisePlan_PlanID UNIQUE (PlanID),

    CONSTRAINT FK_ExercisePlan_FitnessPlan
        FOREIGN KEY (PlanID)
        REFERENCES dbo.FitnessPlan(PlanID)
        ON DELETE CASCADE,

    CONSTRAINT CK_ExercisePlan_Days
        CHECK (DaysPerWeek BETWEEN 1 AND 7)
);
GO

-- ============================================================
-- 7. NutritionPlan
-- ============================================================

CREATE TABLE dbo.NutritionPlan
(
    NutritionPlanID INT IDENTITY(1,1) NOT NULL,
    PlanID INT NOT NULL,
    DailyCalories INT NOT NULL,
    ProteinG INT NOT NULL,
    CarbsG INT NOT NULL,
    FatG INT NOT NULL,

    CONSTRAINT PK_NutritionPlan PRIMARY KEY (NutritionPlanID),
    CONSTRAINT UQ_NutritionPlan_PlanID UNIQUE (PlanID),

    CONSTRAINT FK_NutritionPlan_FitnessPlan
        FOREIGN KEY (PlanID)
        REFERENCES dbo.FitnessPlan(PlanID)
        ON DELETE CASCADE,

    CONSTRAINT CK_NutritionPlan_Calories
        CHECK (DailyCalories BETWEEN 800 AND 6000),

    CONSTRAINT CK_NutritionPlan_Protein
        CHECK (ProteinG BETWEEN 0 AND 500),

    CONSTRAINT CK_NutritionPlan_Carbs
        CHECK (CarbsG BETWEEN 0 AND 1000),

    CONSTRAINT CK_NutritionPlan_Fat
        CHECK (FatG BETWEEN 0 AND 400)
);
GO

-- ============================================================
-- 8. Exercise
-- ============================================================

CREATE TABLE dbo.Exercise
(
    ExerciseID INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    MuscleGroup NVARCHAR(50) NOT NULL,
    ExerciseType NVARCHAR(20) NOT NULL,

    Equipment NVARCHAR(30) NOT NULL
        CONSTRAINT DF_Exercise_Equipment DEFAULT N'None',

    DifficultyLevel NVARCHAR(20) NOT NULL,
    ContraindicatedAreas NVARCHAR(200) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Exercise_IsActive DEFAULT 1,

    CONSTRAINT PK_Exercise PRIMARY KEY (ExerciseID),
    CONSTRAINT UQ_Exercise_Name UNIQUE (Name),

    CONSTRAINT CK_Exercise_Name
        CHECK (LEN(TRIM(Name)) > 0),

    CONSTRAINT CK_Exercise_MuscleGroup
        CHECK (LEN(TRIM(MuscleGroup)) > 0),

    CONSTRAINT CK_Exercise_Type
        CHECK (ExerciseType IN
            (N'Strength', N'Cardio', N'Flexibility', N'Balance')),

    CONSTRAINT CK_Exercise_Equipment
        CHECK (LEN(TRIM(Equipment)) > 0),

    CONSTRAINT CK_Exercise_Difficulty
        CHECK (DifficultyLevel IN
            (N'Beginner', N'Intermediate', N'Advanced')),

    CONSTRAINT CK_Exercise_Contraindications
        CHECK (
            ContraindicatedAreas IS NULL
            OR LEN(TRIM(ContraindicatedAreas)) > 0
        )
);
GO

-- ============================================================
-- 9. ExercisePlanItem
-- ============================================================

CREATE TABLE dbo.ExercisePlanItem
(
    ItemID INT IDENTITY(1,1) NOT NULL,
    ExercisePlanID INT NOT NULL,
    ExerciseID INT NOT NULL,
    DayNumber INT NOT NULL,
    OrderIndex INT NOT NULL,
    Sets INT NOT NULL,
    Reps INT NOT NULL,

    Source NVARCHAR(10) NOT NULL
        CONSTRAINT DF_ExercisePlanItem_Source DEFAULT N'AI',

    Notes NVARCHAR(500) NULL,

    CONSTRAINT PK_ExercisePlanItem PRIMARY KEY (ItemID),

    CONSTRAINT FK_ExercisePlanItem_ExercisePlan
        FOREIGN KEY (ExercisePlanID)
        REFERENCES dbo.ExercisePlan(ExercisePlanID)
        ON DELETE CASCADE,

    CONSTRAINT FK_ExercisePlanItem_Exercise
        FOREIGN KEY (ExerciseID)
        REFERENCES dbo.Exercise(ExerciseID)
        ON DELETE NO ACTION,

    CONSTRAINT UQ_ExercisePlanItem_Order
        UNIQUE (ExercisePlanID, DayNumber, OrderIndex),

    CONSTRAINT CK_ExercisePlanItem_Day
        CHECK (DayNumber BETWEEN 1 AND 7),

    CONSTRAINT CK_ExercisePlanItem_OrderIndex
        CHECK (OrderIndex >= 1),

    CONSTRAINT CK_ExercisePlanItem_Sets
        CHECK (Sets BETWEEN 1 AND 20),

    CONSTRAINT CK_ExercisePlanItem_Reps
        CHECK (Reps BETWEEN 1 AND 100),

    CONSTRAINT CK_ExercisePlanItem_Source
        CHECK (Source IN (N'AI', N'Admin'))
);
GO

CREATE INDEX IX_ExercisePlanItem_ExerciseID
    ON dbo.ExercisePlanItem(ExerciseID);
GO

-- ============================================================
-- 10. Food
-- ============================================================

CREATE TABLE dbo.Food
(
    FoodID INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Category NVARCHAR(30) NOT NULL,
    SuitableMeals NVARCHAR(100) NULL,

    CaloriesPer100g DECIMAL(6,2) NOT NULL,
    ProteinPer100g DECIMAL(6,2) NOT NULL,
    CarbsPer100g DECIMAL(6,2) NOT NULL,
    FatPer100g DECIMAL(6,2) NOT NULL,

    IsVegetarian BIT NOT NULL
        CONSTRAINT DF_Food_Vegetarian DEFAULT 0,

    IsGlutenFree BIT NOT NULL
        CONSTRAINT DF_Food_GlutenFree DEFAULT 0,

    ContainsDairy BIT NOT NULL
        CONSTRAINT DF_Food_ContainsDairy DEFAULT 0,

    ContainsNuts BIT NOT NULL
        CONSTRAINT DF_Food_ContainsNuts DEFAULT 0,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Food_IsActive DEFAULT 1,

    CONSTRAINT PK_Food PRIMARY KEY (FoodID),
    CONSTRAINT UQ_Food_Name UNIQUE (Name),

    CONSTRAINT CK_Food_Name
        CHECK (LEN(TRIM(Name)) > 0),

    CONSTRAINT CK_Food_Category
        CHECK (LEN(TRIM(Category)) > 0),

    CONSTRAINT CK_Food_Calories
        CHECK (CaloriesPer100g BETWEEN 0 AND 900),

    CONSTRAINT CK_Food_Protein
        CHECK (ProteinPer100g BETWEEN 0 AND 100),

    CONSTRAINT CK_Food_Carbs
        CHECK (CarbsPer100g BETWEEN 0 AND 100),

    CONSTRAINT CK_Food_Fat
        CHECK (FatPer100g BETWEEN 0 AND 100),

    CONSTRAINT CK_Food_Macros
        CHECK (
            ProteinPer100g + CarbsPer100g + FatPer100g <= 100
        )
);
GO

-- ============================================================
-- 11. NutritionPlanItem
-- ============================================================

CREATE TABLE dbo.NutritionPlanItem
(
    ItemID INT IDENTITY(1,1) NOT NULL,
    NutritionPlanID INT NOT NULL,
    FoodID INT NOT NULL,
    DayNumber INT NOT NULL,
    MealType NVARCHAR(20) NOT NULL,
    QuantityGrams INT NOT NULL,

    Source NVARCHAR(10) NOT NULL
        CONSTRAINT DF_NutritionPlanItem_Source DEFAULT N'AI',

    CONSTRAINT PK_NutritionPlanItem PRIMARY KEY (ItemID),

    CONSTRAINT FK_NutritionPlanItem_NutritionPlan
        FOREIGN KEY (NutritionPlanID)
        REFERENCES dbo.NutritionPlan(NutritionPlanID)
        ON DELETE CASCADE,

    CONSTRAINT FK_NutritionPlanItem_Food
        FOREIGN KEY (FoodID)
        REFERENCES dbo.Food(FoodID)
        ON DELETE NO ACTION,

    CONSTRAINT CK_NutritionPlanItem_Day
        CHECK (DayNumber BETWEEN 1 AND 7),

    CONSTRAINT CK_NutritionPlanItem_MealType
        CHECK (MealType IN
            (N'Breakfast', N'Lunch', N'Dinner', N'Snack')),

    CONSTRAINT CK_NutritionPlanItem_Quantity
        CHECK (QuantityGrams BETWEEN 1 AND 2000),

    CONSTRAINT CK_NutritionPlanItem_Source
        CHECK (Source IN (N'AI', N'Admin'))
);
GO

CREATE INDEX IX_NutritionPlanItem_FoodID
    ON dbo.NutritionPlanItem(FoodID);
GO

-- ============================================================
-- 12. AIGenerationLog
-- ============================================================

CREATE TABLE dbo.AIGenerationLog
(
    LogID INT IDENTITY(1,1) NOT NULL,
    PlanID INT NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    RequestJson NVARCHAR(MAX) NOT NULL,
    ResponseJson NVARCHAR(MAX) NULL,
    Status NVARCHAR(20) NOT NULL,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_AIGenerationLog_CreatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_AIGenerationLog PRIMARY KEY (LogID),

    CONSTRAINT FK_AIGenerationLog_FitnessPlan
        FOREIGN KEY (PlanID)
        REFERENCES dbo.FitnessPlan(PlanID)
        ON DELETE CASCADE,

    CONSTRAINT CK_AIGenerationLog_Model
        CHECK (LEN(TRIM(Model)) > 0),

    CONSTRAINT CK_AIGenerationLog_RequestJson
        CHECK (ISJSON(RequestJson) = 1),

    CONSTRAINT CK_AIGenerationLog_ResponseJson
        CHECK (
            ResponseJson IS NULL OR ISJSON(ResponseJson) = 1
        ),

    CONSTRAINT CK_AIGenerationLog_Status
        CHECK (Status IN (N'Success', N'Failed', N'Timeout')),

    CONSTRAINT CK_AIGenerationLog_SuccessResponse
        CHECK (Status <> N'Success' OR ResponseJson IS NOT NULL)
);
GO

CREATE INDEX IX_AIGenerationLog_PlanID_CreatedAt
    ON dbo.AIGenerationLog(PlanID, CreatedAt);
GO
