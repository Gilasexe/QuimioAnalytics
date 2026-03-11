# QuimioAnalytics
Repositório oficial da nossa equipe de Projeto Aplicado 2

# Banco de Dados Unificado - IST Ambiental 🧪📊

Projeto Aplicado II (PJAII) do curso de Ciência de Dados e Inteligência Artificial.

## 🎯 Objetivo
Desenvolver um banco de dados unificado para o Instituto SENAI de Tecnologia Ambiental (IST Ambiental), integrando saídas analíticas (Identificação e Abundância) e enriquecendo esses dados com bibliotecas públicas de química (PubChem, ChEBI, etc.).

## 🛠️ Tecnologias Utilizadas
* **PostgreSQL**: Banco de dados relacional (MVP já modelado em camadas: Staging, Core e Ref).
* **Python (Pandas & Requests)**: Scripts de extração (ETL), leitura de planilhas e integração com APIs.
* **Modelagem Lógica**: DBeaver / brModelo.

## 🚀 Próximos Passos (Backlog)
- [x] Modelagem do Mapa Lógico e Schema Físico (MVP)
- [ ] Desenvolvimento do script Python (Pandas) para leitura dos arquivos do IST
- [ ] Integração com as APIs do PubChem e ChEBI via endpoint
- [ ] Carga dos dados tratados no PostgreSQL