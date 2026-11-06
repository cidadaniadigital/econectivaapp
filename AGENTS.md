# AGENTS.md — Task Flow (SPO)

Use este fluxo para executar tarefas com Jira neste projeto.

1. **Ler tarefa Jira**
   - Capturar: chave, escopo, tipo (erro/alteração) e critérios.

2. **Preparar projeto local**
   - Configurar `.env`.
   - Rodar setup do projeto (dependências, migrate/seed quando aplicável).

3. **Criar branch**
   - Formato: `<JIRA>-<slug>`
   - Ex.: `UU-373-ajuste-retorno-api`.

4. **Implementar somente o escopo da tarefa**
   - Não incluir refactors não solicitados.
   - Manter compatibilidade quando possível.
   - Rodar `dart analyze`e realizar as correções do que for error

5. **Publicar entrega técnica**
   - Fazer commit no formato abaixo
    ### Fixed
    - Descrição do commit. Mencionar também o link da tarefa https://spo-tec.atlassian.net/browse/UU-999
    ### Changed
    - Descrição do commit. Mencionar também o link da tarefa https://spo-tec.atlassian.net/browse/UU-999
    ### Added
    - Descrição do commit. Mencionar também o link da tarefa https://spo-tec.atlassian.net/browse/UU-999

   - Fazer push da branch.
   - Comentar na tarefa Jira com resumo da implementação e branch.
   - Mover a tarefa para **Review**.

6. **Encerramento**
   - Não marcar Done sem validação e definição humana.
