
-- CREATE DATABASE TABLE

-- 1. Agent Table
CREATE TABLE Agent (
    AgentID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Contact VARCHAR(50),
    Branch VARCHAR(100),
    Experience INT
);
SELECT * FROM Agent ;

-- 2. Client Table
CREATE TABLE Client (
    ClientID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Contact VARCHAR(50),
    Email VARCHAR(100),
    Gender VARCHAR(10)
);
SELECT * FROM Client ;

-- 3. Policy Table
CREATE TABLE Policy (
    PolicyID SERIAL PRIMARY KEY,
    ClientID INT REFERENCES Client(ClientID) ON DELETE CASCADE,
    AgentID INT REFERENCES Agent(AgentID) ON DELETE SET NULL,
    Type VARCHAR(50),
    Premium DECIMAL(10,2),
    StartDate DATE,
    EndDate DATE,
    Status VARCHAR(20)
);
SELECT * FROM Policy ;

-- 4. Claim Table

CREATE TABLE Claim (
    ClaimID SERIAL PRIMARY KEY,
    PolicyID INT REFERENCES Policy(PolicyID) ON DELETE CASCADE,
    DateFiled DATE,
    Type VARCHAR(50),
    Status VARCHAR(20),
    ClaimedAmount DECIMAL(10,2)
);
SELECT * FROM Claim ;

-- 5. ClaimAssessment Table
CREATE TABLE ClaimAssessment (
    AssessmentID SERIAL PRIMARY KEY,
    ClaimID INT UNIQUE REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Officer VARCHAR(100),
    AssessmentDate DATE,
    ApprovedAmount DECIMAL(10,2),
    Decision VARCHAR(20)
);
SELECT * FROM ClaimAssessment ;

-- 6.PAYMENT TABLE

CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    ClaimID INT UNIQUE REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Amount DECIMAL(10,2),
    PaymentDate DATE,
    Method VARCHAR(20)
);
SELECT * FROM Payment ;

-- Apply CASCADE DELETE between Claim → Payment
ALTER TABLE Payment
    DROP CONSTRAINT payment_claimid_fkey,
    ADD CONSTRAINT payment_claimid_fkey
    FOREIGN KEY (ClaimID) REFERENCES Claim(ClaimID) ON DELETE CASCADE;

-- 3. Insert sample data

INSERT INTO Agent (FullName, Contact, Branch, Experience) VALUES
('John Doe', '0789000001', 'Kigali', 5),
('Mary Uwase', '0789000002', 'Musanze', 3),
('Eric Habimana', '0789000003', 'Huye', 7);

INSERT INTO Client (FullName, Contact, Email, Gender) VALUES
('Alice N.', '0788000001', 'alice@gmail.com', 'F'),
('Brian M.', '0788000002', 'brian@gmail.com', 'M'),
('Carine K.', '0788000003', 'carine@gmail.com', 'F'),
('David R.', '0788000004', 'david@gmail.com', 'M'),
('Eliane T.', '0788000005', 'eliane@gmail.com', 'F');

INSERT INTO Policy (ClientID, AgentID, Type, Premium, StartDate, EndDate, Status) VALUES
(1, 1, 'Health', 200000, '2025-01-01', '2026-01-01', 'Active'),
(2, 1, 'Auto', 150000, '2025-02-01', '2026-02-01', 'Active'),
(3, 2, 'Home', 300000, '2025-03-01', '2026-03-01', 'Active'),
(4, 3, 'Life', 500000, '2025-04-01', '2030-04-01', 'Active'),
(5, 2, 'Travel', 120000, '2025-05-01', '2026-05-01', 'Active');

INSERT INTO Claim (PolicyID, DateFiled, Type, Status, ClaimedAmount) VALUES
(1, '2025-06-10', 'Medical', 'Approved', 80000),
(2, '2025-07-05', 'Accident', 'Pending', 100000),
(3, '2025-07-20', 'Fire', 'Approved', 250000),
(4, '2025-08-15', 'Death', 'Closed', 500000),
(5, '2025-09-01', 'Lost Baggage', 'Approved', 60000);

INSERT INTO ClaimAssessment (ClaimID, Officer, AssessmentDate, ApprovedAmount, Decision) VALUES
(1, 'Officer A', '2025-06-12', 80000, 'Approved'),
(2, 'Officer B', '2025-07-08', 0, 'Pending'),
(3, 'Officer C', '2025-07-22', 230000, 'Approved'),
(4, 'Officer D', '2025-08-18', 500000, 'Approved'),
(5, 'Officer E', '2025-09-03', 55000, 'Approved');

INSERT INTO Payment (ClaimID, Amount, PaymentDate, Method) VALUES
(1, 80000, '2025-06-20', 'Bank Transfer'),
(3, 230000, '2025-07-25', 'Mobile Money'),
(4, 500000, '2025-08-25', 'Cheque'),
(5, 55000, '2025-09-10', 'Mobile Money');

-- 4. Retrieve all approved claims with payment amounts

CREATE VIEW ApprovedClaimsWithPayments AS
SELECT c.ClaimID, c.Type, ca.Decision, ca.ApprovedAmount, p.Amount, p.PaymentDate
FROM Claim c
JOIN ClaimAssessment ca ON c.ClaimID = ca.ClaimID
JOIN Payment p ON c.ClaimID = p.ClaimID
WHERE ca.Decision = 'Approved';

-- 5. Update policy status after claim closure

CREATE OR REPLACE FUNCTION update_policy_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Policy
    SET Status = 'Closed'
    WHERE PolicyID = (SELECT PolicyID FROM Claim WHERE ClaimID = NEW.ClaimID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_policy_status
AFTER UPDATE OF Status ON Claim
FOR EACH ROW
WHEN (NEW.Status = 'Closed')
EXECUTE FUNCTION update_policy_status();


-- 6. Identify agent with the highest total policy value

CREATE VIEW AgentHighestPolicyValue AS
SELECT a.AgentID, a.FullName, SUM(p.Premium) AS TotalValue
FROM Agent a
JOIN Policy p ON a.AgentID = p.AgentID
GROUP BY a.AgentID, a.FullName
ORDER BY TotalValue DESC
LIMIT 1;

-- 7. View showing claims by approval rate

CREATE VIEW ClaimApprovalRate AS
SELECT Decision, COUNT(*) AS Total, 
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ClaimAssessment), 2) AS Percentage
FROM ClaimAssessment
GROUP BY Decision;

SELECT * FROM ClaimApprovalRate ;

-- 8. Trigger to auto-update claim status after payment

DROP FUNCTION IF EXISTS update_policy_status() CASCADE;

CREATE OR REPLACE FUNCTION update_policy_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Policy
    SET Status = 'Closed'
    WHERE PolicyID = (SELECT PolicyID FROM Claim WHERE ClaimID = NEW.ClaimID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_policy_status ON Claim;

CREATE TRIGGER trg_update_policy_status
AFTER UPDATE OF Status ON Claim
FOR EACH ROW
WHEN (NEW.Status = 'Closed')
EXECUTE FUNCTION update_policy_status();

