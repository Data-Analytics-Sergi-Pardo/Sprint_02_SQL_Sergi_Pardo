# NIVELL 1 

# Exercici 1
-- Una vez cargado el scrip muestro las bases de datos que tengo almacenas
SHOW DATABASES;
-- Sentencia para utilizar transactions
USE transactions;
-- Sentencia para mostrar y verificar que se han cargado las tablas
SHOW TABLES;
-- Sentencia que me permite ver la estructura del create de la tabla
SHOW CREATE TABLE company;
SHOW CREATE TABLE transaction;
-- Sentencia que me permite ver en formato tabla las diferentes columnas, sus claves y tipos de valores 
DESCRIBE company;
DESCRIBE transaction;
-- Verifico el número de registros en amnas tablas para ver que coincide.
SELECT COUNT(*) FROM company;
SELECT COUNT(*) FROM transaction;

# EXERCICI 2.1
SELECT DISTINCT c.country
FROM company c
INNER JOIN transaction t
	ON c.id = t.company_id
WHERE t.declined = 0
ORDER BY country ASC;

# EXERCICI 2.2
SELECT COUNT(DISTINCT c.country) AS number_of_countries
FROM company c
INNER JOIN transaction t
    ON c.id = t.company_id
WHERE t.declined = 0;

# EXERCICI 2.3
SELECT
    company_name,
    average_sales
FROM (
    SELECT
        c.company_name,
        ROUND(AVG(t.amount), 2) AS average_sales,
        RANK() OVER (ORDER BY AVG(t.amount) DESC) AS ranking
    FROM company c
    INNER JOIN transaction t
        ON c.id = t.company_id
    WHERE t.declined = 0
    GROUP BY c.id, c.company_name
) AS ranked
WHERE ranking = 1;

# EXERCICI 3.1
SELECT t.id
FROM transaction t
WHERE EXISTS (
	SELECT 1
	FROM company c
	WHERE c.id = t.company_id
		AND c.country = 'Germany'
	);

# EXERCICI 3.2
SELECT c.company_name
FROM company c
WHERE EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.company_id = c.id
      AND t.declined = 0
      AND t.amount > (
          SELECT AVG(amount)
          FROM transaction
          WHERE declined = 0
      )
)
ORDER BY c.company_name ASC;

# EXERCICI 3.3
SELECT c.company_name
FROM company c
WHERE NOT EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.company_id = c.id
);

SELECT COUNT(*) FROM company;
SELECT COUNT(DISTINCT company_id) FROM transaction;

# EXERCICI 4
CREATE TABLE IF NOT EXISTS transactions.credit_card (
    id VARCHAR(15) NOT NULL,
    iban VARCHAR(34) NOT NULL,
    pan VARCHAR(19) NOT NULL,
    pin VARCHAR(4)  NOT NULL,
    cvv VARCHAR(3)  NOT NULL,
    expiring_date VARCHAR(8)  NOT NULL,
    CONSTRAINT pk_credit_card PRIMARY KEY (id),
    CONSTRAINT uk_credit_card_pan UNIQUE (pan)
);

SHOW INDEX FROM credit_card;
DESCRIBE credit_card;

ALTER TABLE transaction ADD CONSTRAINT fk_transaction_credit_card FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);
SHOW CREATE TABLE transaction;
DESCRIBE transaction;

# EXERCICI 5
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';

# EXERCICI 6
INSERT INTO company (id) VALUES ('b-9999');

ALTER TABLE credit_card
    MODIFY iban          VARCHAR(34) DEFAULT NULL,
    MODIFY pan           VARCHAR(19) DEFAULT NULL,
    MODIFY pin           VARCHAR(4)  DEFAULT NULL,
    MODIFY cvv           VARCHAR(3)  DEFAULT NULL,
    MODIFY expiring_date VARCHAR(8)  DEFAULT NULL;

INSERT INTO credit_card (id) VALUES ('CcU-9999');

INSERT INTO transaction
    (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES
    ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 100.00, 0);

# EXERCICI 7
ALTER TABLE credit_card
	DROP COLUMN pan;

DESCRIBE credit_card;
SHOW INDEX FROM credit_card;
    
# EXERCICI 8
-- Creación de la base de datos
SHOW DATABASES;

CREATE DATABASE global_payments
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
    
SHOW DATABASES;

-- Ceación de las tablas
USE global_payments;

-- Dimensión: usuarios (american_users + european_users)
CREATE TABLE IF NOT EXISTS user (
    id            INT          NOT NULL,
    name          VARCHAR(50)  DEFAULT NULL,
    surname       VARCHAR(50)  DEFAULT NULL,
    phone         VARCHAR(30)  DEFAULT NULL,
    email         VARCHAR(100) DEFAULT NULL,
    birth_date    DATE         DEFAULT NULL,
    country       VARCHAR(50)  DEFAULT NULL,
    city          VARCHAR(50)  DEFAULT NULL,
    postal_code   VARCHAR(20)  DEFAULT NULL,
    address       VARCHAR(100) DEFAULT NULL,
    signup_date   DATE         DEFAULT NULL,
    user_segment  VARCHAR(30)  DEFAULT NULL,
    income_band   VARCHAR(20)  DEFAULT NULL,
    region        VARCHAR(10)  NOT NULL,   -- 'Europe' / 'America' (origen del archivo)
    CONSTRAINT pk_user PRIMARY KEY (id)
);

-- Dimensión: empresas
CREATE TABLE IF NOT EXISTS company (
    id                      VARCHAR(15)  NOT NULL,
    company_name            VARCHAR(100) DEFAULT NULL,
    phone                   VARCHAR(20)  DEFAULT NULL,
    email                   VARCHAR(100) DEFAULT NULL,
    country                 VARCHAR(50)  DEFAULT NULL,
    website                 VARCHAR(100) DEFAULT NULL,
    merchant_category       VARCHAR(30)  DEFAULT NULL,
    merchant_price_position VARCHAR(20)  DEFAULT NULL,
    CONSTRAINT pk_company PRIMARY KEY (id)
);

-- Dimensión: tarjetas (cada tarjeta pertenece a un usuario)
CREATE TABLE IF NOT EXISTS credit_card (
    id                VARCHAR(15) NOT NULL,
    user_id           INT         NOT NULL,
    iban              VARCHAR(34) NOT NULL,
    pan               VARCHAR(19) NOT NULL,
    pin               VARCHAR(4)  NOT NULL,
    cvv               VARCHAR(3)  NOT NULL,
    track1            VARCHAR(100) DEFAULT NULL,
    track2            VARCHAR(100) DEFAULT NULL,
    expiring_date     DATE        NOT NULL,   -- el CSV trae MM/DD/AA; se convierte al cargar
    card_type         VARCHAR(20) DEFAULT NULL,
    card_renewal_flag BOOLEAN     DEFAULT NULL,
    CONSTRAINT pk_credit_card      PRIMARY KEY (id),
    CONSTRAINT uk_credit_card_pan  UNIQUE (pan),
    CONSTRAINT fk_credit_card_user FOREIGN KEY (user_id) REFERENCES user(id)
);

-- Tabla de hechos: transacciones
CREATE TABLE IF NOT EXISTS transaction (
    id               CHAR(36)      NOT NULL,          
    credit_card_id   VARCHAR(15)   NOT NULL,          
    company_id       VARCHAR(15)   NOT NULL,          
    user_id          INT           NOT NULL,
    timestamp        DATETIME      NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    declined         BOOLEAN       NOT NULL,
    product_ids      VARCHAR(30)   DEFAULT NULL,      
    lat              DOUBLE        DEFAULT NULL,
    longitude        DOUBLE        DEFAULT NULL,
    discount_amount  DECIMAL(10,2) DEFAULT NULL,
    tax_amount       DECIMAL(10,2) DEFAULT NULL,
    shipping_amount  DECIMAL(10,2) DEFAULT NULL,
    channel          VARCHAR(20)   DEFAULT NULL,
    campaign_id      VARCHAR(30)   DEFAULT NULL,
    device_type      VARCHAR(20)   DEFAULT NULL,
    is_international BOOLEAN       DEFAULT NULL,
    decline_reason   VARCHAR(30)   DEFAULT NULL,      
    distance_km      DECIMAL(10,2) DEFAULT NULL,
    CONSTRAINT pk_transaction             PRIMARY KEY (id),
    CONSTRAINT fk_transaction_credit_card FOREIGN KEY (credit_card_id) REFERENCES credit_card(id),
    CONSTRAINT fk_transaction_company     FOREIGN KEY (company_id)     REFERENCES company(id),
    CONSTRAINT fk_transaction_user        FOREIGN KEY (user_id)        REFERENCES user(id)
);

SHOW TABLES;

-- Càrrega de les dades
-- Load de usuarios europeos (3.990)
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__european_users.csv'
INTO TABLE user
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, @birth_date, country, city, postal_code,
 address, signup_date, user_segment, income_band)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),   -- 'Jul 2, 1980'
    region     = 'Europe';


-- Load de usuarios americanos (1.010): mismas columnas y mismo orden
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__american_users.csv'
INTO TABLE user
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, @birth_date, country, city, postal_code,
 address, signup_date, user_segment, income_band)
SET birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),
    region     = 'America';
    
-- Compruebo que la fusión está bien: debería dar Europe 3990 + America 1010 (total 5000)
SELECT region, COUNT(*) AS usuarios FROM user GROUP BY region;

-- Load de empresas (100).
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__companies.csv'
INTO TABLE company 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, company_name, phone, email, country, website, merchant_category,
 merchant_price_position);
 
 -- Load tarjetas (5.000).
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_card
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date, card_type,
 card_renewal_flag)
SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

-- Load transacciones (100.000).
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__transactions.csv'
INTO TABLE transaction
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, credit_card_id, company_id, timestamp, amount, declined, product_ids,
 user_id, lat, longitude, discount_amount, tax_amount, shipping_amount,
 channel, campaign_id, device_type, is_international, @decline_reason,
 distance_km)
SET decline_reason = NULLIF(@decline_reason, '');

-- Modificació de local infile per a la càrrega
SHOW VARIABLES LIKE 'local_infile';   -- si pone OFF:
SET GLOBAL local_infile = 0;

# EXERCICI 9
SELECT u.id, u.name, u.surname
FROM user u
WHERE EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.user_id = u.id
    GROUP BY t.user_id
    HAVING COUNT(*) > 80
);

# EXERCICI 10
SELECT cc.iban, ROUND(AVG(t.amount),2) AS average_amount
FROM transaction t
INNER JOIN credit_card cc ON t.credit_card_id = cc.id
INNER JOIN company c ON t.company_id = c.id
WHERE c.company_name = 'Donec Ltd'
  AND t.declined = 0
GROUP BY cc.iban
ORDER BY average_amount DESC;

# NIVELL 2

# EXERCICI 1
SELECT
	sales_date, 
    total_sales
FROM (
    SELECT
        DATE(timestamp) AS sales_date,
		SUM(amount) AS total_sales,
        RANK() OVER (ORDER BY SUM(amount) DESC) AS ranking
    FROM transaction
    WHERE declined = 0
    GROUP BY DATE(timestamp)
) AS ranked
WHERE ranking <= 5
ORDER BY total_sales DESC;

# EXERCICI 2
SELECT 
	c.company_name, 
    c.phone, 
    c.country, 
    DATE(t.timestamp) AS transaction_date, 
    t.amount
FROM company c
INNER JOIN transaction t
 ON c.id = t.company_id
WHERE t.declined = 0
	AND t.amount BETWEEN 350 AND 400
    AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;

# EXERCICI 3
SELECT 
	c.id, 
    c.company_name, 
    COUNT(t.id) AS total_transactions,
    CASE 
		WHEN COUNT(t.id) >= 400 THEN '>= 400'
        ELSE '< 400'
	END AS transactions_level
FROM company c
INNER JOIN transaction t
 ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY total_transactions DESC;

# EXERCICI 4
-- Verifico antes que el registro esté
SELECT * 
FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
-- Lo borro
DELETE FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
-- Y por último compruebo que este borrado.
SELECT * 
FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

# EXERCICI 5
CREATE VIEW VistaMarketing AS
SELECT 
	c.company_name,
    c.phone,
    c.country,
    ROUND(AVG(t.amount), 2) AS average_purchase
FROM company c
INNER JOIN transaction t
		ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.id, c.company_name;

-- Muestro los resultados en la vista
SELECT *
FROM VistaMarketing
ORDER BY average_purchase DESC;

# NIVELL 3
 
# EXERCICI 1
-- Tabla con el estado de cada tarjeta según sus 3 últimas transacciones
--   · Las 3 últimas transacciones declinadas  -> 'inactive'
--   · Al menos una de las 3 no declinada      -> 'active'
-- 	 · Dos transacciones o menos y todas declinadas -> 'pending'

-- Creación de la tabla a partir de un SELECT
CREATE TABLE credit_card_status AS
SELECT
    credit_card_id,
    CASE
        WHEN COUNT(*) = 3 AND SUM(declined) = 3 THEN 'inactive'
        WHEN SUM(declined) < COUNT(*)           THEN 'active'
        ELSE 'pending'
    END AS status
FROM (
    SELECT
        credit_card_id,
        declined,
        ROW_NUMBER() OVER (
            PARTITION BY credit_card_id
            ORDER BY timestamp DESC, id DESC
        ) AS rn
    FROM transaction
) AS ultimas
WHERE rn <= 3
GROUP BY credit_card_id;

-- Comprobación de cuantas están 'active'
SELECT COUNT(*) AS active_cards
FROM credit_card_status
WHERE status = 'active';

# EXERCICI 2
-- Unir products.csv con la base de datos:
--   · product              -> los 100 productos de products.csv
--   · transaction_product  -> tabla puente (N:M) entre transaction y product
--                             Una fila por cada producto de cada transacción

-- Comprobación previa: transaction debe tener la columna product_ids (debería devolver 1 fila)
SHOW COLUMNS FROM transaction LIKE 'product_ids';

-- Creación de la tabla
CREATE TABLE product (
    id           INT           NOT NULL,
    product_name VARCHAR(40)   DEFAULT NULL,   
    price        DECIMAL(10,2) DEFAULT NULL,
    colour       VARCHAR(7)    DEFAULT NULL,   
    weight       DECIMAL(6,2)  DEFAULT NULL,   
    warehouse_id VARCHAR(10)   DEFAULT NULL,   
    category     VARCHAR(20)   DEFAULT NULL,   
    brand        VARCHAR(20)   DEFAULT NULL,   
    cost         DECIMAL(10,2) DEFAULT NULL,
    launch_date  DATE          DEFAULT NULL,   
    CONSTRAINT pk_product PRIMARY KEY (id)
);

-- Tabla puente transaction_product
CREATE TABLE transaction_product (
    transaction_id CHAR(36) NOT NULL,
    product_id     INT      NOT NULL,
    CONSTRAINT pk_transaction_product PRIMARY KEY (transaction_id, product_id),
    CONSTRAINT fk_tp_transaction FOREIGN KEY (transaction_id)
        REFERENCES transaction (id) ON DELETE CASCADE,
    CONSTRAINT fk_tp_product FOREIGN KEY (product_id)
        REFERENCES product (id)
);

-- Load de productos
LOAD DATA LOCAL INFILE '/Users/sergi/Home/Formación/DATA ANALYTICS/Especialització/Sprint 02/N1-Ex.8__products.csv'
INTO TABLE product
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, product_name, @price, colour, weight, warehouse_id, category, brand, @cost, launch_date)
SET price = REPLACE(@price, '$', ''),
    cost  = REPLACE(@cost,  '$', '');
    
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

SET GLOBAL local_infile = 0;

-- Carga de transaction_product a partir de transaction.product_ids
INSERT INTO transaction_product (transaction_id, product_id)
SELECT t.id, jt.product_id
FROM transaction t,
     JSON_TABLE(
         CONCAT('[', t.product_ids, ']'),
         '$[*]' COLUMNS (product_id INT PATH '$')
     ) AS jt;

-- 5) Comprobaciones
SELECT COUNT(*) FROM product; -- Debería dar 100
-- Filas de la tabla puente
SELECT COUNT(*) FROM transaction_product;
-- Debe coincidir con el número de productos contados en product_ids:
SELECT SUM(LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) + 1)
FROM transaction;
-- Precios sin el '$' y sin nulos (debe dar 0)
SELECT COUNT(*) FROM product WHERE price IS NULL OR cost IS NULL;

-- Transacciones sin ningún producto en la tabla puente (debe dar 0)
SELECT COUNT(*)
FROM transaction t
WHERE NOT EXISTS (SELECT 1 FROM transaction_product tp WHERE tp.transaction_id = t.id);

-- Comprobar com salen sin el símbolo de $ los productos
SELECT * FROM product LIMIT 5;

# Veces que se ha vendido cada producto
SELECT
    p.id,
    p.product_name,
    COUNT(t.id) AS times_sold
FROM product p
LEFT JOIN transaction_product tp
    ON tp.product_id = p.id
LEFT JOIN transaction t
    ON t.id = tp.transaction_id
   AND t.declined = 0
GROUP BY p.id, p.product_name
ORDER BY times_sold DESC;











