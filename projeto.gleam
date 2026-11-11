type Posicao {
  Posicao(lin: Int, col: Int)
}

type Jogador {
  Jogador(
    numero: Int,
    posicao: Posicao,
    casas_visitadas: List(Posicao),
    escapou: Bool,
  )
}

type Enigma {
  Enigma(
    numero: Int,
    posicao: Posicao,
    codigo: String,
    alternativas: List(String),
    // Alternativa correta: 1, 2 ou 3
    resposta_correta: Int,
    resolvido: Bool,
  )
}

type Modo {
  Explorando
  ResolvendoEnigma(numero_enigma: Int, jogador_encontrou: Int)
}

type Partida {
  Partida(
    jogadores: List(Jogador),
    paredes: List(Posicao),
    saida: Posicao,
    enigmas: List(Enigma),
    modo: Modo,
    // Tiques que faltam para o tempo acabar
    tiques_restantes: Int,
  )
}

type Estado {
  Abertura
  EmPartida(partida: Partida)
  Resultado(
    venceu: Bool,
    enigmas_resolvidos: Int,
    jogadores_escaparam: Int,
    tiques_restantes: Int,
  )
}
