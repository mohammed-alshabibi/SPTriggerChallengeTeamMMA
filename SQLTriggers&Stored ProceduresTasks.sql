--==============================================================================================================TASK 1 PROCEDURE===============================================================================================================
--  إنشاء قاعدة بيانات الحيوانات
CREATE DATABASE AnimalShelterDB;


--   استخدام قاعدة البيانات
USE AnimalShelterDB;
GO

--   إنشاء جدول الحيوانات
CREATE TABLE Animal (
    AnimalID INT PRIMARY KEY,
    Name VARCHAR(50),
    Type VARCHAR(50),
    LastFed DATETIME
);
GO

--   إدخال بيانات الحيوانات
INSERT INTO Animal VALUES (1, 'Bello', 'Dog', '2024-05-20');
INSERT INTO Animal VALUES (2, 'Kitty', 'Cat', '2024-05-24');
INSERT INTO Animal VALUES (3, 'Falcon', 'Bird', NULL);
GO

--   إنشاء إجراء لتحديث وقت الإطعام
CREATE PROCEDURE FeedAnimal
    @AnimalID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Animal WHERE AnimalID = @AnimalID)
    BEGIN
        UPDATE Animal SET LastFed = GETDATE() WHERE AnimalID = @AnimalID;
        PRINT 'Animal has been fed.';
    END
    ELSE
    BEGIN
        PRINT 'Animal ID not found.';
    END
END;
GO
--   اختبار الإجراء - تغذية حيوان  موجود
EXEC FeedAnimal @AnimalID = 3;
--   اختبار رقم حيوان غير موجود
EXEC FeedAnimal @AnimalID = 99;

--==============================================================================================================TASK 2 PROCEDURE===============================================================================================================

-- 1. إنشاء قاعدة البيانات
CREATE DATABASE HRSystem;
GO

-- 2. استخدام قاعدة البيانات
USE HRSystem;


-- 3. إنشاء جدول الموظفين
CREATE TABLE Employee (
    ID INT PRIMARY KEY,
    Name VARCHAR(100),
    Position VARCHAR(100),
    Salary FLOAT
);
GO

-- 4. إدخال بيانات تجريبية
INSERT INTO Employee VALUES (1, 'Ahmed AlBalushi', 'Manager', 1200);
INSERT INTO Employee VALUES (2, 'Fatma AlHinai', 'Accountant', 800);
INSERT INTO Employee VALUES (3, 'Salim AlZadjali', 'Developer', 950);
INSERT INTO Employee VALUES (4, 'Aisha AlBusaidi', 'Intern', NULL);
GO

-- 5. إنشاء الإجراء لحساب البونص
CREATE PROCEDURE CalculateBonus
    @EmpID INT
AS
BEGIN
    DECLARE @Salary FLOAT, @Bonus FLOAT;

    SELECT @Salary = Salary FROM Employee WHERE ID = @EmpID;

    IF @Salary IS NOT NULL
    BEGIN
        SET @Bonus = @Salary * 0.10;
        PRINT 'Employee Bonus: ' + CAST(@Bonus AS VARCHAR);
    END
    ELSE
    BEGIN
        PRINT 'Employee not found or salary is NULL';
    END
END;
GO

--  6. اختبار الإجراء مع رقم موظف موجود
EXEC CalculateBonus @EmpID = 2;
--  7. اختبار الإجراء مع رقم موظف غير موجود
EXEC CalculateBonus @EmpID = 99;
-- 
--  8. اختبار موظف لديه NULL في الراتب
EXEC CalculateBonus @EmpID = 4;
--  
--==============================================================================================================TASK TRIGGER===============================================================================================================
CREATE DATABASE SchoolDB;
GO
USE SchoolDB;
GO
-- Main table
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Grade NVARCHAR(50)
);
-- Log table for inserts
CREATE TABLE StudentInsertLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT,
    Action NVARCHAR(50),
    TimeStamp DATETIME
);
-- Log table for updates
CREATE TABLE GradeChangeLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT,
    OldGrade NVARCHAR(50),
    NewGrade NVARCHAR(50),
    TimeStamp DATETIME
);
INSERT INTO Students (StudentID, Name, Grade)
VALUES
(1, N'Ahmed Ali', N'Grade 1'),
(2, N'Sara Mohammed', N'Grade 2'),
(3, N'Yousef Khaled', N'Grade 3');
--Insert Sample Data into GradeChangeLog
INSERT INTO GradeChangeLog (StudentID, OldGrade, NewGrade, TimeStamp)
VALUES
(101, 'Grade 1', 'Grade 2', GETDATE()),
(102, 'Grade 2', 'Grade 3', GETDATE()),
(103, 'Grade 3', 'Grade 4', GETDATE());
--Insert Sample Data into StudentInsertLog
INSERT INTO StudentInsertLog (StudentID, Action, TimeStamp)
VALUES
(101, 'INSERTED', GETDATE()),
(102, 'INSERTED', GETDATE()),
(103, 'INSERTED', GETDATE());
--Create a Trigger to Prevent Deletion
CREATE TRIGGER PreventStudentDeletion
ON Students
INSTEAD OF DELETE
AS
BEGIN
    PRINT 'Deleting student records is not allowed.';
    ROLLBACK;
END;
-- Try to Delete a Record (Test the Trigger)
DELETE FROM Students WHERE StudentID = 2;
--Confirm Data Is Still There
SELECT * FROM Students;
--INSTEAD OF INSERT – Prevent inserting students without names
CREATE TRIGGER ValidateStudentInsert
ON Students
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE Name IS NULL OR LTRIM(RTRIM(Name)) = '')
    BEGIN
        RAISERROR(' Student name cannot be empty.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Students (StudentID, Name, Grade)
        SELECT StudentID, Name, Grade FROM inserted;
    END
END;
--AFTER INSERT – Log every new student
CREATE TRIGGER LogStudentInsert
ON Students
AFTER INSERT
AS
BEGIN
    INSERT INTO StudentInsertLog (StudentID, Action, TimeStamp)
    SELECT StudentID, 'INSERTED', GETDATE() FROM inserted;
END;
--INSTEAD OF UPDATE – Prevent setting Grade to invalid value
CREATE TRIGGER ValidateGradeUpdate
ON Students
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE Grade IS NULL OR Grade = '')
    BEGIN
        RAISERROR(' Grade cannot be empty.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        UPDATE Students
        SET Name = i.Name,
            Grade = i.Grade
        FROM Students s
        JOIN inserted i ON s.StudentID = i.StudentID;
    END
END;
--AFTER UPDATE – Log grade changes
CREATE TRIGGER LogGradeChange
ON Students
AFTER UPDATE
AS
BEGIN
    INSERT INTO GradeChangeLog (StudentID, OldGrade, NewGrade, TimeStamp)
    SELECT d.StudentID, d.Grade, i.Grade, GETDATE()
    FROM deleted d
    JOIN inserted i ON d.StudentID = i.StudentID
    WHERE d.Grade <> i.Grade;
END;
--Test the Triggers
--Try to insert student with empty name (should fail):
INSERT INTO Students (StudentID, Name, Grade)
VALUES (1, '', 'Grade 1');
--Insert a valid student:
INSERT INTO Students (StudentID, Name, Grade)
VALUES (4, 'Ali Hassan', 'Grade 2');
--Try to update grade to empty (should fail):
UPDATE Students SET Grade = '' WHERE StudentID = 2;
--Valid grade update:
UPDATE Students SET Grade = 'Grade 3' WHERE StudentID = 2;