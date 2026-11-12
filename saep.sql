
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    status_colab VARCHAR(30) DEFAULT 'Inativo' CHECK (status_colab IN ('Inativo', 'Ativo'))
);


CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    nome_tarefa VARCHAR(100) NOT NULL,
    prazo_entrega TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    categoria VARCHAR(100) NOT NULL,
    status VARCHAR(100) DEFAULT 'Agendada' CHECK (status IN ('Agendada', 'Em curso', 'Finalizada'))
);


create table historico_tarefas (
    id serial primary key,
    tarefa_id INT REFERENCES tarefas(id),
    acao VARCHAR(100) NOT NULL,
    descricao VARCHAR(100),
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO usuarios (nome, email, senha, status_colab) VALUES
('Ana Silva', 'ana.silva@consultoria.com', 'Senha123!', 'Ativo'),
('Carlos Oliveira', 'carlos.oliveira@consultoria.com', 'Senha456!', 'Ativo'),
('Mariana Santos', 'mariana.santos@consultoria.com', 'Senha789!', 'Inativo');

-- Inserção de Tarefas
INSERT INTO tarefas (usuario_id, nome_tarefa, prazo_entrega, categoria, status) VALUES
(1, 'Mapeamento de Processos RH', '2026-11-15 18:00:00', 'Consultoria Estratégica', 'Em curso'),
(2, 'Auditoria de Segurança da Informação', '2026-11-05 17:00:00', 'Auditoria de Processos', 'Agendada'),
(1, 'Migração do Banco de Dados PostgreSQL', '2026-11-01 12:00:00', 'Implementação de Sistemas', 'Agendada');

-- Inserção de Histórico
INSERT INTO historico_tarefas (tarefa_id, acao, descricao, data_registro) VALUES
(1, 'Criação de Tarefa', 'Tarefa criada e atribuída à colaboradora Ana Silva', '2026-10-20 09:00:00'),
(1, 'Alteração de Status', 'Status alterado de Agendada para Em curso', '2026-10-22 14:30:00'),
(2, 'Criação de Tarefa', 'Tarefa criada e atribuída ao colaborador Carlos Oliveira', '2026-10-25 10:15:00');

CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT 
    u.nome AS nome_colaborador,
    t.nome_tarefa AS titulo_tarefa,
    t.categoria,
    t.prazo_entrega,
    t.status AS status_atividade
FROM tarefas t
JOIN usuarios u ON t.usuario_id = u.id;

CREATE OR REPLACE FUNCTION fn_trg_validar_tarefa()
RETURNS TRIGGER AS $$
DECLARE
    v_status_colab VARCHAR;
    v_nome_colab VARCHAR;
BEGIN
    -- 1. Garante que a data de entrega tenha um valor padrão
    NEW.prazo_entrega := COALESCE(NEW.prazo_entrega, CURRENT_TIMESTAMP);

    -- 2. Busca o status e nome do colaborador
    SELECT status_colab, nome 
    INTO v_status_colab, v_nome_colab
    FROM usuarios
    WHERE id = NEW.usuario_id;

    -- 3. Validações
    IF v_status_colab IS NULL THEN
        RAISE EXCEPTION 'Erro: Colaborador com ID % não encontrado.', NEW.usuario_id;
    ELSIF v_status_colab <> 'Ativo' THEN
        RAISE EXCEPTION 'Erro: Não é possível atribuir tarefas a colaboradores inativos (Colaborador: %).', v_nome_colab;
    END IF;

    -- 4. Registro no Histórico de Tarefas
    INSERT INTO historico_tarefas (tarefa_id, acao, descricao, data_registro)
    VALUES (
        NEW.id,
        'Criação de Tarefa',
        FORMAT('Tarefa "%s" atribuída ao colaborador %s', NEW.nome_tarefa, v_nome_colab),
        CURRENT_TIMESTAMP
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Associação do Gatilho à Tabela tarefas
CREATE OR REPLACE TRIGGER trg_validar_tarefa
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_tarefa();

create view vw_cronograma_prazos as
select
    t.nome_tarefa,
    t.status AS status_tarefa,
	t.prazo_entrega,
    (t.prazo_entrega - CURRENT_DATE) AS dias_restantes,
    u.nome AS nome_responsavel
FROM tarefas t
JOIN usuarios u ON t.usuario_id = u.id
ORDER BY t.prazo_entrega ASC;

-- FIZ SÓ OS QUE DAVA PARA FAZER ATÉ ONDE APRENDEMOS
