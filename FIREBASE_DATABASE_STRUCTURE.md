# Flordle - Estrutura Firebase

## Arquitetura

| Componente | Onde | Porquê |
|------------|------|--------|
| **Palavras Diárias** | LOCAL (`lib/data/word_list.dart`) | Offline, instantâneo, grátis |
| **Jogos** | Firebase (`games`) | Persistente entre sessões |
| **Estatísticas** | Firebase (`statistics`) | Sincronizado entre dispositivos |
| **Utilizadores** | Firebase (`users`) | Dados do perfil |

## Coleções no Firestore

### `games`
Guarda os resultados de cada jogo jogado.

```
games/{gameId}
├── playerName: string
├── word: string
├── won: boolean
├── attempts: number
├── date: string (YYYY-MM-DD)
├── guesses: array<string>
└── timestamp: timestamp
```

### `statistics`
Estatísticas agregadas por jogador.

```
statistics/{playerName}
├── gamesPlayed: number
├── gamesWon: number
├── winRate: number
├── currentStreak: number
├── maxStreak: number
├── averageAttempts: number
└── guessDistribution: map<string, number>
```

### `users`
Dados dos utilizadores autenticados.

```
users/{odId}
├── email: string
├── displayName: string
└── createdAt: timestamp
```

### `test`
Coleção temporária para testes de conexão (pode ser eliminada).

## Coleções NÃO usadas (podem ser eliminadas)

- ❌ `daily_words` - As palavras são calculadas localmente, não via Firebase
- ❌ `config` - Não implementado

## Notas

- A palavra do dia é calculada deterministicamente usando `WordList.getWordForDate()`
- Todos os utilizadores recebem a mesma palavra para o mesmo dia
- Funciona offline sem necessidade de consultar o Firebase
