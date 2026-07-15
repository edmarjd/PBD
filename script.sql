-- == TABELAS

-- DEPARTAMENTO
CREATE TABLE departamento (
    departamento_id  SERIAL PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL UNIQUE
);

-- CURSO
-- (Departamento 1:N Curso) -> FK em Curso
CREATE TABLE curso (
    curso_id          SERIAL PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL UNIQUE,
    departamento_id   INT NOT NULL,
    FOREIGN KEY (departamento_id) REFERENCES departamento(departamento_id)
    	ON UPDATE CASCADE
);


-- PROFESSOR
-- Curso 1:N Professor -> FK em Professor
CREATE TABLE professor (
    siape             VARCHAR(10) PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL,
    curso_id          INT NOT NULL,
    FOREIGN KEY (curso_id) REFERENCES curso(curso_id)
    	ON DELETE RESTRICT
    	ON UPDATE CASCADE
);


-- ALUNO
-- 1:N Aluno -> FK em Aluno
CREATE TABLE aluno (
    matricula         VARCHAR(20) PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL,
    curso_id          INT NOT NULL,
    FOREIGN KEY (curso_id) REFERENCES curso(curso_id)
    	ON DELETE RESTRICT
      	ON UPDATE CASCADE
);

-- DISCIPLINA
-- (Curso 1:N Disciplina) -> FK em Disciplina
CREATE TABLE disciplina (
    disciplina_id     SERIAL PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL,
    curso_id          INT NOT NULL,
    FOREIGN KEY (curso_id) REFERENCES curso(curso_id)
    	ON DELETE RESTRICT
    	ON UPDATE CASCADE,
    UNIQUE (curso_id, nome)
);

-- TURMA
-- (Disciplina 1:N Turma) -> FK em Turma
CREATE TABLE turma (
    turma_id          SERIAL PRIMARY KEY,
    nome              VARCHAR(100) NOT NULL,
    disciplina_id     INT NOT NULL,
    FOREIGN KEY (disciplina_id) REFERENCES disciplina(disciplina_id)
    	ON DELETE RESTRICT
      	ON UPDATE CASCADE,
    UNIQUE (disciplina_id, nome)
);

-- MINISTRA (Professor N:M Turma)
CREATE TABLE ministra (
    professor_siape   VARCHAR(10) NOT NULL,
    turma_id          INT NOT NULL,
    PRIMARY KEY (professor_siape, turma_id),
    FOREIGN KEY (professor_siape) REFERENCES professor(siape)
    	ON DELETE CASCADE,
    FOREIGN KEY (turma_id) REFERENCES turma (turma_id)
    	ON DELETE CASCADE
);

-- MATRICULA_TURMA (Aluno N:M Turma)
CREATE TABLE matricula_turma (
    aluno_matricula   VARCHAR(20) NOT NULL,
    turma_id          INT NOT NULL,
    PRIMARY KEY (aluno_matricula, turma_id),
    FOREIGN KEY (aluno_matricula) REFERENCES aluno(matricula)
    	ON DELETE CASCADE,
    FOREIGN KEY (turma_id) REFERENCES turma(turma_id)
    	ON DELETE CASCADE
);

-- AVALIACAO
CREATE TABLE avaliacao (
    avaliacao_id      SERIAL PRIMARY KEY,
    aluno_matricula   VARCHAR(20) NOT NULL,
    turma_id          INT NOT NULL,
    nota              DECIMAL(4,2) NOT NULL,
    observacoes       TEXT,
    FOREIGN KEY (aluno_matricula) REFERENCES aluno(matricula)
    	ON DELETE CASCADE,
    FOREIGN KEY (turma_id) REFERENCES turma(turma_id)
    	ON DELETE CASCADE,
    UNIQUE (aluno_matricula, turma_id)
);


-- ============================================================================
-- TRIGGERS DE VALIDAÇÃO
-- ============================================================================

-- 1. Trigger para garantir que o aluno só possa avaliar turmas em que está matriculado
CREATE OR REPLACE FUNCTION check_aluno_matriculado()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM matricula_turma 
        WHERE aluno_matricula = NEW.aluno_matricula 
          AND turma_id = NEW.turma_id
    ) THEN
        RAISE EXCEPTION 'Erro: O aluno com matrícula % não está matriculado na turma % e, portanto, não pode avaliá-la.', 
            NEW.aluno_matricula, NEW.turma_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_aluno_matriculado
BEFORE INSERT OR UPDATE ON avaliacao
FOR EACH ROW
EXECUTE FUNCTION check_aluno_matriculado();


-- 2. Trigger para limitar a nota da avaliação entre 0 e 10
CREATE OR REPLACE FUNCTION check_nota_limites()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nota < 0 OR NEW.nota > 10 THEN
        RAISE EXCEPTION 'Erro: A nota deve estar entre 0.00 e 10.00. Valor fornecido: %', NEW.nota;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_nota_limites
BEFORE INSERT OR UPDATE ON avaliacao
FOR EACH ROW
EXECUTE FUNCTION check_nota_limites();


-- ============================================================================
-- 1. DEPARTAMENTO
-- ============================================================================
INSERT INTO departamento (departamento_id, nome) VALUES
(1, 'Centro de Desenvolvimento Tecnológico (CDTec)'),
(2, 'Instituto de Física e Matemática (IFM)'),
(3, 'Centro de Engenharias'),
(4, 'Centro de Letras e Comunicação'),
(5, 'Faculdade de Odontologia'),
(6, 'Instituto de Ciências Humanas');

-- ============================================================================
-- 2. CURSO
-- ============================================================================
INSERT INTO curso (curso_id, nome, departamento_id) VALUES
(1, 'Ciência da Computação', 1),
(2, 'Engenharia de Computação', 1),
(3, 'Matemática Licenciatura', 2),
(4, 'Física Bacharelado', 2),
(5, 'Engenharia Civil', 3),
(6, 'Engenharia de Controle e Automação', 3),
(7, 'Letras - Português/Inglês', 4),
(8, 'Jornalismo', 4),
(9, 'Odontologia', 5),
(10, 'História', 6);

-- ============================================================================
-- 3. PROFESSOR
-- ============================================================================
INSERT INTO professor (siape, nome, curso_id) VALUES
('1000001', 'Alan Turing', 1),
('1000002', 'Ada Lovelace', 2),
('1000003', 'Linus Torvalds', 1),
('1000004', 'Margaret Hamilton', 2),
('1000005', 'Isaac Newton', 4),
('1000006', 'Carl Friedrich Gauss', 3),
('1000007', 'Nikola Tesla', 6),
('1000008', 'Gustave Eiffel', 5),
('1000009', 'Machado de Assis', 7),
('1000010', 'Clarice Lispector', 8),
('1000011', 'Pierre Fauchard', 9),
('1000012', 'Sérgio Buarque de Holanda', 10);

-- ============================================================================
-- 4. ALUNO
-- ============================================================================
INSERT INTO aluno (matricula, nome, curso_id) VALUES
('20260001', 'Alice Santos', 1),
('20260002', 'Bruno Oliveira', 1),
('20260003', 'Carla Mendes', 1),
('20260004', 'Diego Costa', 2),
('20260005', 'Eduarda Lima', 2),
('20260006', 'Felipe Rocha', 3),
('20260007', 'Gabriela Alves', 3),
('20260008', 'Henrique Silva', 4),
('20260009', 'Isabela Martins', 5),
('20260010', 'João Pereira', 5),
('20260011', 'Kamila Souza', 6),
('20260012', 'Leonardo Farias', 7),
('20260013', 'Mariana Ribeiro', 7),
('20260014', 'Nicolas Castro', 8),
('20260015', 'Olívia Pinto', 9),
('20260016', 'Paulo Guedes', 9),
('20260017', 'Quintino Bocaiúva', 10),
('20260018', 'Rafaela Nogueira', 10),
('20260019', 'Samuel Dias', 1),
('20260020', 'Tatiana Moraes', 2);

-- ============================================================================
-- 5. DISCIPLINA
-- ============================================================================
INSERT INTO disciplina (disciplina_id, nome, curso_id) VALUES
(1, 'Algoritmos e Estruturas de Dados', 1),
(2, 'Administração de Sistemas Linux', 1),
(3, 'Arquitetura de Computadores', 2),
(4, 'Cálculo I', 3),
(5, 'Álgebra Linear', 3),
(6, 'Física Quântica', 4),
(7, 'Mecânica dos Solos', 5),
(8, 'Sistemas de Controle', 6),
(9, 'Literatura Brasileira', 7),
(10, 'Redação Jornalística', 8),
(11, 'Anatomia e Escultura Dental', 9),
(12, 'História do Brasil Império', 10),
(13, 'Bancos de Dados Relacionais', 1),
(14, 'Engenharia de Software', 2);

-- ============================================================================
-- 6. TURMA
-- ============================================================================
INSERT INTO turma (turma_id, nome, disciplina_id) VALUES
(1, 'Turma M1', 1),
(2, 'Turma T1', 1),
(3, 'Turma N1', 2),
(4, 'Turma M1', 3),
(5, 'Turma M1', 4),
(6, 'Turma T1', 4),
(7, 'Turma M1', 5),
(8, 'Turma N1', 6),
(9, 'Turma T1', 7),
(10, 'Turma M1', 8),
(11, 'Turma T1', 9),
(12, 'Turma M1', 10),
(13, 'Turma T1', 11),
(14, 'Turma M1', 12),
(15, 'Turma N1', 13),
(16, 'Turma N1', 14);

-- ============================================================================
-- 7. MINISTRA (Professor -> Turma)
-- ============================================================================
INSERT INTO ministra (professor_siape, turma_id) VALUES
('1000001', 1),  -- Alan Turing ministra Algoritmos (M1)
('1000002', 2),  -- Ada Lovelace ministra Algoritmos (T1)
('1000003', 3),  -- Linus Torvalds ministra Admin Linux (N1)
('1000004', 4),  -- Margaret Hamilton ministra Arq. de Computadores (M1)
('1000006', 5),  -- Gauss ministra Cálculo I (M1)
('1000005', 6),  -- Newton ministra Cálculo I (T1)
('1000006', 7),  -- Gauss ministra Álgebra Linear (M1)
('1000005', 8),  -- Newton ministra Física Quântica (N1)
('1000008', 9),  -- Gustave Eiffel ministra Mecânica dos Solos (T1)
('1000007', 10), -- Tesla ministra Sistemas de Controle (M1)
('1000009', 11), -- Machado de Assis ministra Literatura (T1)
('1000010', 12), -- Clarice ministra Redação Jornalística (M1)
('1000011', 13), -- Fauchard ministra Anatomia Dental (T1)
('1000012', 14), -- Sérgio Buarque ministra História do Brasil (M1)
('1000001', 15), -- Turing ministra Banco de Dados (N1)
('1000004', 16); -- Margaret ministra Engenharia de Software (N1)

-- ============================================================================
-- 8. MATRICULA_TURMA (Aluno -> Turma)
-- ============================================================================
INSERT INTO matricula_turma (aluno_matricula, turma_id) VALUES
-- Alunos de Computação
('20260001', 1), ('20260001', 3), ('20260001', 15),
('20260002', 1), ('20260002', 15),
('20260003', 2), ('20260003', 3),
('20260019', 2), ('20260019', 15),
('20260004', 4), ('20260004', 16),
('20260005', 4), ('20260005', 16),
('20260020', 4), ('20260020', 16),
-- Alunos de Exatas (Matemática e Física)
('20260006', 5), ('20260006', 7),
('20260007', 6), ('20260007', 7),
('20260008', 6), ('20260008', 8),
-- Alunos de Engenharia
('20260009', 9), ('20260010', 9),
('20260011', 10),
-- Alunos de Humanas/Artes/Saúde
('20260012', 11), ('20260013', 11),
('20260014', 12),
('20260015', 13), ('20260016', 13),
('20260017', 14), ('20260018', 14);

-- ============================================================================
-- 9. AVALIACAO (Aluno avalia as turmas onde está matriculado)
-- ============================================================================
INSERT INTO avaliacao (avaliacao_id, aluno_matricula, turma_id, nota, observacoes) VALUES
(1, '20260001', 1, 9.50, 'Professor tem uma lógica impecável, lista de exercícios excelente.'),
(2, '20260001', 3, 10.00, 'Aula incrível! O laboratório utilizando Linux Mint funcionou perfeitamente e ajudou muito na prática.'),
(3, '20260002', 1, 8.00, 'Boa didática, mas a prova foi muito extensa.'),
(4, '20260003', 3, 9.00, 'Ambiente de desenvolvimento livre muito bem explicado.'),
(5, '20260019', 15, 8.50, 'Gostei de como a normalização foi abordada na prática.'),
(6, '20260004', 4, 10.00, 'A professora domina o assunto como ninguém.'),
(7, '20260005', 16, 7.50, 'Disciplina um pouco teórica, mas os projetos salvaram.'),
(8, '20260006', 5, 0.00, 'filho da puta.'),
(9, '20260007', 7, 9.50, 'Melhor professor do instituto, sem dúvidas.'),
(10, '20260008', 8, 8.00, 'Laboratórios bem equipados, mas faltou tempo para as práticas.'),
(11, '20260009', 9, 9.00, 'Material de apoio muito completo e detalhado.'),
(12, '20260011', 10, 10.00, 'Aulas super dinâmicas e envolventes.'),
(13, '20260012', 11, 9.80, 'As discussões em sala são riquíssimas.'),
(14, '20260014', 12, 8.50, 'Muito exigente com os textos, mas o aprendizado é garantido.'),
(15, '20260015', 13, 9.00, 'Prática em laboratório fundamental, professor muito atencioso.'),
(16, '20260018', 14, 10.00, 'O professor faz você se sentir dentro do período histórico. Excepcional.');

-- Consulta final
SELECT AL.nome as "Aluno", PR.nome as "Professor", AV.nota, AV.observacoes
FROM avaliacao AV JOIN aluno AL ON AV.aluno_matricula = AL.matricula
	JOIN ministra M ON AV.turma_id = M.turma_id
    JOIN professor PR ON M.professor_siape = PR.siape
WHERE AV.nota < 5 OR AV.nota > 9;
