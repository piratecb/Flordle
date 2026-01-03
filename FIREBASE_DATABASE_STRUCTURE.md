# Flordle - Estrutura Firebase

## Arquitetura

| Componente | Onde | Porquê |
|------------|------|--------|
| **Palavras Diárias** | LOCAL (`lib/data/word_list.dart`) | Offline, instantâneo, grátis |
| **Jogos** | Firebase (`games`) | Persistente |
| **Estatísticas** | Firebase (`statistics`) | Sincronizado |
