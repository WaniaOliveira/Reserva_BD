create database reservasBDAula;
use reservasBDAula;

CREATE TABLE cliente (
idcliente INT PRIMARY KEY AUTO_INCREMENT,
nome VARCHAR(100) NOT NULL,
cpf VARCHAR(14) UNIQUE NOT NULL,
email VARCHAR(100),
uf CHAR(2)
);

INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Ana Silva', '123.456.789-01', 'ana.silva@email.com', 'SP');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Bruno Costa', '234.567.890-12', 'bruno.costa@email.com', 'SP');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Carla Souza', '345.678.901-23', 'carla.souza@email.com', 'SP');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Diego Martins', '456.789.012-34', 'diego.martins@email.com', 'RJ');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Elisa Ferreira', '567.890.123-45', 'elisa.ferreira@email.com', 'MG');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Fernando Lima', '678.901.234-56', 'fernando.lima@email.com', 'MG');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Gabriela Rocha', '789.012.345-67', 'gabriela.rocha@email.com', 'MG');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Hugo Almeida', '890.123.456-78', 'hugo.almeida@email.com', 'RS');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('Isabela Rios', '901.234.567-89', 'isabela.rios@email.com', 'BA');
INSERT INTO cliente (nome, cpf, email, uf) VALUES ('João Pedro', '012.345.678-90', 'joao.pedro@email.com', 'BA');

-- CONSULTA: clientes do estado BA
SELECT * FROM cliente WHERE uf = 'BA';

-- ALTERAÇÃO: atualizar o cliente 3
UPDATE cliente
SET nome = 'Carla Mendes',
email = 'carla.mendes@novoemail.com',
uf = 'RJ'
WHERE idcliente = 3;

-- EXCLUSÃO: remover o cliente 10
DELETE FROM cliente WHERE idcliente = 10;

-- criar tabela reserva
CREATE TABLE reserva (
idreserva INT PRIMARY KEY AUTO_INCREMENT,
idcliente INT,
tipo_acomodacao ENUM('Suite', 'Apartamento') NOT NULL,
numero INT NOT NULL, -- numero do apart ou suite
entrada DATE,
saida DATE,
diaria DECIMAL(10,2),
total DECIMAL(10,2),
pagamento VARCHAR(50), -- tipo pagamento (cartão, pix,...)
FOREIGN KEY (idcliente) REFERENCES cliente(idcliente)
);

GATILHO para calcular a diária de acordo com o tipo de reserva.
DELIMITER $$
CREATE TRIGGER set_diaria_before_insert
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
IF NEW.tipo_acomodacao = 'Apartamento' THEN
SET NEW.diaria = 200.00;
ELSEIF NEW.tipo_acomodacao =
'Suite' THEN
SET NEW.diaria = 250.00;
END IF;
-- Calcular total automaticamente (número de dias * diária)
SET NEW.total = DATEDIFF(NEW.saida, NEW.entrada) * NEW.diaria;
END$$
DELIMITER ;

-- criar um STORED PROCEDURE com o retorno do ID da reserva.
-- Sistema de Reservas
DELIMITER $$
CREATE PROCEDURE inserir_reserva (
IN p_idcliente INT,
IN p_tipo_acomodacao ENUM('Suite', 'Apartamento'),
IN p_numero INT,
IN p_entrada DATE,
IN p_saida DATE,
IN p_pagamento VARCHAR(50),
OUT p_idreserva INT
)
BEGIN
INSERT INTO reserva (
idcliente,
tipo_acomodacao,
numero,
entrada,
saida,
pagamento
)

VALUES (
p_idcliente,
p_tipo_acomodacao,
p_numero,
p_entrada,
p_saida,
p_pagamento
);
SET p_idreserva = LAST_INSERT_ID();
END$$
DELIMITER ;

-- Inserir uma reserva e obter o retorno do ID
-- Declarar uma variável para armazenar o ID retornado
SET @id_reserva = 0;
-- Chamar a procedure passando os parâmetros e a variável de saída
CALL inserir_reserva(5,
'Suite', 204,
'2025-08-01', '2025-08-05', 'cartão', @id_reserva);
-- Ver o ID gerado
SELECT @id_reserva;

-- vamos limpar a tabela reserva e zerar o id.
TRUNCATE TABLE reserva;

-- Um procedimento para
-- verificar conflito de reserva.

DELIMITER $$
CREATE PROCEDURE verificar_conflito_reserva (
IN p_numero INT,
IN p_entrada DATE,
IN p_saida DATE,
OUT p_conflito INT
)
BEGIN
SELECT COUNT(*) INTO p_conflito
FROM reserva
WHERE numero = p_numero
AND (
(p_entrada BETWEEN entrada AND saida)
OR (p_saida BETWEEN entrada AND saida)
OR (entrada BETWEEN p_entrada AND p_saida)
);
-- Se houver conflito (count > 0), retorna 1, senão 0
SET p_conflito = IF(p_conflito > 0, 1, 0);
END$$
DELIMITER ;

-- Utilizar o stored procedure verificar_conflito_reserva

-- Declarar variável para armazenar o resultado
SET @conflito = 0;
-- Verificar se o quarto 201 está disponível de 2025-08-03 a 2025-08-06
CALL verificar_conflito_reserva(201,
'2025-08-03', '2025-08-06', @conflito);
-- Ver o resultado
SELECT @conflito;

-- criar um novo procedimento para verificar o conflito e, se for satisfatório (valor zero),
-- vamos executar o inserir_reserva.


DELIMITER $$
CREATE PROCEDURE reserva_com_condicional (
IN p_idcliente INT,
IN p_tipo_acomodacao ENUM('Suite', 'Apartamento'),
IN p_numero INT,
IN p_entrada DATE,
IN p_saida DATE,
IN p_pagamento VARCHAR(50),
OUT p_idreserva INT
)
BEGIN
DECLARE conflito INT DEFAULT 0;
CALL verificar_conflito_reserva(p_numero, p_entrada, p_saida, conflito);
IF conflito = 0 THEN
CALL inserir_reserva(p_idcliente, p_tipo_acomodacao, p_numero, p_entrada, p_saida, p_pagamento,
p_idreserva);
ELSE
SET p_idreserva = NULL;
END IF;
END$$
DELIMITER ;

-- Executando o novo procedimento

SET @id_reserva = 0;
-- Chamar a procedure passando os parâmetros e a variável de saída
CALL reserva_com_condicional(5,
'Suite', 204,
'2025-08-01', '2025-08-05', 'cartão', @id_reserva);
-- Ver o ID gerado
SELECT @id_reserva;

SET @id_reserva = 0;
CALL reserva_com_condicional(5,
'Suite', 205,
'2025-08-04', '2025-08-10', 'cartão', @id_reserva);
-- Ver o ID gerado
SELECT @id_reserva;
-- Vamos criar um stored procedure para buscar apartamentos e suítes
-- disponíveis em uma determinada data.
-- Antes vamos criar uma tabela quarto.

CREATE TABLE quarto (
numero INT PRIMARY KEY,
tipo ENUM('Suite', 'Apartamento') NOT NULL);

-- Carregar a tabela quarto.
-- Sistema de Reservas
INSERT INTO quarto (numero, tipo) VALUES
(201,
'Suite'),
(202,
'Suite'),
(203,
'Suite'),
(204,
'Suite'),
(205,
'Suite'),
(206, 'Apartamento'),
(207, 'Apartamento'),
(208, 'Apartamento'),
(209, 'Apartamento'),
(210, 'Apartamento');
DELIMITER $$
CREATE PROCEDURE listar_quartos_disponiveis (
IN p_entrada DATE, IN p_saida DATE
)
BEGIN
SELECT q.numero, q.tipo
FROM quarto q
WHERE NOT EXISTS (
SELECT 1
FROM reserva r
WHERE r.numero = q.numero
AND (
(p_entrada BETWEEN r.entrada AND r.saida)
OR (p_saida BETWEEN r.entrada AND r.saida)
OR (r.entrada BETWEEN p_entrada AND p_saida)
)
)
ORDER BY q.numero;
END$$
DELIMITER ;

select * from reserva;

-- comando que lista a quantidade de quartos disponiveis

CALL listar_quartos_disponiveis('2025-08-02', '2025-08-09');

CALL listar_quartos_disponiveis('2025-08-06', '2025-08-09');


