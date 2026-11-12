create table usuarios (
    id serial primary key,
    nome varchar(100) not null,
    email varchar(100) not null unique,
    senha varchar(100) not null,
    status_colab varchar(30) default 'inativo' check (status_colab in ('inativo', 'ativo'))
);

create table tarefas (
    id serial primary key,
    usuario_id int references usuarios(id),
    nome_tarefa varchar(100) not null,
    prazo_entrega timestamp default current_timestamp,
    categoria varchar(100) not null,
    status varchar(100) default 'agendada' check (status in ('agendada', 'em curso', 'finalizada'))
);

create table historico_tarefas (
    id serial primary key,
    tarefa_id int references tarefas(id),
    acao varchar(100) not null,
    descricao varchar(100),
    data_registro timestamp default current_timestamp
);

INSERT INTO usuarios (nome, email, senha, status_colab) VALUES
('Ana Silva', 'ana.silva@consultoria.com', 'Senha123!', 'ativo'),
('Carlos Oliveira', 'carlos.oliveira@consultoria.com', 'Senha456!', 'ativo'),
('Mariana Santos', 'mariana.santos@consultoria.com', 'Senha789!', 'inativo');


INSERT INTO tarefas (usuario_id, nome_tarefa, prazo_entrega, categoria, status) VALUES
(1, 'Mapeamento de Processos RH', '2026-11-15 18:00:00', 'Consultoria Estratégica', 'em curso'),
(2, 'Auditoria de Segurança da Informação', '2026-11-05 17:00:00', 'Auditoria de Processos', 'agendada'),
(3, 'Migração do Banco de Dados PostgreSQL', '2026-11-01 12:00:00', 'Implementação de Sistemas', 'agendada');


INSERT INTO historico_tarefas (tarefa_id, acao, descricao, data_registro) VALUES
(1, 'Criação de Tarefa', 'Tarefa criada e atribuída à colaboradora Ana Silva', '2026-10-20 09:00:00'),
(2, 'Alteração de Status', 'Status alterado de Agendada para Em curso', '2026-10-22 14:30:00'),
(3, 'Criação de Tarefa', 'Tarefa criada e atribuída ao colaborador Carlos Oliveira', '2026-10-25 10:15:00');


create or replace view vw_painel_principal as
select 
    u.nome as nome_colaborador,
    t.nome_tarefa as titulo_tarefa,
    t.categoria,
    t.prazo_entrega,
    t.status as status_atividade
from
	tarefas t
join
	usuarios u on t.usuario_id = u.id;

create or replace function fn_trg_validar_tarefa()
returns trigger as 
$$
declare
    v_status_colab varchar;
    v_nome_colab varchar;
begin
    new.prazo_entrega := coalesce(new.prazo_entrega, current_timestamp);

select
	status_colab,
	nome 
into
	v_status_colab,
	v_nome_colab
from
	usuarios
where
	id = new.usuario_id;

    if v_status_colab is null then
        raise exception 'erro: colaborador com id % não encontrado.', new.usuario_id;
    elsif v_status_colab <> 'ativo' then
        raise exception 'erro: não é possível atribuir tarefas a colaboradores inativos (colaborador: %).', v_nome_colab;
    end if;

    insert into historico_tarefas (tarefa_id, acao, descricao, data_registro)
    values (
        new.id,
        'criação de tarefa',
        format('tarefa "%s" atribuída ao colaborador %s', new.nome_tarefa, v_nome_colab),
        current_timestamp
    );

    return new;
end;
$$ language plpgsql;

create or replace trigger trg_validar_tarefa
before insert on tarefas
for each row
execute function fn_trg_validar_tarefa();

create view vw_cronograma_prazos as
select
    t.nome_tarefa,
    t.status as status_tarefa,
    t.prazo_entrega,
    (t.prazo_entrega - current_date) as dias_restantes,
    u.nome as nome_responsavel
from
	tarefas t
join
	usuarios u on t.usuario_id = u.id
order by 
	t.prazo_entrega asc;

-- ESSA EU FIZ NA AULA DO DIA 12/11

create or replace function fn_buscar_colaboradores(termo_pesq varchar)
returns table(
	id int,
	nome varchar,
	email varchar,
	status_colab varchar
)
as
$$
begin
	return query
	select
	u.id,
	u.nome,
	u.email,
	u.status_colab
from
	usuarios u
where
	u.nome ilike '%' || termo_pesq || '%'
	or
	u.email ilike '%' || termo_pesq || '%';
end;
$$ language plpgsql;
