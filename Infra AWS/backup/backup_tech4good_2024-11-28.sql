-- =====================================================
-- BACKUP COMPLETO DO BANCO DE DADOS tech4good
-- Data: 2024-11-28
-- Arquivo: backup_tech4good_2024-11-28.sql
-- =====================================================

-- Configurações iniciais para o backup
SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

-- =====================================================
-- ESTRUTURA DO BANCO DE DADOS
-- =====================================================

-- Remover banco se existir e criar novo
DROP DATABASE IF EXISTS tech4good;
CREATE DATABASE tech4good;
USE tech4good;

-- =====================================================
-- CRIAÇÃO DAS TABELAS
-- =====================================================

-- Tabela: endereco
CREATE TABLE endereco(
	id_endereco INT PRIMARY KEY AUTO_INCREMENT,
    cep CHAR(8) NOT NULL,
    logradouro VARCHAR(100) NOT NULL,
    numero INT NOT NULL,
    complemento VARCHAR(50),
    bairro VARCHAR(80),
    cidade VARCHAR(80) NOT NULL,
    estado CHAR(2) NOT NULL,
    moradia VARCHAR(50) NOT NULL,
    tipo_moradia VARCHAR(50) NOT NULL,
    data_entrada DATE NOT NULL,
    data_saida DATE,
    tipo_cesta VARCHAR(12) NOT NULL,
    status VARCHAR(30)
);

-- Tabela: beneficiado
CREATE TABLE beneficiado(
	id_beneficiado INT AUTO_INCREMENT,
	cpf CHAR(11) UNIQUE,
	nome VARCHAR(100) NOT NULL,
	rg VARCHAR(9) NOT NULL,
	data_nascimento DATE NOT NULL,
	naturalidade VARCHAR(50) NOT NULL,
	telefone VARCHAR(11) NOT NULL,
	estado_civil VARCHAR(30) NOT NULL,
	escolaridade VARCHAR(40) NOT NULL,
	profissao VARCHAR(50),
	renda_mensal DECIMAL(7,2),
	empresa VARCHAR(60),
	cargo VARCHAR(40),
	religiao VARCHAR(40),
	quantidade_dependentes INT NOT NULL,
	foto_beneficiado MEDIUMBLOB,
    fk_endereco INT,
    FOREIGN KEY (fk_endereco) REFERENCES endereco(id_endereco),
    PRIMARY KEY (id_beneficiado, cpf, fk_endereco)
) AUTO_INCREMENT = 1;

-- Tabela: auxilio_governamental
CREATE TABLE auxilio_governamental(
	id_auxilio INT PRIMARY KEY,
	tipo VARCHAR(50)
);

-- Tabela: beneficiado_has_auxilio
CREATE TABLE beneficiado_has_auxilio(
	fk_auxilio INT,
	fk_id_beneficiado INT,
	fk_cpf CHAR(11),
    fk_endereco INT,
	PRIMARY KEY (fk_auxilio, fk_id_beneficiado, fk_cpf, fk_endereco),
	FOREIGN KEY (fk_auxilio) REFERENCES auxilio_governamental(id_auxilio),
	FOREIGN KEY (fk_id_beneficiado, fk_cpf, fk_endereco) REFERENCES beneficiado(id_beneficiado, cpf, fk_endereco)
);

-- Tabela: tipo_morador
CREATE TABLE tipo_morador(
	id_tipo_morador INT PRIMARY KEY,
    quantidade_crianca INT,
    quantidade_adolescente INT,
    quantidade_jovem INT,
    quantidade_idoso INT,
    quantidade_gestante INT,
    quantidade_deficiente INT,
    quantidade_outros INT,
    fk_beneficiado INT,
    fk_cpf CHAR(11),
    fk_endereco INT,
    FOREIGN KEY (fk_beneficiado, fk_cpf) REFERENCES beneficiado(id_beneficiado, cpf),
    FOREIGN KEY (fk_endereco) REFERENCES endereco(id_endereco)
);

-- Tabela: filho_beneficiado
CREATE TABLE filho_beneficiado(
	id_filho_beneficiado INT,
    data_nascimento DATE NOT NULL,
    is_estudante TINYINT NOT NULL,
    has_creche TINYINT NOT NULL,
    fk_beneficiado INT,
    fk_cpf CHAR(11),
    fk_endereco INT,
    FOREIGN KEY (fk_beneficiado, fk_cpf, fk_endereco) REFERENCES beneficiado(id_beneficiado, cpf, fk_endereco),
    PRIMARY KEY (id_filho_beneficiado, fk_beneficiado, fk_cpf, fk_endereco)
);

-- Tabela: fila_espera
CREATE TABLE fila_espera(
	id_fila INT PRIMARY KEY,
    data_entrada DATE NOT NULL,
    data_saida DATE,
    fk_endereco INT,
    FOREIGN KEY (fk_endereco) REFERENCES endereco(id_endereco)
);

-- Tabela: voluntario
CREATE TABLE voluntario(
	id_voluntario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    cpf CHAR(11),
    telefone VARCHAR(11),
    senha VARCHAR(255),
    email VARCHAR(80),
    administrador TINYINT
);

-- Tabela: cesta
CREATE TABLE cesta(
	id_cesta INT PRIMARY KEY,
    tipo VARCHAR(5) NOT NULL,
    peso_kg DECIMAL(3,2) NOT NULL,
    data_entrada DATE NOT NULL,
    quantidade_cesta INT
);

-- Tabela: entrega
CREATE TABLE entrega(
	id_entrega INT,
    data_retirada DATE,
    proxima_retirada DATE,
    fk_voluntario INT,
	fk_endereco INT,
    fk_cesta INT,
    FOREIGN KEY (fk_voluntario) REFERENCES voluntario(id_voluntario),
    FOREIGN KEY (fk_endereco) REFERENCES endereco(id_endereco),
    FOREIGN KEY (fk_cesta) REFERENCES cesta(id_cesta)
);

-- =====================================================
-- CONSTRAINTS ADICIONAIS
-- =====================================================

ALTER TABLE beneficiado ADD CONSTRAINT CHK_estado_civil 
	CHECK (estado_civil IN ('SOLTEIRO', 'CASADO', 'VIÚVO', 'DIVORCIADO', 'SEPARADO JUDICIALMENTE'));

-- =====================================================
-- DADOS - INSERÇÃO COMPLETA
-- =====================================================

-- DADOS: endereco (50 registros)
INSERT INTO endereco (cep, logradouro, numero, complemento, bairro, cidade, estado, moradia, tipo_moradia, data_entrada, data_saida, tipo_cesta, status) VALUES
('01503000', 'Rua Galvão Bueno', 120, 'Apto 12', 'Liberdade', 'São Paulo', 'SP', 'Própria', 'Apartamento', '2024-03-12', NULL, 'Cesta Básica', 'Ativo'),
('01504010', 'Rua dos Estudantes', 88, NULL, 'Liberdade', 'São Paulo', 'SP', 'Alugada', 'Kitnet', '2024-04-20', NULL, 'Kit', 'Ativo'),
('01001000', 'Praça da Sé', 45, NULL, 'Sé', 'São Paulo', 'SP', 'Própria', 'Casa', '2023-12-10', '2025-01-10', 'Cesta Básica', 'Inativo'),
('01310940', 'Avenida Paulista', 1578, 'Apto 81', 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-01-15', NULL, 'Cesta Básica', 'Em Espera'),
('01032010', 'Rua Aurora', 310, 'Fundos', 'República', 'São Paulo', 'SP', 'Cedida', 'Casa', '2024-02-05', NULL, 'Kit', 'Ativo'),
('01311000', 'Rua Itapeva', 200, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Kitnet', '2024-03-01', '2025-02-01', 'Kit', 'Inativo'),
('01042000', 'Rua dos Gusmões', 280, 'Casa 2', 'Santa Ifigênia', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-05-01', NULL, 'Cesta Básica', 'Ativo'),
('01310000', 'Rua Frei Caneca', 450, NULL, 'Consolação', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-01-10', NULL, 'Cesta Básica', 'Ativo'),
('01227000', 'Rua Marquês de Itu', 233, NULL, 'Vila Buarque', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2023-11-22', NULL, 'Kit', 'Em Espera'),
('01506000', 'Rua da Glória', 70, 'Sobrado', 'Liberdade', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-02-14', '2025-02-20', 'Cesta Básica', 'Inativo'),
('01045000', 'Rua Vitória', 102, NULL, 'Santa Ifigênia', 'São Paulo', 'SP', 'Alugada', 'Casa', '2024-06-05', NULL, 'Cesta Básica', 'Ativo'),
('01319000', 'Rua Treze de Maio', 940, 'Apto 42', 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-04-10', NULL, 'Cesta Básica', 'Em Espera'),
('01323000', 'Rua Rocha', 56, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2024-02-25', NULL, 'Kit', 'Ativo'),
('01023000', 'Rua Quintino Bocaiúva', 210, NULL, 'Sé', 'São Paulo', 'SP', 'Própria', 'Casa', '2023-12-12', '2025-01-30', 'Cesta Básica', 'Inativo'),
('01508000', 'Rua São Joaquim', 220, 'Casa 1', 'Liberdade', 'São Paulo', 'SP', 'Alugada', 'Casa', '2024-05-10', NULL, 'Cesta Básica', 'Ativo'),
('01034010', 'Rua General Couto de Magalhães', 95, NULL, 'Santa Ifigênia', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2024-03-05', NULL, 'Kit', 'Em Espera'),
('01311030', 'Rua Carlos Sampaio', 128, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-01-25', NULL, 'Cesta Básica', 'Ativo'),
('01222000', 'Rua das Palmeiras', 300, NULL, 'Santa Cecília', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-04-01', NULL, 'Cesta Básica', 'Ativo'),
('01512000', 'Rua Tamandaré', 780, 'Fundos', 'Liberdade', 'São Paulo', 'SP', 'Alugada', 'Casa', '2024-02-18', NULL, 'Kit', 'Em Espera'),
('01015000', 'Rua Benjamin Constant', 65, NULL, 'Sé', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2023-10-15', '2024-12-10', 'Kit', 'Inativo'),
('01025000', 'Rua Direita', 15, 'Sobreloja', 'Sé', 'São Paulo', 'SP', 'Própria', 'Apartamento', '2024-03-08', NULL, 'Cesta Básica', 'Ativo'),
('01331000', 'Rua Augusta', 1120, NULL, 'Consolação', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-05-10', NULL, 'Cesta Básica', 'Em Espera'),
('01221000', 'Rua Martim Francisco', 98, NULL, 'Santa Cecília', 'São Paulo', 'SP', 'Cedida', 'Casa', '2024-02-28', NULL, 'Kit', 'Ativo'),
('01027000', 'Rua Senador Feijó', 30, 'Casa 3', 'Sé', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-01-20', NULL, 'Cesta Básica', 'Ativo'),
('01520000', 'Rua do Lavapés', 445, NULL, 'Cambuci', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-04-15', NULL, 'Cesta Básica', 'Ativo'),
('01523000', 'Rua Barão de Iguape', 190, 'Apto 31', 'Liberdade', 'São Paulo', 'SP', 'Cedida', 'Apartamento', '2024-05-18', NULL, 'Kit', 'Em Espera'),
('01228000', 'Rua Major Sertório', 257, NULL, 'Vila Buarque', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-03-22', NULL, 'Cesta Básica', 'Ativo'),
('01047000', 'Rua dos Timbiras', 390, NULL, 'Santa Ifigênia', 'São Paulo', 'SP', 'Alugada', 'Kitnet', '2024-06-10', NULL, 'Kit', 'Ativo'),
('01321000', 'Rua Santo Antônio', 600, 'Apto 24', 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-01-30', '2025-02-28', 'Cesta Básica', 'Inativo'),
('01232000', 'Rua Gravataí', 150, 'Casa 2', 'Santa Cecília', 'São Paulo', 'SP', 'Cedida', 'Casa', '2024-03-10', NULL, 'Cesta Básica', 'Ativo'),
('01514000', 'Rua São Paulo', 72, NULL, 'Cambuci', 'São Paulo', 'SP', 'Própria', 'Kitnet', '2024-04-11', NULL, 'Kit', 'Ativo'),
('01036000', 'Rua dos Andradas', 122, NULL, 'Sé', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-02-17', NULL, 'Cesta Básica', 'Ativo'),
('01326000', 'Rua Herculano de Freitas', 400, 'Fundos', 'Bela Vista', 'São Paulo', 'SP', 'Cedida', 'Casa', '2024-03-27', NULL, 'Kit', 'Em Espera'),
('01234000', 'Rua Jaguaribe', 520, NULL, 'Vila Buarque', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-01-12', '2025-01-20', 'Cesta Básica', 'Inativo'),
('01525000', 'Rua Pires da Mota', 300, NULL, 'Cambuci', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-02-09', NULL, 'Cesta Básica', 'Ativo'),
('01032020', 'Rua Santa Efigênia', 500, 'Apto 32', 'Santa Ifigênia', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-05-22', NULL, 'Cesta Básica', 'Ativo'),
('01511000', 'Rua Conselheiro Furtado', 640, 'Casa 4', 'Liberdade', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-04-05', NULL, 'Cesta Básica', 'Em Espera'),
('01033000', 'Rua Barão de Paranapiacaba', 70, NULL, 'Sé', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2023-12-19', NULL, 'Kit', 'Ativo'),
('01239000', 'Rua Baronesa de Itu', 211, NULL, 'Santa Cecília', 'São Paulo', 'SP', 'Própria', 'Casa', '2024-02-13', '2025-01-25', 'Cesta Básica', 'Inativo'),
('01324000', 'Rua Maestro Cardim', 1100, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-06-11', NULL, 'Cesta Básica', 'Ativo'),
('01530000', 'Rua Muniz de Souza', 600, 'Casa 2', 'Cambuci', 'São Paulo', 'SP', 'Cedida', 'Casa', '2024-03-25', NULL, 'Kit', 'Ativo'),
('01230000', 'Rua General Jardim', 199, 'Apto 22', 'Vila Buarque', 'São Paulo', 'SP', 'Própria', 'Apartamento', '2024-01-18', NULL, 'Cesta Básica', 'Em Espera'),
('01042020', 'Rua Vitória', 260, NULL, 'Santa Ifigênia', 'São Paulo', 'SP', 'Alugada', 'Kitnet', '2024-02-03', NULL, 'Kit', 'Ativo'),
('01332000', 'Rua Haddock Lobo', 145, NULL, 'Consolação', 'São Paulo', 'SP', 'Própria', 'Apartamento', '2024-03-18', NULL, 'Cesta Básica', 'Ativo'),
('01229000', 'Rua Rego Freitas', 80, 'Sobreloja', 'Vila Buarque', 'São Paulo', 'SP', 'Alugada', 'Casa', '2024-01-22', '2025-03-01', 'Cesta Básica', 'Inativo'),
('01533000', 'Rua Bueno de Andrade', 520, NULL, 'Cambuci', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2024-05-19', NULL, 'Kit', 'Ativo'),
('01043000', 'Rua Timbiras', 312, 'Apto 52', 'Santa Ifigênia', 'São Paulo', 'SP', 'Alugada', 'Apartamento', '2024-04-27', NULL, 'Cesta Básica', 'Em Espera'),
('01321020', 'Rua Dr. Plínio Barreto', 48, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Cedida', 'Kitnet', '2024-02-07', NULL, 'Kit', 'Ativo'),
('01002000', 'Rua XV de Novembro', 100, NULL, 'Sé', 'São Paulo', 'SP', 'Própria', 'Casa', '2023-11-05', '2025-02-15', 'Cesta Básica', 'Inativo'),
('01002001', 'Rua Dr. Plínio Barreto', 101, NULL, 'Bela Vista', 'São Paulo', 'SP', 'Própria', 'Casa', '2023-11-06', '2025-02-16', 'Kit', 'Inativo');

-- DADOS: auxilio_governamental (4 registros)
INSERT INTO auxilio_governamental (id_auxilio, tipo) VALUES
(1, 'Bolsa Família'),
(2, 'Auxílio Emergencial'),
(3, 'Pé de Meia'),
(4, 'Auxílio Gás');

-- DADOS: voluntario (11 registros incluindo Maria)
INSERT INTO voluntario (nome, cpf, telefone, senha, email, administrador) VALUES
('Maria', '11122233300', '11917176262', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'maria.silva@tech4good.org', NULL),
('Ana Clara Pereira', '12345678901', '11912345678', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'ana.pereira@tech4good.org', 1),
('João Carlos Santos', '23456789012', '11923456789', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'joao.santos@tech4good.org', 0),
('Fernanda Lima Costa', '34567890123', '11934567890', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'fernanda.costa@tech4good.org', 0),
('Ricardo Oliveira', '45678901234', '11945678901', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'ricardo.oliveira@tech4good.org', 1),
('Patrícia Almeida', '56789012345', '11956789012', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'patricia.almeida@tech4good.org', 0),
('Carlos Eduardo Silva', '67890123456', '11967890123', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'carlos.silva@tech4good.org', 0),
('Luciana Rodrigues', '78901234567', '11978901234', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'luciana.rodrigues@tech4good.org', 1),
('Bruno Fernandes', '89012345678', '11989012345', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'bruno.fernandes@tech4good.org', 0),
('Mariana Souza', '90123456789', '11990123456', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'mariana.souza@tech4good.org', 0),
('Gabriel Nascimento', '01234567890', '11901234567', '$2a$12$olbYENKfstBLb0G8CueY1OGBmfusjuiV8F/5V5SVrFhTaj9qAviM2', 'gabriel.nascimento@tech4good.org', 1);

-- DADOS: cesta (20 registros)
INSERT INTO cesta (id_cesta, tipo, peso_kg, data_entrada, quantidade_cesta) VALUES
(1, 'BASIC', 9.50, '2024-01-15', 250),
(2, 'BASIC', 9.75, '2024-02-10', 180),
(3, 'BASIC', 9.25, '2024-03-12', 200),
(4, 'BASIC', 9.00, '2024-04-08', 160),
(5, 'BASIC', 9.80, '2024-05-14', 190),
(6, 'BASIC', 9.60, '2024-06-11', 175),
(7, 'BASIC', 9.90, '2024-07-09', 210),
(8, 'BASIC', 9.40, '2024-08-13', 165),
(9, 'BASIC', 9.65, '2024-09-10', 185),
(10, 'BASIC', 9.85, '2024-10-08', 195),
(11, 'KIT', 5.25, '2024-01-15', 150),
(12, 'KIT', 5.50, '2024-02-10', 120),
(13, 'KIT', 5.75, '2024-03-12', 140),
(14, 'KIT', 5.00, '2024-04-08', 110),
(15, 'KIT', 5.30, '2024-05-14', 130),
(16, 'KIT', 5.60, '2024-06-11', 125),
(17, 'KIT', 5.80, '2024-07-09', 145),
(18, 'KIT', 5.10, '2024-08-13', 115),
(19, 'KIT', 5.40, '2024-09-10', 135),
(20, 'KIT', 5.70, '2024-10-08', 140);

-- =====================================================
-- FINALIZAÇÃO
-- =====================================================

SET FOREIGN_KEY_CHECKS=1;
COMMIT;

-- =====================================================
-- FIM DO BACKUP
-- Data: 2024-11-28
-- =====================================================