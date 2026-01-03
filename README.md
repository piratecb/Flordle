# 🎯 Flordle

Um clone do popular jogo **Wordle** desenvolvido em **Flutter** com palavras em Português de Portugal.

![Flutter](https://img.shields.io/badge/Flutter-3.9+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

---

## 📖 Sobre o Projeto

**Flordle** é um jogo de adivinhação de palavras onde o jogador tem 6 tentativas para descobrir a palavra secreta de 5 letras. O jogo oferece feedback visual através de cores:

- 🟩 **Verde** - Letra correta na posição correta
- 🟨 **Amarelo** - Letra correta na posição errada
- ⬛ **Cinza** - Letra não existe na palavra

---

## ✨ Features

### 🎮 Modos de Jogo

| Modo | Descrição |
|------|-----------|
| **📅 Palavra do Dia** | Uma palavra por dia, igual para todos os jogadores. Só podes jogar uma vez por dia! |
| **♾️ Modo Ilimitado** | Joga quantas vezes quiseres com palavras aleatórias diferentes. |

### 📊 Sistema de Estatísticas

- **Games Played** - Total de jogos jogados
- **Win Rate** - Percentagem de vitórias
- **Current Streak** - Sequência atual de vitórias
- **Max Streak** - Melhor sequência de vitórias
- **Average Attempts** - Média de tentativas para acertar
- **Guess Distribution** - Distribuição de tentativas (1-6)

### 🔐 Autenticação

- Login com **Email/Password**
- Modo **Guest** (convidado)
- Sincronização de estatísticas na **cloud**

### 💾 Persistência

- Estado do jogo diário guardado localmente
- Estatísticas sincronizadas com **Firebase**
- Não perdes o progresso ao fechar a app

---

## 🛠️ Tech Stack

| Tecnologia | Utilização |
|------------|------------|
| **Flutter** | Framework UI multiplataforma |
| **Dart** | Linguagem de programação |
| **Firebase Auth** | Autenticação de utilizadores |
| **Cloud Firestore** | Base de dados NoSQL |
| **SharedPreferences** | Armazenamento local |
| **Provider** | State management |

---

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                    # Entry point e UI principal do jogo
├── firebase_options.dart        # Configurações do Firebase
├── data/
│   └── word_list.dart          # Lista de palavras portuguesas
├── models/
│   ├── game_model.dart         # Modelo de dados do jogo
│   └── player_stats.dart       # Modelo de estatísticas
├── screens/
│   ├── login_screen.dart       # Ecrã de login/registo
│   └── stats_screen.dart       # Ecrã de estatísticas
└── services/
    ├── auth_service.dart       # Serviço de autenticação
    └── firebase_service.dart   # Serviço de Firestore
```

---

## 🚀 Getting Started

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.9+)
- [Android Studio](https://developer.android.com/studio) ou [VS Code](https://code.visualstudio.com/)
- Conta no [Firebase](https://firebase.google.com/)

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-username/flordle.git
   cd flordle
   ```

2. **Instala as dependencies**
   ```bash
   flutter pub get
   ```

3. **Configura o Firebase**
   - Cria um projeto no [Firebase Console](https://console.firebase.google.com/)
   - Ativa **Authentication** (Email/Password)
   - Ativa **Cloud Firestore**
   - Descarrega os ficheiros de configuração e coloca em:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Corre a app**
   ```bash
   flutter run
   ```

---

## 📱 Screenshots

| Menu Inicial | Jogo | Estatísticas |
|:------------:|:----:|:------------:|
| 🎮 | 🎯 | 📊 |

---

## 🎯 Como Jogar

1. Escolhe um modo de jogo: **Palavra do Dia** ou **Modo Ilimitado**
2. Digita uma palavra de 5 letras usando o teclado
3. Pressiona **ENTER** para submeter
4. Analisa as cores e tenta adivinhar a palavra em 6 tentativas
5. Partilha os teus resultados com amigos!

---

## 📝 Lista de Palavras

O jogo contém **365+ palavras** portuguesas de 5 letras, incluindo:
- Palavras comuns do dia-a-dia
- Sem acentos (para simplificar o teclado)
- Todas em maiúsculas

---

## 🤝 Contribuir

Contribuições são bem-vindas! Para contribuir:

1. Faz **Fork** do projeto
2. Cria uma **Branch** para a tua feature (`git checkout -b feature/NovaFeature`)
3. **Commit** as tuas alterações (`git commit -m 'Adiciona NovaFeature'`)
4. **Push** para a branch (`git push origin feature/NovaFeature`)
5. Abre um **Pull Request**

---

## 📄 Licença

Este projeto está sob a licença MIT. Vê o ficheiro [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

Desenvolvido com ❤️ em Flutter

---

## 🙏 Agradecimentos

- Inspirado no [Wordle](https://www.nytimes.com/games/wordle/index.html) original
- Ícones do [Material Design](https://material.io/icons/)
- Comunidade Flutter e Firebase

---

<p align="center">
  <b>Feito em Portugal 🇵🇹</b>
</p>

