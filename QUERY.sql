-- =========================================================================
-- SYSTEM:      Football Ticket Booking System
-- ENGINE:      PostgreSQL
-- =========================================================================

DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Matches;
DROP TABLE IF EXISTS Users;

-- =========================================================================
-- 1. CREATE USERS TABLE
-- =========================================================================
CREATE TABLE Users (
    user_id      INT          NOT NULL,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL,
    role         VARCHAR(20)  NOT NULL,
    phone_number VARCHAR(20),                         

    CONSTRAINT pk_users PRIMARY KEY (user_id),        
    CONSTRAINT uq_users_email UNIQUE (email),         
    CONSTRAINT chk_users_role CHECK (role IN ('Ticket Manager', 'Football Fan'))
);

-- =========================================================================
-- 2. CREATE MATCHES TABLE
-- =========================================================================
CREATE TABLE Matches (
    match_id            INT           NOT NULL,
    fixture             VARCHAR(150)  NOT NULL,
    tournament_category VARCHAR(50)   NOT NULL,
    base_ticket_price   NUMERIC(10,2) NOT NULL,
    match_status        VARCHAR(20)   NOT NULL,

    CONSTRAINT pk_matches PRIMARY KEY (match_id),               -- match_id is the Primary Key
    CONSTRAINT chk_matches_price CHECK (base_ticket_price >= 0), -- no negative prices
    CONSTRAINT chk_matches_status CHECK (
        match_status IN ('Available', 'Selling Fast', 'Sold Out', 'Postponed')
    )
);

-- =========================================================================
-- 3. CREATE BOOKINGS TABLE
-- =========================================================================
CREATE TABLE Bookings (
    booking_id     INT           NOT NULL,
    user_id        INT           NOT NULL,
    match_id       INT           NOT NULL,
    seat_number    VARCHAR(10),                 
    payment_status VARCHAR(20),                 
    total_cost     NUMERIC(10,2) NOT NULL,

    CONSTRAINT pk_bookings PRIMARY KEY (booking_id),  -- booking_id is the Primary Key
    CONSTRAINT fk_bookings_user
        FOREIGN KEY (user_id) REFERENCES Users (user_id),   
    CONSTRAINT fk_bookings_match
        FOREIGN KEY (match_id) REFERENCES Matches (match_id), 
    CONSTRAINT chk_bookings_cost CHECK (total_cost >= 0),     -- non-negative cost
    CONSTRAINT chk_bookings_payment CHECK (
        payment_status IN ('Pending', 'Confirmed', 'Cancelled', 'Refunded')
    )
);   


-- =========================================================================
-- DATA SEEDING: USERS
-- =========================================================================
INSERT INTO Users (user_id, full_name, email, role, phone_number) VALUES
(1, 'Tanvir Rahman', 'tanvir@mail.com', 'Football Fan',   '+8801711111111'),
(2, 'Asif Haque',    'asif@mail.com',   'Football Fan',   '+8801722222222'),
(3, 'Sajjad Rahman', 'sajjad@mail.com', 'Ticket Manager', '+8801733333333'),
(4, 'Jannat Ara',    'jannat@mail.com', 'Football Fan',   NULL);

-- =========================================================================
-- DATA SEEDING: MATCHES
-- =========================================================================
INSERT INTO Matches (match_id, fixture, tournament_category, base_ticket_price, match_status) VALUES
(101, 'Real Madrid vs Barcelona', 'Champions League', 150.00, 'Available'),
(102, 'Man City vs Liverpool',    'Premier League',   120.00, 'Selling Fast'),
(103, 'Bayern Munich vs PSG',     'Champions League', 130.00, 'Available'),
(104, 'AC Milan vs Inter Milan',  'Serie A',           90.00, 'Sold Out'),
(105, 'Juventus vs Roma',         'Serie A',           80.00, 'Available');

-- =========================================================================
-- DATA SEEDING: BOOKINGS
-- =========================================================================
INSERT INTO Bookings (booking_id, user_id, match_id, seat_number, payment_status, total_cost) VALUES
(501, 1, 101, 'A-12', 'Confirmed', 150.00),
(502, 1, 102, 'B-04', 'Confirmed', 120.00),
(503, 2, 101, 'A-13', 'Confirmed', 150.00),
(504, 2, 101, NULL,    NULL,       150.00),
(505, 3, 102, 'C-20', 'Pending',   120.00);


-- =========================================================================
-- PART 2: SQL QUERIES
-- =========================================================================

-- -------------------------------------------------------------------------
-- Query 1: All upcoming 'Champions League' matches that are 'Available'.
-- -------------------------------------------------------------------------
SELECT match_id, fixture, base_ticket_price
FROM Matches
WHERE tournament_category = 'Champions League'
  AND match_status = 'Available';

-- -------------------------------------------------------------------------
-- Query 2: Users whose full name starts with 'Tanvir' OR contains 'Haque'
--          (case-insensitive).
-- -------------------------------------------------------------------------
SELECT user_id, full_name, email
FROM Users
WHERE full_name ILIKE 'Tanvir%'
   OR full_name ILIKE '%Haque%';

-- -------------------------------------------------------------------------
-- Query 3: Bookings with a missing (NULL) payment status, shown as
--          'Action Required'.
-- -------------------------------------------------------------------------
SELECT booking_id,
       user_id,
       match_id,
       COALESCE(payment_status, 'Action Required') AS systematic_status
FROM Bookings
WHERE payment_status IS NULL;

-- -------------------------------------------------------------------------
-- Query 4: Booking details enriched with user full name and match fixture.
-- -------------------------------------------------------------------------
SELECT b.booking_id,
       u.full_name,
       m.fixture,
       b.total_cost
FROM Bookings b
INNER JOIN Users   u ON b.user_id  = u.user_id
INNER JOIN Matches m ON b.match_id = m.match_id
ORDER BY b.booking_id;

-- -------------------------------------------------------------------------
-- Query 5: Every user with their booking IDs, including fans who never booked.
-- -------------------------------------------------------------------------
SELECT u.user_id,
       u.full_name,
       b.booking_id
FROM Users u
LEFT JOIN Bookings b ON u.user_id = b.user_id
ORDER BY u.user_id, b.booking_id;

-- -------------------------------------------------------------------------
-- Query 6: Bookings whose total cost is strictly above the average of all.
-- -------------------------------------------------------------------------
SELECT booking_id,
       match_id,
       total_cost
FROM Bookings
WHERE total_cost > (SELECT AVG(total_cost) FROM Bookings)
ORDER BY booking_id;

-- -------------------------------------------------------------------------
-- Query 7: Top 2 most expensive matches by base price, skipping the single
--          most expensive (premium) one.
-- -------------------------------------------------------------------------
SELECT match_id,
       fixture,
       base_ticket_price
FROM Matches
ORDER BY base_ticket_price DESC
LIMIT 2 OFFSET 1;
