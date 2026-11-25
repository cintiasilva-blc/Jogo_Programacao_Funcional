// Cintia da Silva Bulcão    ra145107
// Giovana da Silva Bulcão   ra144325

// SOBRE O JOGO
//  É um jogo competitivo multiplayer para dois jogadores

//  Os dois jogadores começam em casas diferentes de um mesmo labirinto, e devem encontrar a saída.
//  Porém, o labirinto é escuro e cada jogador só enxerga um quadrado 3x3 (um quadrado de 8 casas) a partir da sua casa atual,
//  além disso, eles também não guardam a memória das casas que já visitaram.

//  Aquele que chegar primeiro a saída E reslver o enigma (expressão aritmética) vence o jogo.

// PONTOS IMPORTANTES SOBRE DECISÕES DE PROJETO:
// - O labirinto é uma grade de 20x20, e no inicio de cada partida, um, entre os cinco labirintos elaborados,
//   é sorteado. (É para todos serem dificeis e terem aproximadamente o mesmo nível de dificuldade)

// - O jogador adversário pode ser visto se ele entrar no seu quadrado de visão, mas se ele estiver
//   fora do quadrado, entre 2 a 4 casas de distÂncia, aparece o aviso: "Alguém está perto!"

// - Ao entrar na casa da porta de saída, o jogador fica parado e recebe uma
//   expressão aritmética e 3 alternativas, no qual ele tem 10 segundos para escolher a alternativa correta.

// - Enquanto um jogador resolve o enigma, a porta fica revelada na tela do
//   adversário, com o aviso "Adversário na porta!", e o adversário continua
//   andando normalmente.

// - Resposta certa: o jogador vence a partida.
// - Resposta errada ou tempo esgotado: o jogador fica bloqueado por 3 segundos, e depois disso ele precisa
//   sair da casa da porta e entrar de novo para receber um novo enigma.

// - Os jogadores podem ocupar a mesma casa

// CONTROLES:
// - Enter: começa a partida ou joga novamente.
// - Setas (Cima, Baixo, Esquerda, Direita): movem o personagem uma casa.
// - 1, 2 ou 3: escolhem a alternativa do enigma.

// Imports, constantes, desenho dos labirintos e tipos de dados

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import sgleam/check
import sgleam/color.{type Color}
import sgleam/env.{type Env}
import sgleam/fill
import sgleam/image.{type Image}
import sgleam/key
import sgleam/mworld
import sgleam/random.{type Generator}
import sgleam/style

// CONSTANTES
// Quantidade de casas em cada lado do labirinto
const tamanho = 20

// Cada casa é um quadrado com lado de 24px
const lado_casa = 24

/// Quantidade de tiques por segundo
const tiques_por_segundo = 10

/// Tempo para responder o enigma, em tiques (10 seg)
const tempo_enigma = 100

/// Tempo de bloqueio depois de um erro, em tiques (3 seg)
const tempo_bloqueio = 30

/// Largura da tela em px
const largura = 480

/// Altura da tela em px
const altura = 590

// LABIRINTOS
// - # é parede
// - . é corredor
// - S e T são os inícios e P é a porta

const labirinto_1 = [
  "..#.#..#.#.#.#.#.#..",
  "#.....#...........#.",
  "..###.#######.###.#.",
  "#...#...#...#.#P#...",
  ".##.###.#.#.#.#.###.",
  "....#.....#...#...#.",
  "#.#############.###.",
  "#.#.....#.......#...",
  "T.#.###.###.#.#.#.##",
  "#S..#.#...#.#.#.#...",
  ".####.#######.#.###.",
  "....#.........#...#.",
  "###.#.#####.###.###.",
  "....#.#...#.#...#...",
  "#.###.#.#.#.#.###.##",
  "..#...#.#.#.#.#...#.",
  "#.#.#####.#.###.###.",
  "..#...#...#.#...#...",
  "#.###.#.#.#.#.#####.",
  "........#.#.........",
]

const labirinto_2 = [
  ".#T.#.#.#.#.#..#.#..",
  "..#...........#...#.",
  "#.#.#.#######.#.#.#.",
  "..#S#.#.....#...#...",
  "#.#.###.###.#######.",
  "..#...#...#.#.....#.",
  "#.###.###.#.###.#.#.",
  "....#.....#...#.#...",
  "#.###########.#.####",
  "#.#.....#.....#.....",
  "..#.###.###########.",
  "#.#...#.....#...#...",
  "..###.###.###.#.#.##",
  "#.#...#.#.....#...#.",
  "..#.###.###########.",
  "#..P#.........#.....",
  "..#######.###.#.####",
  "#.....#...#...#.....",
  ".####.#.###.#######.",
  "........#...........",
]

const labirinto_3 = [
  ".#.#.#.##..#.#S#..#.",
  "..........#....T#...",
  "#.#.#######.###.###.",
  "..#...#.....#.#...#.",
  "#.###.#.#####.###.#.",
  "....#.#.......#...#.",
  ".##.#.###.#####.###.",
  "#.#.#.....#.....#...",
  "..#.#######.#######.",
  "#.#.#...#.#.#.......",
  "..#.#.###.#.#.#.###.",
  "#...#...#...#.#.#.#.",
  "..#####.#######.#.#.",
  "#.........#...#.#...",
  ".########.#.#.#.#.##",
  "..#.....#...#...#.#.",
  "#.#.#.###########.#.",
  "....#...#......P#...",
  "#.#####.#.#####.###.",
  "......#.......#.....",
]

const labirinto_4 = [
  "..#.#..#S#.#.#.#..#.",
  "#.....#T........#...",
  ".##.#.#.#######.#.##",
  "....#.#...#.....#...",
  "#.###.###.#.#####.#.",
  "..#...#...#.....#.#.",
  "#.###.#.#######.###.",
  "....#.#.#.....#.....",
  "#.#.###.###.#.#####.",
  "..#.#...#.#.#.....#.",
  ".##.#.###.#.#####.#.",
  "#...#.#...#.#...#...",
  "..###.#.###.#.######",
  "#...#...#.#.#.......",
  "..#.#####.#.###.###.",
  "#.#.......#.....#...",
  "..#####.#########.##",
  "#P..#.#.........#...",
  ".##.#.#####.#######.",
  "..........#.........",
]

const labirinto_5 = [
  "#..#.#.#.#..#.#.##..",
  "..#.......#.......#.",
  "#.#.#.###.#.#####.#.",
  "....#...#.#...#...#.",
  "#.#####.#.#.#.###.#.",
  "......#.#.#.#...#.#.",
  ".####.#.#.#####.#.#.",
  "#.#...#.#.......#...",
  "..#.###.###########.",
  "#...#...#.#...#.....",
  ".####.#.#.#.#.#.####",
  "......#.#.#.#.#...#.",
  "#.#######.#.#.###.#.",
  "......#...#P#.#.#.#.",
  "#.###.#.###.#.#.#.#.",
  "..#...#.#...#...#...",
  "###.#.#.###.#######.",
  "....#.#...#.......#.",
  "#.#######.#.###.###.",
  "T.S.......#...#.....",
]

// TIPOS DE DADOS
// Representa uma casa do labirinto
// - *lin* e *col* vão de 0 a `tamanho - 1`
pub type Posicao {
  Posicao(lin: Int, col: Int)
}

// Representa a direção de um movimento
pub type Direcao {
  Cima
  Baixo
  Esquerda
  Direita
}

/// Representa o mapa do labirinto com as linhas, os inícios S e T e a porta P
pub type Mapa {
  Mapa(linhas: List(String), inicio: Posicao, inicio_2: Posicao, porta: Posicao)
}

/// Representa o formato das expressões aritméticas
pub type Expressao {
  FormatoA
  FormatoB
  FormatoC
  FormatoD
}

/// Representa o enigma, em que:
//  - *expressao* é o texto da expressão arit.
//  - *alternativas* são as três opções
//  - *correta* é o número (1, 2 ou 3) da alternativa correta
pub type Enigma {
  Enigma(expressao: String, alternativas: List(Int), correta: Int)
}

/// Representa a ação de um jogador na partida.
pub type Acao {
  Andando
  ResolvendoEnigma(enigma: Enigma, tiques_restantes: Int)
  Bloqueado(tiques_restantes: Int)
}

/// Representa o jogador, em que:
//  - *numero* pode ser 1 ou 2 (jogador 1 ou jogador 2)
pub type Jogador {
  Jogador(numero: Int, posicao: Posicao, acao: Acao)
}

/// Representa uma partida em andamento
pub type Partida {
  Partida(jogadores: List(Jogador), mapa: Mapa)
}

/// Representa o estado do jogo.
pub type Estado {
  Abertura(gerador: Generator)
  EmPartida(gerador: Generator, partida: Partida)
  Resultado(gerador: Generator, vencedor: Int)
}

// Desvios usados para montar as alternativas incorretas.
pub type ParErros {
  ParErros(primeiro: Int, segundo: Int)
}

// Mworld

pub fn smain() {
  mworld.create_from(inicio, min: 2, max: 2, to_image: desenha)
  |> mworld.tick_rate(tiques_por_segundo)
  |> mworld.on_tick(tique)
  |> mworld.on_key_down(tecla)
}

/// Cria o estado inicial do jogo a partir do gerador de *env*.
fn inicio(env: Env, _jogadores: List(mworld.Player)) -> Estado {
  Abertura(env.random(env))
}

/// Determina qual tela deve ser mostrada ao jogador de acordo com o *estado*.
fn desenha(estado: Estado, jogador: mworld.Player) -> Image {
  tela(estado, mworld.player_index(jogador))
}

/// Recebe a tecla pressionada pelo jogador e trata o evento.
fn tecla(estado: Estado, jogador: mworld.Player, evento: key.Event) -> Estado {
  trata_tecla(estado, mworld.player_index(jogador), evento)
}

/// Recebe *inicio* e *fim* e retorna uma lista com os números desse intervalo, incluindo os extremos.
/// Se *inicio* for maior que *fim*, retorna uma lista vazia.
pub fn sequencia(inicio: Int, fim: Int) -> List(Int) {
  case inicio > fim {
    True -> []
    False -> [inicio, ..sequencia(inicio + 1, fim)]
  }
}
pub fn sequencia_examples() {
  // Casos em que o início é maior ou igual ao fim
  check.eq(sequencia(3, 2), [])
  check.eq(sequencia(3, 3), [3])
  check.eq(sequencia(2, 5), [2, 3, 4, 5])
}

/// Gera uma lista com todas as posições do labirinto, percorrendo as linhas em ordem.
pub fn todas_as_casas() -> List(Posicao) {
  sequencia(0, tamanho - 1)
  |> list.map(fn(lin) {
    list.map(sequencia(0, tamanho - 1), fn(col) { Posicao(lin, col) })
  })
  |> list.fold([], list.append)
}
pub fn todas_as_casas_examples() {
  check.eq(list.length(todas_as_casas()), 400)
  check.eq(list.first(todas_as_casas()), Ok(Posicao(0, 0)))
  // A segunda linha começa depois das 20 casas da primeira
  check.eq(todas_as_casas() |> list.drop(20) |> list.first, Ok(Posicao(1, 0)))
  check.eq(todas_as_casas() |> list.drop(399) |> list.first, Ok(Posicao(19, 19)))
}

/// Recebe uma *lista* e sorteia um de seus elementos, retornando também o gerador atualizado.
/// Se a lista estiver vazia, retorna *padrao* no lugar do elemento.
pub fn sorteia(gerador: Generator, lista: List(a), padrao: a) -> #(a, Generator) {
  case random.pick(gerador, lista) {
    #(Ok(x), gerador) -> #(x, gerador)
    #(Error(_), gerador) -> #(padrao, gerador)
  }
}
pub fn sorteia_examples() {
  let gerador_teste = random.mock([random.pick_returns([1, 2, 3], Ok(2))])
  check.eq(sorteia(gerador_teste, [1, 2, 3], 0), #(2, random.mock([])))
  let gerador_teste = random.mock([random.pick_returns([], Error(Nil))])
  // Lista vazia -> usa o valor padrão
  check.eq(sorteia(gerador_teste, [], 7), #(7, random.mock([])))
}

// MAPAS
/// Determina o símbolo da casa *p*. Se a posição estiver fora do labirinto, retorna "#".
pub fn simbolo_em(linhas: List(String), p: Posicao) -> String {
  case p.lin < 0 || p.lin >= tamanho || p.col < 0 || p.col >= tamanho {
    True -> "#"
    False -> case linhas |> list.drop(p.lin) |> list.first {
      Ok(linha) -> case string.slice(linha, p.col, 1) {
        "" -> "#"
        simbolo -> simbolo
      }
      Error(_) -> "#"
    }
  }
}

/// Procura a primeira posição que contém o *simbolo* nas linhas do mapa.
/// Se o símbolo não estiver presente, retorna a posição (0, 0).
pub fn acha_simbolo(linhas: List(String), simbolo: String) -> Posicao {
  case list.find(todas_as_casas(), fn(p) { simbolo_em(linhas, p) == simbolo }) {
    Ok(p) -> p
    Error(_) -> Posicao(0, 0)
  }
}

/// Cria o mapa identificando nas linhas as posições iniciais (S e T) e a saída (P).
pub fn ler_mapa(linhas: List(String)) -> Mapa {
  Mapa(linhas, acha_simbolo(linhas, "S"), acha_simbolo(linhas, "T"), acha_simbolo(linhas, "P"))
}

/// Representa um mapa menor utilizado nos exemplos, localizado no canto superior esquerdo.
pub fn mapa_teste() -> Mapa {
  ler_mapa(["#####", "#S.P#", "#T#.#", "#####"])
}
pub fn ler_mapa_examples() {
  // Posições de início dos jogadores e da porta
  check.eq(mapa_teste(), Mapa(["#####", "#S.P#", "#T#.#", "#####"], Posicao(1, 1), Posicao(2, 1), Posicao(1, 3)))
  // Casas dentro do mapa
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(1, 2)), ".")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(0, 0)), "#")
  // Posições fora do mapa, inclusive fora do mapa menor usado nos exemplos
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(-1, 0)), "#")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(0, 20)), "#")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(0, 5)), "#")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(4, 0)), "#")
}

/// Retorna uma lista com os cinco mapas do jogo.
pub fn mapas() -> List(Mapa) {
  list.map([labirinto_1, labirinto_2, labirinto_3, labirinto_4, labirinto_5], ler_mapa)
}
pub fn mapas_examples() {
  check.eq(list.length(mapas()), 5)
  // Todos os mapas têm 20 linhas e 20 colunas
  check.eq(
    list.all(mapas(), fn(mapa) {
      list.length(mapa.linhas) == 20
      && list.all(mapa.linhas, fn(l) { string.length(l) == 20 })
    }),
    True,
  )
  // Os jogadores começam em casas diferentes e os símbolos estão nas posições esperadas
  check.eq(
    list.all(mapas(), fn(mapa) {
      mapa.inicio != mapa.inicio_2
      && simbolo_em(mapa.linhas, mapa.inicio) == "S"
      && simbolo_em(mapa.linhas, mapa.inicio_2) == "T"
      && simbolo_em(mapa.linhas, mapa.porta) == "P"
    }),
    True,
  )
}

/// Verifica se a casa *p* permite a movimentação do jogador (corredor, início ou porta).
pub fn caminho_livre(mapa: Mapa, p: Posicao) -> Bool {
  let simbolo = simbolo_em(mapa.linhas, p)
  simbolo == "." || simbolo == "S" || simbolo == "T" || simbolo == "P"
}
pub fn caminho_livre_examples() {
  let mapa = mapa_teste()
  // Casas livres (inícios, corredor e porta)
  check.eq(caminho_livre(mapa, Posicao(1, 1)), True)
  check.eq(caminho_livre(mapa, Posicao(2, 1)), True)
  check.eq(caminho_livre(mapa, Posicao(1, 2)), True)
  check.eq(caminho_livre(mapa, Posicao(1, 3)), True)
  // Casas que não permitem andar (parede ou fora do mapa)
  check.eq(caminho_livre(mapa, Posicao(0, 0)), False)
  check.eq(caminho_livre(mapa, Posicao(-1, 1)), False)
  check.eq(caminho_livre(mapa, Posicao(1, 20)), False)
}

// TECLAS
/// trata a tecla do jogador *numero* de acordo com o estado do jogo
/// Enter começa ou reinicia a partida, durante a partida a tecla é tratada por trata_tecla_partida
pub fn trata_tecla(estado: Estado, numero: Int, tecla: key.Event) -> Estado {
  case estado, tecla {
    Abertura(gerador), key.Enter -> inicia_partida(gerador)
    EmPartida(gerador, partida), _ -> trata_tecla_partida(gerador, partida, numero, tecla)
    Resultado(gerador, _), key.Enter -> inicia_partida(gerador)
    _, _ -> estado
  }
}
pub fn trata_tecla_examples() {
  let gerador = random.new(0)
  let partida_base = partida_teste()
  // Teclas na abertura
  check.eq(trata_tecla(Abertura(gerador), 1, key.Enter), inicia_partida(gerador))
  check.eq(trata_tecla(Abertura(gerador), 2, key.ArrowUp), Abertura(gerador))
  // Teclas durante a partida
  let esperado = Partida([Jogador(1, Posicao(1, 2), Andando), Jogador(2, Posicao(1, 1), Andando)], mapa_teste())
  check.eq(trata_tecla(EmPartida(gerador, partida_base), 1, key.ArrowRight), EmPartida(gerador, esperado))
  check.eq(trata_tecla(EmPartida(gerador, partida_base), 2, key.Enter), EmPartida(gerador, partida_base))
  // Teclas na tela de resultado
  check.eq(trata_tecla(Resultado(gerador, 1), 2, key.Enter), inicia_partida(gerador))
  check.eq(trata_tecla(Resultado(gerador, 1), 2, key.Char("1")), Resultado(gerador, 1))
}

/// Determina a direção correspondente à seta pressionada. Para outras teclas, retorna None.
pub fn direcao(tecla: key.Event) -> Option(Direcao) {
  case tecla {
    key.ArrowUp -> Some(Cima)
    key.ArrowDown -> Some(Baixo)
    key.ArrowLeft -> Some(Esquerda)
    key.ArrowRight -> Some(Direita)
    _ -> None
  }
}
pub fn direcao_examples() {
  check.eq(direcao(key.ArrowUp), Some(Cima))
  check.eq(direcao(key.ArrowDown), Some(Baixo))
  check.eq(direcao(key.ArrowLeft), Some(Esquerda))
  check.eq(direcao(key.ArrowRight), Some(Direita))
  // Enter não indica uma direção
  check.eq(direcao(key.Enter), None)
}

/// Identifica a alternativa escolhida (1, 2 ou 3). Se a tecla não corresponde a uma alternativa, retorna None.
pub fn alternativa(tecla: key.Event) -> Option(Int) {
  case tecla {
    key.Char("1") -> Some(1)
    key.Char("2") -> Some(2)
    key.Char("3") -> Some(3)
    _ -> None
  }
}
pub fn alternativa_examples() {
  check.eq(alternativa(key.Char("1")), Some(1))
  check.eq(alternativa(key.Char("2")), Some(2))
  check.eq(alternativa(key.Char("3")), Some(3))
  check.eq(alternativa(key.Char("4")), None)
}

/// trata a tecla de acordo com o que o jogador está fazendo na partida
/// se estiver andando usa as setas, se estiver no enigma usa 1, 2 ou 3 e se estiver bloqueado ignora a tecla
pub fn trata_tecla_partida(gerador: Generator, partida: Partida, numero: Int, tecla: key.Event) -> Estado {
  case acha_jogador(partida.jogadores, numero) {
    Error(_) -> EmPartida(gerador, partida)
    Ok(jogador) ->
      case jogador.acao {
        Andando ->
          case direcao(tecla) {
            Some(d) -> anda(gerador, partida, numero, d)
            None -> EmPartida(gerador, partida)
          }
        ResolvendoEnigma(enigma, _) ->
          case alternativa(tecla) {
            Some(n) -> responde(gerador, partida, numero, enigma, n)
            None -> EmPartida(gerador, partida)
          }
        Bloqueado(_) -> EmPartida(gerador, partida)
      }
  }
}
pub fn trata_tecla_partida_examples() {
  let gerador = random.new(0)
  let enigma = enigma_teste()
  let partida_base = partida_teste()
  let resolvendo = troca_acao(partida_base, 1, ResolvendoEnigma(enigma, 50))
  let bloqueado = troca_acao(partida_base, 1, Bloqueado(30))
  // Jogador andando
  check.eq(trata_tecla_partida(gerador, partida_base, 1, key.ArrowRight), EmPartida(gerador, move(partida_base, 1, Direita)))
  check.eq(trata_tecla_partida(gerador, partida_base, 1, key.Char("1")), EmPartida(gerador, partida_base))
  // Jogador resolvendo o enigma
  check.eq(trata_tecla_partida(gerador, resolvendo, 1, key.ArrowRight), EmPartida(gerador, resolvendo))
  check.eq(trata_tecla_partida(gerador, resolvendo, 1, key.Char("2")), Resultado(gerador, 1))
  // Jogador bloqueado ou inexistente
  check.eq(trata_tecla_partida(gerador, bloqueado, 1, key.ArrowRight), EmPartida(gerador, bloqueado))
  check.eq(trata_tecla_partida(gerador, partida_base, 3, key.ArrowRight), EmPartida(gerador, partida_base))
}

// PARTIDA
/// sorteia o mapa e coloca cada jogador na sua casa inicial
pub fn inicia_partida(gerador: Generator) -> Estado {
  let #(mapa, gerador) = sorteia(gerador, mapas(), ler_mapa(labirinto_1))
  let jogadores = [Jogador(1, mapa.inicio, Andando), Jogador(2, mapa.inicio_2, Andando)]
  EmPartida(gerador, Partida(jogadores, mapa))
}
pub fn inicia_partida_examples() {
  let mapa = ler_mapa(labirinto_1)
  let gerador_teste = random.mock([random.pick_returns(mapas(), Ok(mapa))])
  // Início da partida com o mapa sorteado e os jogadores em casas diferentes
  check.eq(
    inicia_partida(gerador_teste),
    EmPartida(
      random.mock([]),
      Partida([Jogador(1, Posicao(9, 1), Andando), Jogador(2, Posicao(8, 0), Andando)], mapa),
    ),
  )
}

/// Procura o jogador de acordo com seu *numero*. Caso não encontre, retorna Error.
pub fn acha_jogador(jogadores: List(Jogador), numero: Int) -> Result(Jogador, Nil) {
  list.find(jogadores, fn(jogador) { jogador.numero == numero })
}
pub fn acha_jogador_examples() {
  let jogadores = [Jogador(1, Posicao(0, 0), Andando), Jogador(2, Posicao(1, 1), Andando)]
  check.eq(acha_jogador(jogadores, 2), Ok(Jogador(2, Posicao(1, 1), Andando)))
  check.eq(acha_jogador(jogadores, 3), Error(Nil))
}

/// Calcula a próxima posição a partir de *p* e da direção *d*.
pub fn destino(p: Posicao, d: Direcao) -> Posicao {
  case d {
    Cima -> Posicao(p.lin - 1, p.col)
    Baixo -> Posicao(p.lin + 1, p.col)
    Esquerda -> Posicao(p.lin, p.col - 1)
    Direita -> Posicao(p.lin, p.col + 1)
  }
}
pub fn destino_examples() {
  check.eq(destino(Posicao(4, 5), Cima), Posicao(3, 5))
  check.eq(destino(Posicao(4, 5), Baixo), Posicao(5, 5))
  check.eq(destino(Posicao(4, 5), Esquerda), Posicao(4, 4))
  check.eq(destino(Posicao(4, 5), Direita), Posicao(4, 6))
}

/// move o jogador *numero* uma casa na direção *d*, se ele estiver andando e a casa for livre
/// os dois jogadores podem ficar na mesma casa
pub fn move(partida: Partida, numero: Int, d: Direcao) -> Partida {
  atualiza_jogador(partida, numero, fn(jogador) {
    let nova = destino(jogador.posicao, d)
    case jogador.acao == Andando && caminho_livre(partida.mapa, nova) {
      True -> Jogador(..jogador, posicao: nova)
      False -> jogador
    }
  })
}
pub fn move_examples() {
  let partida_base = partida_teste()
  let j1 = Jogador(1, Posicao(1, 1), Andando)
  let j2 = Jogador(2, Posicao(1, 1), Andando)
  // Movimentação dos dois jogadores
  check.eq(move(partida_base, 1, Direita), Partida(..partida_base, jogadores: [Jogador(1, Posicao(1, 2), Andando), j2]))
  check.eq(move(partida_base, 2, Baixo), Partida(..partida_base, jogadores: [j1, Jogador(2, Posicao(2, 1), Andando)]))
  // Tentativas de andar contra a parede ou sair do mapa
  check.eq(move(partida_base, 1, Cima), partida_base)
  check.eq(move(partida_base, 3, Direita), partida_base)
  let canto = Partida(..partida_base, jogadores: [Jogador(1, Posicao(0, 0), Andando)])
  check.eq(move(canto, 1, Esquerda), canto)
  let bloqueado = troca_acao(partida_base, 1, Bloqueado(5))
  // Jogador bloqueado ou resolvendo não pode andar
  check.eq(move(bloqueado, 1, Direita), bloqueado)
  let resolvendo = troca_acao(partida_base, 1, ResolvendoEnigma(enigma_teste(), 5))
  check.eq(move(resolvendo, 1, Direita), resolvendo)
  // Os dois podem ocupar a mesma casa
  let juntos = partida_base |> move(1, Direita) |> move(2, Direita)
  check.eq(juntos.jogadores, [
    Jogador(1, Posicao(1, 2), Andando),
    Jogador(2, Posicao(1, 2), Andando),
  ])
}

/// Verifica se o jogador *numero* está na posição da porta.
pub fn na_porta(partida: Partida, numero: Int) -> Bool {
  list.any(partida.jogadores, fn(jogador) {
    jogador.numero == numero && jogador.posicao == partida.mapa.porta
  })
}
pub fn na_porta_examples() {
  let partida_base = Partida(..partida_teste(), jogadores: [
      Jogador(1, Posicao(1, 3), Andando),
      Jogador(2, Posicao(1, 1), Andando),
    ])
  check.eq(na_porta(partida_base, 1), True)
  check.eq(na_porta(partida_base, 2), False)
  check.eq(na_porta(partida_base, 3), False)
}

/// move o jogador e sorteia um enigma se ele acabou de entrar na casa da porta
/// para receber outro enigma, ele precisa sair da porta e entrar de novo
pub fn anda(gerador: Generator, partida: Partida, numero: Int, d: Direcao) -> Estado {
  let nova = move(partida, numero, d)
  case na_porta(nova, numero) && !na_porta(partida, numero) {
    True -> {
      let #(enigma, gerador) = sorteia_enigma(gerador)
      EmPartida(gerador, troca_acao(nova, numero, ResolvendoEnigma(enigma, tempo_enigma)))
    }
    False -> EmPartida(gerador, nova)
  }
}
pub fn anda_examples() {
  let partida_base = partida_teste()
  let vizinha = move(partida_base, 1, Direita)
  let porta = move(vizinha, 1, Direita)
  let vazio = random.mock([])
  // Anda pelo corredor sem sortear um enigma
  check.eq(anda(vazio, partida_base, 1, Direita), EmPartida(vazio, vizinha))
  let numeros = sequencia(2, 9)
  let pares = [ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)]
  let sorteios = [
    random.pick_returns([FormatoA, FormatoB, FormatoC, FormatoD], Ok(FormatoB)),
    random.pick_returns(numeros, Ok(7)), random.pick_returns(numeros, Ok(3)),
    random.pick_returns(numeros, Ok(4)), random.pick_returns(numeros, Ok(5)),
  ]
  let primeiro = list.append(sorteios, [random.pick_returns(pares, Ok(ParErros(-1, 1)))])
  let segundo = list.append(sorteios, [random.pick_returns(pares, Ok(ParErros(1, 2)))])
  let gerador = random.mock(list.append(primeiro, segundo))
  let restante = random.mock(segundo)
  let entrada = anda(gerador, vizinha, 1, Direita)
  // Chegou na porta -> sorteia o primeiro enigma
  check.eq(entrada, EmPartida(restante, troca_acao(porta, 1, ResolvendoEnigma(enigma_teste(), 100))))
  let assert EmPartida(gerador, partida) = entrada
  let liberado = tique(EmPartida(gerador, troca_acao(partida, 1, Bloqueado(1))))
  // Acabou o bloqueio
  check.eq(liberado, EmPartida(restante, porta))
  let assert EmPartida(gerador, partida) = liberado
  // Continua na porta ao tentar andar contra a parede
  check.eq(anda(gerador, partida, 1, Direita), liberado)
  let saida = anda(gerador, partida, 1, Esquerda)
  check.eq(saida, EmPartida(restante, vizinha))
  let assert EmPartida(gerador, partida) = saida
  let novo = Enigma("(7 - 3) + 4 × 5", [24, 25, 26], 1)
  // Volta para a porta e recebe outro enigma
  check.eq(anda(gerador, partida, 1, Direita), EmPartida(vazio, troca_acao(porta, 1, ResolvendoEnigma(novo, 100))))
}

/// Aplica *altera* apenas ao jogador de número *numero*.
fn atualiza_jogador(partida: Partida, numero: Int, altera: fn(Jogador) -> Jogador) -> Partida {
  let jogadores = list.map(partida.jogadores, fn(jogador) {
    case jogador.numero == numero {
      True -> altera(jogador)
      False -> jogador
    }
  })
  Partida(..partida, jogadores: jogadores)
}

pub fn atualiza_jogador_examples() {
  let partida = partida_teste()
  let altera = fn(jogador) { Jogador(..jogador, posicao: Posicao(1, 2)) }
  check.eq(atualiza_jogador(partida, 1, altera).jogadores, [
    Jogador(1, Posicao(1, 2), Andando), Jogador(2, Posicao(1, 1), Andando),
  ])
  check.eq(atualiza_jogador(partida, 3, altera), partida)
}

/// muda a ação do jogador *numero* para *acao*
pub fn troca_acao(partida: Partida, numero: Int, acao: Acao) -> Partida {
  atualiza_jogador(partida, numero, fn(jogador) { Jogador(..jogador, acao: acao) })
}
pub fn troca_acao_examples() {
  // Apenas o jogador 2 fica bloqueado
  check.eq(troca_acao(partida_teste(), 2, Bloqueado(30)).jogadores, [
    Jogador(1, Posicao(1, 1), Andando),
    Jogador(2, Posicao(1, 1), Bloqueado(30)),
  ])
  // Jogador inexistente -> partida permanece igual
  check.eq(troca_acao(partida_teste(), 3, Bloqueado(30)), partida_teste())
}

// Enigmas

/// Calcula o resultado da expressão de acordo com os quatro números e o *formato*.
/// Considera a ordem das operações aritméticas.
pub fn calcula(formato: Expressao, a: Int, b: Int, c: Int, d: Int) -> Int {
  case formato {
    FormatoA -> { a + b } * c - d
    FormatoB -> { a - b } + c * d
    FormatoC -> a * b + c - d
    FormatoD -> { a + b } * { c - d }
  }
}
pub fn calcula_examples() {
  check.eq(calcula(FormatoA, 2, 3, 4, 5), 15)
  check.eq(calcula(FormatoB, 7, 3, 4, 5), 24)
  check.eq(calcula(FormatoC, 2, 3, 4, 5), 5)
  check.eq(calcula(FormatoD, 2, 3, 4, 5), -5)
}

/// Converte a expressão formada por *a*, *b*, *c* e *d* em uma string.
pub fn escreve(formato: Expressao, a: Int, b: Int, c: Int, d: Int) -> String {
  let para_texto = int.to_string
  case formato {
    FormatoA -> "(" <> para_texto(a) <> " + " <> para_texto(b) <> ") × " <> para_texto(c) <> " - " <> para_texto(d)
    FormatoB -> "(" <> para_texto(a) <> " - " <> para_texto(b) <> ") + " <> para_texto(c) <> " × " <> para_texto(d)
    FormatoC -> para_texto(a) <> " × " <> para_texto(b) <> " + " <> para_texto(c) <> " - " <> para_texto(d)
    FormatoD ->
      "(" <> para_texto(a) <> " + " <> para_texto(b) <> ") × (" <> para_texto(c) <> " - " <> para_texto(d) <> ")"
  }
}
pub fn escreve_examples() {
  check.eq(escreve(FormatoA, 2, 3, 4, 5), "(2 + 3) × 4 - 5")
  check.eq(escreve(FormatoB, 7, 3, 4, 5), "(7 - 3) + 4 × 5")
  check.eq(escreve(FormatoC, 2, 3, 4, 5), "2 × 3 + 4 - 5")
  check.eq(escreve(FormatoD, 2, 3, 4, 5), "(2 + 3) × (4 - 5)")
}

/// Cria um enigma com três alternativas em ordem crescente.
/// Calcula as alternativas incorretas somando os valores de *erros* ao resultado da expressão.
/// Os valores de *erros* devem ser distintos, entre -2 e 2 e diferentes de zero.
pub fn monta_enigma(formato: Expressao, a: Int, b: Int, c: Int, d: Int, erros: ParErros) -> Enigma {
  let certa = calcula(formato, a, b, c, d)
  let alternativas = list.sort([certa, certa + erros.primeiro, certa + erros.segundo], int.compare)
  let menores = alternativas |> list.filter(fn(x) { x < certa }) |> list.length
  let correta = menores + 1
  Enigma(escreve(formato, a, b, c, d), alternativas, correta)
}
pub fn monta_enigma_examples() {
  // Resposta certa em posições diferentes
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(-1, 1)), Enigma("(7 - 3) + 4 × 5", [23, 24, 25], 2))
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(-2, -1)), Enigma("(7 - 3) + 4 × 5", [22, 23, 24], 3))
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(1, 2)), Enigma("(7 - 3) + 4 × 5", [24, 25, 26], 1))
  // Enigma com resposta negativa
  check.eq(monta_enigma(FormatoD, 2, 3, 4, 5, ParErros(-2, 1)), Enigma("(2 + 3) × (4 - 5)", [-7, -5, -4], 2))
}

/// Sorteia o formato da expressão, quatro números entre 2 e 9 e um par de erros.
/// Cada par permite que a resposta correta ocupe uma posição diferente, com a mesma chance.
pub fn sorteia_enigma(gerador: Generator) -> #(Enigma, Generator) {
  let formatos = [FormatoA, FormatoB, FormatoC, FormatoD]
  let pares = [ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)]
  let numeros = sequencia(2, 9)
  let #(formato, gerador) = sorteia(gerador, formatos, FormatoA)
  let #(a, gerador) = sorteia(gerador, numeros, 2)
  let #(b, gerador) = sorteia(gerador, numeros, 2)
  let #(c, gerador) = sorteia(gerador, numeros, 2)
  let #(d, gerador) = sorteia(gerador, numeros, 2)
  let #(erros, gerador) = sorteia(gerador, pares, ParErros(-1, 1))
  #(monta_enigma(formato, a, b, c, d, erros), gerador)
}
pub fn sorteia_enigma_examples() {
  let numeros = sequencia(2, 9)
  let pares = [ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)]
  let gerador = random.mock([
    random.pick_returns([FormatoA, FormatoB, FormatoC, FormatoD], Ok(FormatoD)),
    random.pick_returns(numeros, Ok(2)),
    random.pick_returns(numeros, Ok(3)),
    random.pick_returns(numeros, Ok(4)),
    random.pick_returns(numeros, Ok(5)),
    random.pick_returns(pares, Ok(ParErros(-1, 1))),
  ])
  // Enigma sorteado e gerador sem sorteios restantes
  check.eq(sorteia_enigma(gerador), #(Enigma("(2 + 3) × (4 - 5)", [-6, -5, -4], 2), random.mock([])))
}

/// Representa o enigma utilizado nos exemplos (resposta 24, alternativa 2).
pub fn enigma_teste() -> Enigma {
  Enigma("(7 - 3) + 4 × 5", [23, 24, 25], 2)
}

/// Verifica se a alternativa escolhida pelo jogador *numero* está correta.
/// Se estiver correta, o jogador vence a partida. Caso contrário, fica bloqueado.
pub fn responde(gerador: Generator, partida: Partida, numero: Int, enigma: Enigma, escolha: Int) -> Estado {
  case escolha == enigma.correta {
    True -> Resultado(gerador, numero)
    False -> EmPartida(gerador, troca_acao(partida, numero, Bloqueado(tempo_bloqueio)))
  }
}
pub fn responde_examples() {
  let gerador = random.new(0)
  let enigma = enigma_teste()
  let partida_base = troca_acao(partida_teste(), 2, ResolvendoEnigma(enigma, 50))
  // Acertou o enigma -> venceu
  check.eq(responde(gerador, partida_base, 2, enigma, 2), Resultado(gerador, 2))
  // Errou -> fica bloqueado por 3 segundos
  check.eq(responde(gerador, partida_base, 2, enigma, 3), EmPartida(gerador, troca_acao(partida_base, 2, Bloqueado(30))))
}

// TIQUES 
/// Atualiza o estado da partida a cada tique do relógio, sem alterar os outros estados.
/// O tempo de cada jogador é contado separadamente.
pub fn tique(estado: Estado) -> Estado {
  case estado {
    EmPartida(gerador, partida) -> EmPartida(gerador, avanca_partida(partida))
    _ -> estado
  }
}
pub fn tique_examples() {
  let gerador = random.new(0)
  let partida_base = partida_teste()
    |> troca_acao(1, ResolvendoEnigma(enigma_teste(), 50))
    |> troca_acao(2, Bloqueado(30))
  // Relógio na abertura e no resultado não altera o estado
  check.eq(tique(Abertura(gerador)), Abertura(gerador))
  check.eq(tique(Resultado(gerador, 1)), Resultado(gerador, 1))
  // Diminui o tempo dos dois jogadores
  check.eq(
    tique(EmPartida(gerador, partida_base)),
    EmPartida(
      gerador,
      Partida(..partida_base, jogadores: [
        Jogador(1, Posicao(1, 1), ResolvendoEnigma(enigma_teste(), 49)),
        Jogador(2, Posicao(1, 1), Bloqueado(29)),
      ]),
    ),
  )
}

/// Atualiza a ação de cada jogador da partida após um tique.
pub fn avanca_partida(partida: Partida) -> Partida {
  Partida(..partida, jogadores: list.map(partida.jogadores, tique_jogador))
}
pub fn avanca_partida_examples() {
  let partida_base = partida_teste()
  let bloqueado = troca_acao(partida_base, 2, Bloqueado(2))
  check.eq(avanca_partida(partida_base), partida_base)
  check.eq(avanca_partida(bloqueado), troca_acao(partida_base, 2, Bloqueado(1)))
}

/// Avança em um tique o contador do *jogador*. Quando o tempo do enigma acaba, o jogador é bloqueado. Quando o
/// bloqueio acaba, o jogador volta a andar.
pub fn tique_jogador(jogador: Jogador) -> Jogador {
  let acao = case jogador.acao {
    Andando -> Andando
    ResolvendoEnigma(enigma, tiques) -> case tiques <= 1 {
      True -> Bloqueado(tempo_bloqueio)
      False -> ResolvendoEnigma(enigma, tiques - 1)
    }
    Bloqueado(tiques) -> case tiques <= 1 {
      True -> Andando
      False -> Bloqueado(tiques - 1)
    }
  }
  Jogador(..jogador, acao: acao)
}
pub fn tique_jogador_examples() {
  let posicao = Posicao(1, 1)
  let enigma = enigma_teste()
  check.eq(tique_jogador(Jogador(1, posicao, Andando)), Jogador(1, posicao, Andando))
  // Tempo do enigma (quando acaba, o jogador fica bloqueado)
  check.eq(tique_jogador(Jogador(1, posicao, ResolvendoEnigma(enigma, 100))), Jogador(1, posicao, ResolvendoEnigma(enigma, 99)))
  check.eq(tique_jogador(Jogador(1, posicao, ResolvendoEnigma(enigma, 1))), Jogador(1, posicao, Bloqueado(30)))
  // Tempo de bloqueio (quando acaba, volta a andar)
  check.eq(tique_jogador(Jogador(1, posicao, Bloqueado(30))), Jogador(1, posicao, Bloqueado(29)))
  check.eq(tique_jogador(Jogador(1, posicao, Bloqueado(1))), Jogador(1, posicao, Andando))
}

/// Uma posição está no campo de visão quando difere no máximo uma casa em cada eixo
pub fn visivel(p: Posicao, centro: Posicao) -> Bool {
  distancia(p, centro) <= 1
}
pub fn visivel_examples() {
  // Casas dentro do campo de visão
  check.eq(visivel(Posicao(8, 8), Posicao(9, 9)), True)
  check.eq(visivel(Posicao(9, 9), Posicao(9, 9)), True)
  // Casas fora do campo de visão
  check.eq(visivel(Posicao(11, 9), Posicao(9, 9)), False)
  check.eq(visivel(Posicao(9, 7), Posicao(9, 9)), False)
  check.eq(visivel(Posicao(11, 11), Posicao(9, 9)), False)
}

/// Retorna a distância entre *a* e *b*, a maior diferença entre as linhas ou entre as colunas. As paredes são
/// ignoradas.
pub fn distancia(a: Posicao, b: Posicao) -> Int {
  int.max(int.absolute_value(a.lin - b.lin), int.absolute_value(a.col - b.col))
}
pub fn distancia_examples() {
  check.eq(distancia(Posicao(3, 3), Posicao(3, 3)), 0)
  check.eq(distancia(Posicao(3, 3), Posicao(4, 4)), 1)
  check.eq(distancia(Posicao(3, 3), Posicao(3, 7)), 4)
  check.eq(distancia(Posicao(1, 2), Posicao(6, 4)), 5)
}

/// Retorna True se algum adversário de *jogador_atual* está fora do campo de visão, mas a 2, 3 ou 4 casas de distância
pub fn adversario_perto(jogadores: List(Jogador), jogador_atual: Jogador) -> Bool {
  list.any(jogadores, fn(jogador) {
    let d = distancia(jogador.posicao, jogador_atual.posicao)
    jogador.numero != jogador_atual.numero && d >= 2 && d <= 4
  })
}
pub fn adversario_perto_examples() {
  let jogador_atual = Jogador(1, Posicao(9, 9), Andando)
  let com = fn(p) { [jogador_atual, Jogador(2, p, Andando)] }
  // Adversário já está visível
  check.eq(adversario_perto(com(Posicao(10, 10)), jogador_atual), False)
  // Adversário entre 2 e 4 casas de distância
  check.eq(adversario_perto(com(Posicao(9, 11)), jogador_atual), True)
  check.eq(adversario_perto(com(Posicao(13, 5)), jogador_atual), True)
  // Adversário longe ou inexistente
  check.eq(adversario_perto(com(Posicao(9, 14)), jogador_atual), False)
  check.eq(adversario_perto([jogador_atual], jogador_atual), False)
}

/// devolve True se *acao* é ResolvendoEnigma.
pub fn resolvendo(acao: Acao) -> Bool {
  case acao {
    ResolvendoEnigma(_, _) -> True
    _ -> False
  }
}

///devolve True se algum adversário do jogador *numero* está resolvendo um enigma
pub fn adversario_na_porta(jogadores: List(Jogador), numero: Int) -> Bool {
  list.any(jogadores, fn(jogador) { jogador.numero != numero && resolvendo(jogador.acao) })
}
pub fn adversario_na_porta_examples() {
  let posicao = Posicao(1, 1)
  let jogadores = [Jogador(1, posicao, ResolvendoEnigma(enigma_teste(), 5)), Jogador(2, posicao, Andando)]
  // Jogadores andando ou bloqueados não estão resolvendo
  check.eq(resolvendo(Andando), False)
  check.eq(resolvendo(Bloqueado(3)), False)
  // Apenas o adversário recebe o aviso
  check.eq(adversario_na_porta(jogadores, 2), True)
  check.eq(adversario_na_porta(jogadores, 1), False)
}

/// Devolve True se a porta da *partida* aparece na tela do jogador *jogador_atual*, ela está no campo de visão ou um
/// adversário está resolvendo o enigma.
pub fn porta_visivel(partida: Partida, jogador_atual: Jogador) -> Bool {
  visivel(partida.mapa.porta, jogador_atual.posicao)
  || adversario_na_porta(partida.jogadores, jogador_atual.numero)
}
pub fn porta_visivel_examples() {
  let partida_base = partida_teste()
  let longe = Jogador(1, Posicao(9, 9), Andando)
  let perto = Jogador(1, Posicao(1, 2), Andando)
  let parado = Jogador(2, Posicao(1, 1), Andando)
  let na_porta = Jogador(2, Posicao(1, 3), ResolvendoEnigma(enigma_teste(), 9))
  check.eq(porta_visivel(Partida(..partida_base, jogadores: [longe, parado]), longe), False)
  check.eq(porta_visivel(Partida(..partida_base, jogadores: [perto, parado]), perto), True)
  // Porta longe, mas o adversário está resolvendo o enigma
  check.eq(porta_visivel(Partida(..partida_base, jogadores: [longe, na_porta]), longe), True)
}

// Resultado 
/// Produz a mensagem de resultado para o jogador *numero*, quando o jogador *vencedor* venceu a partida.
pub fn mensagem_resultado(vencedor: Int, numero: Int) -> String {
  case vencedor == numero {
    True -> "Você venceu!"
    False -> "Você perdeu!"
  }
}
pub fn mensagem_resultado_examples() {
  check.eq(mensagem_resultado(1, 1), "Você venceu!")
  check.eq(mensagem_resultado(1, 2), "Você perdeu!")
}

// Desenhos
///devolve a quantidade de segundos que faltam para *tiques* tiques passarem, arredondada para cima
pub fn segundos_restantes(tiques: Int) -> Int {
  { tiques + tiques_por_segundo - 1 } / tiques_por_segundo
}
pub fn segundos_restantes_examples() {
  check.eq(segundos_restantes(0), 0)
  // Menos de um segundo -> mostra 1
  check.eq(segundos_restantes(1), 1)
  check.eq(segundos_restantes(90), 9)
  // Arredonda para 10 segundos
  check.eq(segundos_restantes(91), 10)
}

///devolve a cor do jogador *numero*
pub fn cor(numero: Int) -> Color {
  case numero {
    1 -> color.red
    _ -> color.blue
  }
}
pub fn cor_examples() {
  check.eq(cor(1), color.red)
  check.eq(cor(2), color.blue)
}

///produz uma imagem com o texto *s* em preto, com tamanho *tamanho_fonte*
pub fn texto(s: String, tamanho_fonte: Int) -> Image {
  image.text(s, tamanho_fonte, fill.black)
}
pub fn texto_examples() {
  check.same(texto("Porta", 18), image.text("Porta", 18, fill.black))
}

///empilha as *imagens*, a primeira no topo
pub fn empilha(imagens: List(Image)) -> Image {
  list.fold(imagens, image.empty, image.above)
}
pub fn empilha_examples() {
  let topo = image.square(14, fill.blue)
  let base = image.circle(5, fill.gold)
  // Lista vazia -> imagem vazia
  check.same(empilha([]), image.empty)
  check.same(empilha([topo, base]), image.above(topo, base))
  let meio = image.square(8, fill.black)
  check.same(empilha([topo, meio, base]), image.above(image.above(topo, meio), base))
}

///coloca a *imagem* centralizada na casa *p* da *cena*.
pub fn coloca(cena: Image, p: Posicao, imagem: Image) -> Image {
  image.place_image(cena, p.col * lado_casa + lado_casa / 2, p.lin * lado_casa + lado_casa / 2, imagem)
}
pub fn coloca_examples() {
  let cena = image.empty_scene(480, 480)
  let bola = image.circle(10, fill.gold)
  check.same(coloca(cena, Posicao(0, 0), bola), image.place_image(cena, 12, 12, bola))
  check.same(coloca(cena, Posicao(2, 5), bola), image.place_image(cena, 132, 60, bola))
}

///desenha o chão ou a parede da casa *p* do *mapa*
pub fn desenha_casa(mapa: Mapa, p: Posicao) -> Image {
  case simbolo_em(mapa.linhas, p) {
    "#" -> image.square(lado_casa - 1, fill.slategray)
    _ -> image.square(lado_casa - 1, fill.lightyellow)
  }
}

///desenha a saída
pub fn desenha_porta() -> Image {
  image.square(lado_casa - 1, fill.gold)
}
pub fn desenha_casa_examples() {
  let mapa = mapa_teste()
  check.same(desenha_casa(mapa, Posicao(0, 0)), image.square(23, fill.slategray))
  check.same(desenha_casa(mapa, Posicao(1, 2)), image.square(23, fill.lightyellow))
  check.same(desenha_porta(), image.square(23, fill.gold))
}

///desenha o personagem do jogador *numero*, com uma borda grossa se *destaque* é True.
pub fn personagem(numero: Int, destaque: Bool) -> Image {
  let borda = case destaque {
    True -> [style.stroke(color.black), style.stroke_width(3)]
    False -> []
  }
  image.square(lado_casa / 2 - 2, style.join([style.fill(cor(numero)), ..borda]))
}
pub fn personagem_examples() {
  check.same(personagem(2, False), image.square(10, style.fill(color.blue)))
  // Próprio personagem com contorno
  check.same(personagem(1, True), image.square(10, style.join([style.fill(color.red), style.stroke(color.black), style.stroke_width(3)])))
}

///coloca na *cena* o personagem do *jogador*, destacado se for o jogador *jogador_atual*.
///o jogador 1 é colocado para a esquerda e o
///jogador 2 para a direita, para que os dois sejam vistos na mesma casa.
pub fn coloca_jogador(cena: Image, jogador: Jogador, jogador_atual: Int) -> Image {
  let dx = case jogador.numero {
    1 -> -6
    _ -> 6
  }
  image.place_image(
    cena,
    jogador.posicao.col * lado_casa + lado_casa / 2 + dx,
    jogador.posicao.lin * lado_casa + lado_casa / 2,
    personagem(jogador.numero, jogador.numero == jogador_atual),
  )
}
pub fn coloca_jogador_examples() {
  let cena = image.empty_scene(480, 480)
  let j = Jogador(2, Posicao(1, 2), Andando)
  check.same(coloca_jogador(cena, j, 1), image.place_image(cena, 66, 36, image.square(10, style.fill(color.blue))))
}

///desenha o labirinto para o jogador *jogador_atual* com tudo escuro, exceto o quadrado 3x3 ao redor dele
///mostra a porta quando ela está visível e o adversário quando ele está no campo de visão
pub fn desenha_mapa(partida: Partida, jogador_atual: Jogador) -> Image {
  let fundo = image.rectangle(tamanho * lado_casa, tamanho * lado_casa, fill.black)
  let com_casas =
    todas_as_casas()
    |> list.filter(fn(p) { visivel(p, jogador_atual.posicao) })
    |> list.fold(fundo, fn(cena, p) { coloca(cena, p, desenha_casa(partida.mapa, p)) })
  let com_porta = case porta_visivel(partida, jogador_atual) {
    True -> coloca(com_casas, partida.mapa.porta, desenha_porta())
    False -> com_casas
  }
  list.fold(partida.jogadores, com_porta, fn(cena, jogador) {
    case jogador.numero == jogador_atual.numero || visivel(jogador.posicao, jogador_atual.posicao) {
      True -> coloca_jogador(cena, jogador, jogador_atual.numero)
      False -> cena
    }
  })
}

///produz o aviso de porta para o jogador *numero*, mostrando que o adversário chegou na saida
pub fn aviso_porta(jogadores: List(Jogador), numero: Int) -> String {
  case adversario_na_porta(jogadores, numero) {
    True -> "Adversário na porta!"
    False -> " "
  }
}

///produz o aviso de proximidade para o jogador *jogador_atual*, retorna
///se o adversário esta próximo ou não
pub fn aviso_perto(jogadores: List(Jogador), jogador_atual: Jogador) -> String {
  case adversario_perto(jogadores, jogador_atual) {
    True -> "Alguém está perto!"
    False -> " "
  }
}
pub fn avisos_examples() {
  let jogador_atual = Jogador(1, Posicao(9, 9), Andando)
  let na_porta = Jogador(2, Posicao(1, 3), ResolvendoEnigma(enigma_teste(), 9))
  let perto = Jogador(2, Posicao(9, 11), Andando)
  check.eq(aviso_porta([jogador_atual, na_porta], 1), "Adversário na porta!")
  check.eq(aviso_porta([jogador_atual, perto], 1), " ")
  check.eq(aviso_perto([jogador_atual, perto], jogador_atual), "Alguém está perto!")
  check.eq(aviso_perto([jogador_atual, na_porta], jogador_atual), " ")
}

///desenha a tela de abertura para o jogador *numero*.
pub fn tela_abertura(numero: Int) -> Image {
  empilha([
    texto("Corrida no Labirinto Escuro", 28),
    texto("Os jogadores começam em casas diferentes.", 16),
    texto("Cada um vê só as casas ao redor de si.", 16),
    texto("Ache a porta e resolva a expressão antes do outro.", 16),
    texto("Setas: andar    1, 2 ou 3: responder o enigma", 16),
    image.text("Você é o jogador " <> int.to_string(numero), 20, style.fill(cor(numero))),
    texto("Pressione Enter para começar", 22),
  ])
}

///desenha a tela da *partida* para o jogador *numero*, de acordo com a ação dele
pub fn tela_partida(partida: Partida, numero: Int) -> Image {
  case acha_jogador(partida.jogadores, numero) {
    Error(_) -> texto("Jogador não encontrado", 20)
    Ok(jogador_atual) ->
      case jogador_atual.acao {
        Andando -> tela_labirinto(partida, jogador_atual)
        ResolvendoEnigma(enigma, tiques) -> tela_enigma(enigma, tiques)
        Bloqueado(tiques) -> tela_bloqueio(tiques)
      }
  }
}

///desenha o labirinto, com os avisos no topo, para o jogador *jogador_atual*
pub fn tela_labirinto(partida: Partida, jogador_atual: Jogador) -> Image {
  image.above(
    empilha([
      image.text(
        "Você é o jogador " <> int.to_string(jogador_atual.numero),
        16,
        style.fill(cor(jogador_atual.numero)),
      ),
      texto(aviso_porta(partida.jogadores, jogador_atual.numero), 14),
      texto(aviso_perto(partida.jogadores, jogador_atual), 14),
    ]),
    desenha_mapa(partida, jogador_atual),
  )
}

///desenha a tela do enigma, a expressão, as três alternativas e o tempo restante
pub fn tela_enigma(enigma: Enigma, tiques: Int) -> Image {
  let alternativas = list.index_map(enigma.alternativas, fn(a, i) {
      texto(int.to_string(i + 1) <> ") " <> int.to_string(a), 28)
    })
  let rodape = [texto("Tempo: " <> int.to_string(segundos_restantes(tiques)) <> " s", 22),
    texto("Pressione 1, 2 ou 3", 18)]
  empilha([texto("Resolva a expressão:", 22), texto(enigma.expressao <> " = ?", 32),
    ..list.append(alternativas, rodape)])
}

///desenha a tela de bloqueio, com o tempo restante
pub fn tela_bloqueio(tiques: Int) -> Image {
  empilha([
    texto("Resposta errada ou tempo esgotado!", 26),
    texto("Aguarde " <> int.to_string(segundos_restantes(tiques)) <> " s", 24),
    texto("Depois saia da porta e entre de novo.", 16),
  ])
}

///desenha a tela de resultado para o jogador *numero*
pub fn tela_resultado(vencedor: Int, numero: Int) -> Image {
  empilha([texto(mensagem_resultado(vencedor, numero), 32), texto("Pressione Enter para jogar novamente", 20)])
}

///desenha a tela do *estado* para o jogador *numero*
pub fn tela(estado: Estado, numero: Int) -> Image {
  let conteudo = case estado {
    Abertura(_) -> tela_abertura(numero)
    EmPartida(_, partida) -> tela_partida(partida, numero)
    Resultado(_, vencedor) -> tela_resultado(vencedor, numero)
  }
  image.overlay(conteudo, image.rectangle(largura, altura, fill.white))
}

/// Partida para os exemplos com um mapa pequeno e os dois jogadores na mesma casa.
pub fn partida_teste() -> Partida {
  Partida([Jogador(1, Posicao(1, 1), Andando), Jogador(2, Posicao(1, 1), Andando)], mapa_teste())
}