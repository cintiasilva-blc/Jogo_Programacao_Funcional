// Corrida no Labirinto Escuro
//
// Cíntia da Silva Bulcão - RA 145107.
// Giovana da Silva Bulcão - RA 144325.
//
// Regras
//
// - Dois jogadores começam em casas diferentes (S e T) de um labirinto 20x20.
//   No início de cada partida um dos cinco labirintos é sorteado.
// - O labirinto é escuro: cada jogador vê apenas a sua casa e as 8 casas ao
//   redor (quadrado 3x3). Não há memória das casas já visitadas.
// - O adversário só aparece se estiver no seu quadrado 3x3. Se ele estiver
//   fora do quadrado, mas a 2 a 4 casas de distância, aparece o aviso
//   "Alguém está perto!".
// - O objetivo é chegar à porta de saída (casa dourada) e resolver um enigma
//   aritmético. Ao entrar na casa da porta, o jogador fica parado e recebe uma
//   expressão com 3 alternativas. Ele tem 10 segundos para responder.
// - Enquanto um jogador resolve o enigma, a porta fica revelada na tela do
//   adversário, com o aviso "Adversário na porta!", e o adversário continua
//   andando normalmente.
// - Resposta certa: o jogador vence a partida. Resposta errada ou tempo
//   esgotado: o jogador fica bloqueado por 3 segundos. Depois disso ele precisa
//   sair da casa da porta e entrar de novo para receber um novo enigma.
// - Os jogadores podem ocupar a mesma casa.
//
// Controles
//
// - Enter: começa a partida (abertura) ou joga novamente (resultado).
// - Setas: movem o personagem uma casa.
// - 1, 2 ou 3: escolhem a alternativa do enigma.
// - Qualquer outra tecla é ignorada.

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

// Tipos auxiliares para sorteios e enigmas

pub type Sorteio(a) {
  Sorteio(valor: a, gerador: Generator)
}

pub type ParErros {
  ParErros(primeiro: Int, segundo: Int)
}

pub type CasoSorteio {
  CasoSorteio(erros: ParErros, alternativas: List(Int), correta: Int)
}

// Constantes

/// Quantidade de casas em cada lado do labirinto.
const tamanho = 20

/// Lado de uma casa, em pixels.
const lado_casa = 24

/// Quantidade de tiques por segundo.
const tiques_por_segundo = 10

/// Tempo para responder o enigma, em tiques (10 s).
const tempo_enigma = 100

/// Tempo de bloqueio depois de um erro, em tiques (3 s).
const tempo_bloqueio = 30

/// Largura da tela, em pixels.
const largura = 480

/// Altura da tela, em pixels.
const altura = 590

// Labirintos
// # é parede, . é corredor, S e T são os inícios e P é a porta.
// Os dois inícios têm a mesma distância mínima até a porta.

const labirinto_dificil_1 = [
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

const labirinto_dificil_2 = [
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

const labirinto_dificil_3 = [
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

const labirinto_dificil_4 = [
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

const labirinto_dificil_5 = [
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

// Tipos de dados

/// Uma casa do labirinto. *lin* e *col* vão de 0 a `tamanho - 1`; a casa Posicao(0, 0) fica no canto superior
/// esquerdo.
pub type Posicao {
  Posicao(lin: Int, col: Int)
}

/// A direção de um movimento.
pub type Direcao {
  Cima
  Baixo
  Esquerda
  Direita
}

/// Labirinto com as linhas, os inícios S e T e a porta P.
pub type Mapa {
  Mapa(linhas: List(String), inicio: Posicao, inicio_2: Posicao, porta: Posicao)
}

/// O formato de uma expressão aritmética, com os números a, b, c e d.
pub type Formato {
  FormatoA
  FormatoB
  FormatoC
  FormatoD
}

/// Um enigma. *expressao* é o texto da expressão, *alternativas* são as três opções em ordem crescente e
/// *correta* é o número (1, 2 ou 3) da alternativa certa.
pub type Enigma {
  Enigma(expressao: String, alternativas: List(Int), correta: Int)
}

/// O que um jogador está fazendo na partida.
pub type Acao {
  Andando
  ResolvendoEnigma(enigma: Enigma, tiques_restantes: Int)
  Bloqueado(tiques_restantes: Int)
}

/// Um jogador. *numero* é 1 ou 2 e define a cor.
pub type Jogador {
  Jogador(numero: Int, posicao: Posicao, acao: Acao)
}

/// Uma partida em andamento.
pub type Partida {
  Partida(jogadores: List(Jogador), mapa: Mapa)
}

/// O estado do jogo. Todos os estados guardam o gerador de números aleatórios.
pub type Estado {
  Abertura(gerador: Generator)
  EmPartida(gerador: Generator, partida: Partida)
  Resultado(gerador: Generator, vencedor: Int)
}

// Mundo

pub fn smain() {
  mworld.create_from(inicio, min: 2, max: 2, to_image: desenha)
  |> mworld.tick_rate(tiques_por_segundo)
  |> mworld.on_tick(tique)
  |> mworld.on_key_down(tecla)
}

/// Cria o estado inicial com o gerador de *env*.
fn inicio(env: Env, _jogadores: List(mworld.Player)) -> Estado {
  Abertura(env.random(env))
}

/// Desenha o *estado* do ponto de vista de *jogador*.
fn desenha(estado: Estado, jogador: mworld.Player) -> Image {
  tela(estado, mworld.player_index(jogador))
}

/// Trata o *evento* de tecla pressionada por *jogador*.
fn tecla(estado: Estado, jogador: mworld.Player, evento: key.Event) -> Estado {
  trata_tecla(estado, mworld.player_index(jogador), evento)
}

// Utilitários

/// Produz a lista dos números de *inicio* até *fim*, inclusive. Produz a lista vazia se *inicio* é maior que
/// *fim*.
pub fn sequencia(inicio: Int, fim: Int) -> List(Int) {
  case inicio > fim {
    True -> []
    False -> [inicio, ..sequencia(inicio + 1, fim)]
  }
}
pub fn sequencia_examples() {
  check.eq(sequencia(3, 2), [])
  check.eq(sequencia(3, 3), [3])
  check.eq(sequencia(2, 5), [2, 3, 4, 5])
}

/// Produz a lista de todas as casas do labirinto, linha por linha.
pub fn todas_as_casas() -> List(Posicao) {
  let linhas = list.map(sequencia(0, tamanho - 1), fn(lin) {
    list.map(sequencia(0, tamanho - 1), fn(col) { Posicao(lin, col) })
  })
  list.fold(linhas, [], list.append)
}
pub fn todas_as_casas_examples() {
  check.eq(list.length(todas_as_casas()), 400)
  check.eq(list.first(todas_as_casas()), Ok(Posicao(0, 0)))
}

/// Sorteia um elemento de *lista* com *gerador*. Se a lista é vazia, devolve *padrao*. Devolve o elemento e o
/// novo gerador.
pub fn sorteia(gerador: Generator, lista: List(a), padrao: a) -> Sorteio(a) {
  case random.pick(gerador, lista) {
    #(Ok(x), gerador) -> Sorteio(x, gerador)
    #(Error(_), gerador) -> Sorteio(padrao, gerador)
  }
}
pub fn sorteia_examples() {
  let mock = random.mock([random.pick_returns([1, 2, 3], Ok(2))])
  check.eq(sorteia(mock, [1, 2, 3], 0), Sorteio(2, random.mock([])))
  let mock = random.mock([random.pick_returns([], Error(Nil))])
  check.eq(sorteia(mock, [], 7), Sorteio(7, random.mock([])))
}

// Mapas

/// Devolve o símbolo da casa *p* em *linhas*. Casas fora do labirinto são tratadas como parede ("#").
pub fn simbolo_em(linhas: List(String), p: Posicao) -> String {
  case p.lin < 0 || p.lin >= tamanho || p.col < 0 || p.col >= tamanho {
    True -> "#"
    False -> {
      let restantes = list.drop(linhas, p.lin)
      case list.first(restantes) {
        Ok(linha) -> string.slice(linha, p.col, 1)
        Error(_) -> "#"
      }
    }
  }
}

/// Devolve a primeira casa de *linhas* que tem o *simbolo*, em ordem de linha e coluna. O *simbolo* deve ter um
/// caractere e ocorrer em *linhas* dentro dos limites do labirinto.
pub fn acha_simbolo(linhas: List(String), simbolo: String) -> Posicao {
  case list.find(todas_as_casas(), fn(p) { simbolo_em(linhas, p) == simbolo }) {
    Ok(p) -> p
    Error(_) -> Posicao(0, 0)
  }
}

/// Cria um mapa a partir de linhas que contêm S, T e P.
pub fn ler_mapa(linhas: List(String)) -> Mapa {
  Mapa(linhas, acha_simbolo(linhas, "S"), acha_simbolo(linhas, "T"), acha_simbolo(linhas, "P"))
}

/// Mapa pequeno para os exemplos. Ocupa só o canto superior esquerdo.
pub fn mapa_teste() -> Mapa {
  ler_mapa(["#####", "#S.P#", "#T#.#", "#####"])
}
pub fn ler_mapa_examples() {
  check.eq(mapa_teste(), Mapa(["#####", "#S.P#", "#T#.#", "#####"], Posicao(1, 1), Posicao(2, 1), Posicao(1, 3)))
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(1, 2)), ".")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(0, 0)), "#")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(-1, 0)), "#")
  check.eq(simbolo_em(mapa_teste().linhas, Posicao(0, 20)), "#")
}

/// Produz a lista dos cinco labirintos do jogo.
pub fn mapas() -> List(Mapa) {
  list.map(
    [
      labirinto_dificil_1,
      labirinto_dificil_2,
      labirinto_dificil_3,
      labirinto_dificil_4,
      labirinto_dificil_5,
    ],
    ler_mapa,
  )
}
pub fn mapas_examples() {
  check.eq(list.length(mapas()), 5)
  check.eq(
    list.all(mapas(), fn(m) {
      list.length(m.linhas) == 20
      && list.all(m.linhas, fn(l) { string.length(l) == 20 })
    }),
    True,
  )
  check.eq(
    list.all(mapas(), fn(m) {
      m.inicio != m.inicio_2
      && simbolo_em(m.linhas, m.inicio) == "S"
      && simbolo_em(m.linhas, m.inicio_2) == "T"
      && simbolo_em(m.linhas, m.porta) == "P"
    }),
    True,
  )
}

/// Só corredores, o início e a porta permitem passagem. Casas fora do labirinto são paredes.
pub fn caminho_livre(mapa: Mapa, p: Posicao) -> Bool {
  let simbolo = simbolo_em(mapa.linhas, p)
  simbolo == "." || simbolo == "S" || simbolo == "T" || simbolo == "P"
}
pub fn caminho_livre_examples() {
  let m = mapa_teste()
  check.eq(caminho_livre(m, Posicao(1, 1)), True)
  check.eq(caminho_livre(m, Posicao(2, 1)), True)
  check.eq(caminho_livre(m, Posicao(1, 2)), True)
  check.eq(caminho_livre(m, Posicao(1, 3)), True)
  check.eq(caminho_livre(m, Posicao(0, 0)), False)
  check.eq(caminho_livre(m, Posicao(-1, 1)), False)
  check.eq(caminho_livre(m, Posicao(1, 20)), False)
}

// Teclas

/// Trata a *tecla* pressionada pelo jogador *numero*. Só despacha: Enter começa uma partida na abertura e no
/// resultado; na partida, a tecla vai para a função que trata a partida. As outras teclas não mudam o estado.
pub fn trata_tecla(estado: Estado, numero: Int, tecla: key.Event) -> Estado {
  case estado, tecla {
    Abertura(gerador), key.Enter -> inicia_partida(gerador)
    EmPartida(gerador, partida), _ ->
      trata_tecla_partida(gerador, partida, numero, tecla)
    Resultado(gerador, _), key.Enter -> inicia_partida(gerador)
    _, _ -> estado
  }
}
pub fn trata_tecla_examples() {
  let g = random.new(0)
  let p = partida_teste()
  check.eq(trata_tecla(Abertura(g), 1, key.Enter), inicia_partida(g))
  check.eq(trata_tecla(Abertura(g), 2, key.ArrowUp), Abertura(g))
  check.eq(trata_tecla(EmPartida(g, p), 1, key.ArrowRight), EmPartida(g, move(p, 1, Direita)))
  check.eq(trata_tecla(EmPartida(g, p), 2, key.Enter), EmPartida(g, p))
  check.eq(trata_tecla(Resultado(g, 1), 2, key.Enter), inicia_partida(g))
  check.eq(trata_tecla(Resultado(g, 1), 2, key.Char("1")), Resultado(g, 1))
}

/// Devolve a direção correspondente a *tecla*, ou None se *tecla* não é uma seta.
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
  check.eq(direcao(key.Enter), None)
}

/// Devolve o número da alternativa (1, 2 ou 3) correspondente a *tecla*, ou None se *tecla* não é 1, 2 ou 3.
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
  check.eq(alternativa(key.Char("3")), Some(3))
  check.eq(alternativa(key.Char("4")), None)
}

/// Trata a *tecla* do jogador *numero* durante a *partida*. Só despacha de acordo com a ação do jogador:
/// andando, uma seta move; resolvendo o enigma, 1, 2 ou 3 responde; bloqueado, tudo é ignorado.
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
  let g = random.new(0)
  let e = enigma_teste()
  let p = partida_teste()
  let resolvendo = troca_acao(p, 1, ResolvendoEnigma(e, 50))
  let bloqueado = troca_acao(p, 1, Bloqueado(30))
  check.eq(trata_tecla_partida(g, p, 1, key.ArrowRight), EmPartida(g, move(p, 1, Direita)))
  check.eq(trata_tecla_partida(g, p, 1, key.Char("1")), EmPartida(g, p))
  check.eq(trata_tecla_partida(g, resolvendo, 1, key.ArrowRight), EmPartida(g, resolvendo))
  check.eq(trata_tecla_partida(g, resolvendo, 1, key.Char("2")), responde(g, resolvendo, 1, e, 2))
  check.eq(trata_tecla_partida(g, bloqueado, 1, key.ArrowRight), EmPartida(g, bloqueado))
  check.eq(trata_tecla_partida(g, p, 3, key.ArrowRight), EmPartida(g, p))
}

// Partida

/// Sorteia um labirinto e coloca os jogadores em seus respectivos inícios.
pub fn inicia_partida(gerador: Generator) -> Estado {
  let Sorteio(mapa, gerador) = sorteia(gerador, mapas(), ler_mapa(labirinto_dificil_1))
  let jogadores = [
    Jogador(1, mapa.inicio, Andando),
    Jogador(2, mapa.inicio_2, Andando),
  ]
  EmPartida(gerador, Partida(jogadores, mapa))
}
pub fn inicia_partida_examples() {
  let m = ler_mapa(labirinto_dificil_1)
  let mock = random.mock([random.pick_returns(mapas(), Ok(m))])
  check.eq(
    inicia_partida(mock),
    EmPartida(
      random.mock([]),
      Partida(
        [Jogador(1, Posicao(9, 1), Andando), Jogador(2, Posicao(8, 0), Andando)],
        m,
      ),
    ),
  )
}

/// Devolve o jogador de número *numero*, ou Error se não existe.
pub fn acha_jogador(jogadores: List(Jogador), numero: Int) -> Result(Jogador, Nil) {
  list.find(jogadores, fn(j) { j.numero == numero })
}
pub fn acha_jogador_examples() {
  let js = [Jogador(1, Posicao(0, 0), Andando), Jogador(2, Posicao(1, 1), Andando)]
  check.eq(acha_jogador(js, 2), Ok(Jogador(2, Posicao(1, 1), Andando)))
  check.eq(acha_jogador(js, 3), Error(Nil))
}

/// Calcula o destino de um passo de *p* na direção *d*.
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

/// Move o jogador *numero* da *partida* uma casa na direção *d*. O jogador só se move se está andando e se a
/// casa de destino é livre (não é parede nem está fora do labirinto). Os jogadores podem ocupar a mesma casa.
pub fn move(partida: Partida, numero: Int, d: Direcao) -> Partida {
  Partida(
    ..partida,
    jogadores: list.map(partida.jogadores, fn(j) {
      let nova = destino(j.posicao, d)
      case
        j.numero == numero
        && j.acao == Andando
        && caminho_livre(partida.mapa, nova)
      {
        True -> Jogador(..j, posicao: nova)
        False -> j
      }
    }),
  )
}
pub fn move_examples() {
  let p = partida_teste()
  let j1 = Jogador(1, Posicao(1, 1), Andando)
  let j2 = Jogador(2, Posicao(1, 1), Andando)
  check.eq(move(p, 1, Direita), Partida(..p, jogadores: [Jogador(1, Posicao(1, 2), Andando), j2]))
  check.eq(move(p, 2, Baixo), Partida(..p, jogadores: [j1, Jogador(2, Posicao(2, 1), Andando)]))
  check.eq(move(p, 1, Cima), p)
  let canto = Partida(..p, jogadores: [Jogador(1, Posicao(0, 0), Andando)])
  check.eq(move(canto, 1, Esquerda), canto)
  let bloqueado = troca_acao(p, 1, Bloqueado(5))
  check.eq(move(bloqueado, 1, Direita), bloqueado)
  let resolvendo = troca_acao(p, 1, ResolvendoEnigma(enigma_teste(), 5))
  check.eq(move(resolvendo, 1, Direita), resolvendo)
  check.eq(move(p, 3, Direita), p)
  check.eq(
    move(move(p, 1, Direita), 2, Direita).jogadores,
    [Jogador(1, Posicao(1, 2), Andando), Jogador(2, Posicao(1, 2), Andando)],
  )
}

/// Devolve True se o jogador *numero* da *partida* está na casa da porta.
pub fn na_porta(partida: Partida, numero: Int) -> Bool {
  list.any(partida.jogadores, fn(j) {
    j.numero == numero && j.posicao == partida.mapa.porta
  })
}
pub fn na_porta_examples() {
  let p =
    Partida(..partida_teste(), jogadores: [
      Jogador(1, Posicao(1, 3), Andando),
      Jogador(2, Posicao(1, 1), Andando),
    ])
  check.eq(na_porta(p, 1), True)
  check.eq(na_porta(p, 2), False)
  check.eq(na_porta(p, 3), False)
}

/// Move o jogador *numero* uma casa na direção *d*. Se ele acabou de entrar na casa da porta, sorteia um enigma
/// e ele passa a resolvê-lo. Ficar parado na porta não gera um novo enigma: é preciso sair e entrar de novo.
pub fn anda(gerador: Generator, partida: Partida, numero: Int, d: Direcao) -> Estado {
  let nova = move(partida, numero, d)
  case na_porta(nova, numero) && !na_porta(partida, numero) {
    True -> {
      let Sorteio(enigma, gerador) = sorteia_enigma(gerador)
      EmPartida(
        gerador,
        troca_acao(nova, numero, ResolvendoEnigma(enigma, tempo_enigma)),
      )
    }
    False -> EmPartida(gerador, nova)
  }
}
pub fn anda_examples() {
  let g = random.mock([])
  let p = partida_teste()
  let vizinha = move(p, 1, Direita)
  check.eq(anda(g, p, 1, Direita), EmPartida(g, vizinha))
  check.eq(anda(g, p, 1, Cima), EmPartida(g, p))

  let numeros = sequencia(2, 9)
  let sorteios = [
    random.pick_returns([FormatoA, FormatoB, FormatoC, FormatoD], Ok(FormatoB)),
    random.pick_returns(numeros, Ok(7)),
    random.pick_returns(numeros, Ok(3)),
    random.pick_returns(numeros, Ok(4)),
    random.pick_returns(numeros, Ok(5)),
  ]
  let primeiro = list.append(sorteios, [
    random.pick_returns([ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)], Ok(ParErros(-1, 1))),
  ])
  let segundo = list.append(sorteios, [
    random.pick_returns([ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)], Ok(ParErros(1, 2))),
  ])
  let g = random.mock(list.append(primeiro, segundo))
  let restante = random.mock(segundo)
  let outro = Jogador(2, Posicao(1, 1), Andando)
  let na_porta = Partida(..p, jogadores: [
    Jogador(1, Posicao(1, 3), Andando),
    outro,
  ])
  let entrada = anda(g, vizinha, 1, Direita)
  check.eq(entrada, EmPartida(restante, troca_acao(na_porta, 1, ResolvendoEnigma(enigma_teste(), 100))))

  let assert EmPartida(g, partida) = entrada
  let liberado = tique(EmPartida(g, troca_acao(partida, 1, Bloqueado(1))))
  check.eq(liberado, EmPartida(restante, na_porta))
  let assert EmPartida(g, partida) = liberado
  let parado = anda(g, partida, 1, Direita)
  check.eq(parado, EmPartida(restante, na_porta))

  let assert EmPartida(g, partida) = parado
  let saida = anda(g, partida, 1, Esquerda)
  check.eq(saida, EmPartida(restante, vizinha))
  let assert EmPartida(g, partida) = saida
  let novo = Enigma("(7 - 3) + 4 × 5", [24, 25, 26], 1)
  check.eq(anda(g, partida, 1, Direita), EmPartida(random.mock([]), troca_acao(na_porta, 1, ResolvendoEnigma(novo, 100))))
}

/// Troca a ação do jogador *numero* da *partida* por *acao*.
pub fn troca_acao(partida: Partida, numero: Int, acao: Acao) -> Partida {
  Partida(
    ..partida,
    jogadores: list.map(partida.jogadores, fn(j) {
      case j.numero == numero {
        True -> Jogador(..j, acao: acao)
        False -> j
      }
    }),
  )
}
pub fn troca_acao_examples() {
  check.eq(troca_acao(partida_teste(), 2, Bloqueado(30)).jogadores, [
    Jogador(1, Posicao(1, 1), Andando),
    Jogador(2, Posicao(1, 1), Bloqueado(30)),
  ])
  check.eq(troca_acao(partida_teste(), 3, Bloqueado(30)), partida_teste())
}

// Enigmas

/// Calcula o valor da expressão de *formato* com os números *a*, *b*, *c* e *d*. A multiplicação tem
/// precedência sobre a soma e a subtração.
pub fn calcula(formato: Formato, a: Int, b: Int, c: Int, d: Int) -> Int {
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

/// Escreve a expressão de *formato* com os números *a*, *b*, *c* e *d*.
pub fn escreve(formato: Formato, a: Int, b: Int, c: Int, d: Int) -> String {
  let n = int.to_string
  case formato {
    FormatoA -> "(" <> n(a) <> " + " <> n(b) <> ") × " <> n(c) <> " - " <> n(d)
    FormatoB -> "(" <> n(a) <> " - " <> n(b) <> ") + " <> n(c) <> " × " <> n(d)
    FormatoC -> n(a) <> " × " <> n(b) <> " + " <> n(c) <> " - " <> n(d)
    FormatoD ->
      "(" <> n(a) <> " + " <> n(b) <> ") × (" <> n(c) <> " - " <> n(d) <> ")"
  }
}
pub fn escreve_examples() {
  check.eq(escreve(FormatoA, 2, 3, 4, 5), "(2 + 3) × 4 - 5")
  check.eq(escreve(FormatoB, 7, 3, 4, 5), "(7 - 3) + 4 × 5")
  check.eq(escreve(FormatoC, 2, 3, 4, 5), "2 × 3 + 4 - 5")
  check.eq(escreve(FormatoD, 2, 3, 4, 5), "(2 + 3) × (4 - 5)")
}

/// Monta o enigma do *formato* com os números *a*, *b*, *c* e *d*. As alternativas erradas são a resposta certa
/// mais as diferenças de *erros*. As diferenças devem ser distintas, diferentes de zero e estar entre -2 e 2,
/// inclusive. As três alternativas ficam em ordem crescente.
pub fn monta_enigma(formato: Formato, a: Int, b: Int, c: Int, d: Int, erros: ParErros) -> Enigma {
  let certa = calcula(formato, a, b, c, d)
  let alternativas =
    list.sort([certa, certa + erros.primeiro, certa + erros.segundo], int.compare)
  let correta = list.length(list.filter(alternativas, fn(x) { x < certa })) + 1
  Enigma(escreve(formato, a, b, c, d), alternativas, correta)
}
pub fn monta_enigma_examples() {
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(-1, 1)), Enigma("(7 - 3) + 4 × 5", [23, 24, 25], 2))
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(-2, -1)), Enigma("(7 - 3) + 4 × 5", [22, 23, 24], 3))
  check.eq(monta_enigma(FormatoB, 7, 3, 4, 5, ParErros(1, 2)), Enigma("(7 - 3) + 4 × 5", [24, 25, 26], 1))
  check.eq(monta_enigma(FormatoD, 2, 3, 4, 5, ParErros(-2, 1)), Enigma("(2 + 3) × (4 - 5)", [-7, -5, -4], 2))
}

/// Sorteia um enigma: o formato, os quatro números (de 2 a 9) e o par de diferenças. Cada par coloca a resposta
/// certa em uma posição diferente, com a mesma probabilidade. Devolve o enigma e o novo gerador.
pub fn sorteia_enigma(gerador: Generator) -> Sorteio(Enigma) {
  let formatos = [FormatoA, FormatoB, FormatoC, FormatoD]
  let pares = [ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)]
  let Sorteio(formato, gerador) = sorteia(gerador, formatos, FormatoA)
  let Sorteio(a, gerador) = sorteia(gerador, sequencia(2, 9), 2)
  let Sorteio(b, gerador) = sorteia(gerador, sequencia(2, 9), 2)
  let Sorteio(c, gerador) = sorteia(gerador, sequencia(2, 9), 2)
  let Sorteio(d, gerador) = sorteia(gerador, sequencia(2, 9), 2)
  let Sorteio(erros, gerador) = sorteia(gerador, pares, ParErros(-1, 1))
  Sorteio(monta_enigma(formato, a, b, c, d, erros), gerador)
}
pub fn sorteia_enigma_examples() {
  let numeros = sequencia(2, 9)
  let pares = [ParErros(-1, 1), ParErros(-2, -1), ParErros(1, 2)]
  let casos = [
    CasoSorteio(ParErros(-1, 1), [-6, -5, -4], 2),
    CasoSorteio(ParErros(-2, -1), [-7, -6, -5], 3),
    CasoSorteio(ParErros(1, 2), [-5, -4, -3], 1),
  ]
  testa_sorteios(casos, numeros, pares)
}

fn testa_sorteios(casos: List(CasoSorteio), numeros: List(Int), pares: List(ParErros)) -> Nil {
  case casos {
    [] -> Nil
    [caso, ..resto] -> {
      let CasoSorteio(erros, alternativas, correta) = caso
      let g = random.mock([
        random.pick_returns([FormatoA, FormatoB, FormatoC, FormatoD], Ok(FormatoD)),
        random.pick_returns(numeros, Ok(2)),
        random.pick_returns(numeros, Ok(3)),
        random.pick_returns(numeros, Ok(4)),
        random.pick_returns(numeros, Ok(5)),
        random.pick_returns(pares, Ok(erros)),
      ])
      check.eq(sorteia_enigma(g), Sorteio(Enigma("(2 + 3) × (4 - 5)", alternativas, correta), random.mock([])))
      testa_sorteios(resto, numeros, pares)
    }
  }
}

/// Enigma para os exemplos: (7 - 3) + 4 × 5 = 24, a certa é a alternativa 2.
pub fn enigma_teste() -> Enigma {
  Enigma("(7 - 3) + 4 × 5", [23, 24, 25], 2)
}

/// O jogador *numero* escolheu a alternativa *escolha* do *enigma*. Se acertou, a partida termina e ele vence.
/// Se errou, fica bloqueado.
pub fn responde(gerador: Generator, partida: Partida, numero: Int, enigma: Enigma, escolha: Int) -> Estado {
  case escolha == enigma.correta {
    True -> Resultado(gerador, numero)
    False ->
      EmPartida(gerador, troca_acao(partida, numero, Bloqueado(tempo_bloqueio)))
  }
}
pub fn responde_examples() {
  let g = random.new(0)
  let e = enigma_teste()
  let p = troca_acao(partida_teste(), 2, ResolvendoEnigma(e, 50))
  check.eq(responde(g, p, 2, e, 2), Resultado(g, 2))
  check.eq(responde(g, p, 2, e, 3), EmPartida(g, troca_acao(p, 2, Bloqueado(30))))
}

// Tiques

/// Avança o *estado* em um tique. Só a partida muda com o tempo: o contador de cada jogador avança de forma
/// independente.
pub fn tique(estado: Estado) -> Estado {
  case estado {
    EmPartida(gerador, partida) -> EmPartida(gerador, avanca_partida(partida))
    _ -> estado
  }
}
pub fn tique_examples() {
  let g = random.new(0)
  let p =
    partida_teste()
    |> troca_acao(1, ResolvendoEnigma(enigma_teste(), 50))
    |> troca_acao(2, Bloqueado(30))
  check.eq(tique(Abertura(g)), Abertura(g))
  check.eq(tique(Resultado(g, 1)), Resultado(g, 1))
  check.eq(
    tique(EmPartida(g, p)),
    EmPartida(
      g,
      Partida(..p, jogadores: [
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
  let p = partida_teste()
  let bloqueado = troca_acao(p, 2, Bloqueado(2))
  check.eq(avanca_partida(p), p)
  check.eq(avanca_partida(bloqueado), troca_acao(p, 2, Bloqueado(1)))
}

/// Avança em um tique o contador do *jogador*. Quando o tempo do enigma acaba, o jogador é bloqueado. Quando o
/// bloqueio acaba, o jogador volta a andar.
pub fn tique_jogador(jogador: Jogador) -> Jogador {
  case jogador.acao {
    Andando -> jogador
    ResolvendoEnigma(enigma, tiques) ->
      case tiques <= 1 {
        True -> Jogador(..jogador, acao: Bloqueado(tempo_bloqueio))
        False -> Jogador(..jogador, acao: ResolvendoEnigma(enigma, tiques - 1))
      }
    Bloqueado(tiques) ->
      case tiques <= 1 {
        True -> Jogador(..jogador, acao: Andando)
        False -> Jogador(..jogador, acao: Bloqueado(tiques - 1))
      }
  }
}
pub fn tique_jogador_examples() {
  let p = Posicao(1, 1)
  let e = enigma_teste()
  check.eq(tique_jogador(Jogador(1, p, Andando)), Jogador(1, p, Andando))
  check.eq(tique_jogador(Jogador(1, p, ResolvendoEnigma(e, 100))), Jogador(1, p, ResolvendoEnigma(e, 99)))
  check.eq(tique_jogador(Jogador(1, p, ResolvendoEnigma(e, 1))), Jogador(1, p, Bloqueado(30)))
  check.eq(tique_jogador(Jogador(1, p, Bloqueado(30))), Jogador(1, p, Bloqueado(29)))
  check.eq(tique_jogador(Jogador(1, p, Bloqueado(1))), Jogador(1, p, Andando))
}

// Visibilidade

/// Uma posição está no campo de visão quando difere no máximo uma casa em cada eixo. Isso inclui a própria casa
/// e as oito vizinhas.
pub fn visivel(p: Posicao, centro: Posicao) -> Bool {
  int.absolute_value(p.lin - centro.lin) <= 1
  && int.absolute_value(p.col - centro.col) <= 1
}
pub fn visivel_examples() {
  check.eq(visivel(Posicao(8, 8), Posicao(9, 9)), True)
  check.eq(visivel(Posicao(9, 9), Posicao(9, 9)), True)
  check.eq(visivel(Posicao(11, 9), Posicao(9, 9)), False)
  check.eq(visivel(Posicao(9, 7), Posicao(9, 9)), False)
  check.eq(visivel(Posicao(0, 1), Posicao(0, 0)), True)
  check.eq(visivel(Posicao(19, 19), Posicao(17, 19)), False)
}

/// Devolve a distância entre *a* e *b*: a maior diferença entre as linhas ou entre as colunas. As paredes são
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

/// Devolve True se algum adversário de *eu* está fora do campo de visão, mas a 2, 3 ou 4 casas de distância.
pub fn adversario_perto(jogadores: List(Jogador), eu: Jogador) -> Bool {
  list.any(jogadores, fn(j) {
    let d = distancia(j.posicao, eu.posicao)
    j.numero != eu.numero && d >= 2 && d <= 4
  })
}
pub fn adversario_perto_examples() {
  let eu = Jogador(1, Posicao(9, 9), Andando)
  let com = fn(p) { [eu, Jogador(2, p, Andando)] }
  check.eq(adversario_perto(com(Posicao(10, 10)), eu), False)
  check.eq(adversario_perto(com(Posicao(9, 11)), eu), True)
  check.eq(adversario_perto(com(Posicao(13, 5)), eu), True)
  check.eq(adversario_perto(com(Posicao(9, 14)), eu), False)
  check.eq(adversario_perto([eu], eu), False)
}

/// Devolve True se *acao* é ResolvendoEnigma.
pub fn resolvendo(acao: Acao) -> Bool {
  case acao {
    ResolvendoEnigma(_, _) -> True
    _ -> False
  }
}

/// Devolve True se algum adversário do jogador *numero* está resolvendo um enigma.
pub fn adversario_na_porta(jogadores: List(Jogador), numero: Int) -> Bool {
  list.any(jogadores, fn(j) { j.numero != numero && resolvendo(j.acao) })
}
pub fn adversario_na_porta_examples() {
  let p = Posicao(1, 1)
  let js = [
    Jogador(1, p, ResolvendoEnigma(enigma_teste(), 5)),
    Jogador(2, p, Andando),
  ]
  check.eq(resolvendo(Andando), False)
  check.eq(resolvendo(Bloqueado(3)), False)
  check.eq(adversario_na_porta(js, 2), True)
  check.eq(adversario_na_porta(js, 1), False)
}

/// Devolve True se a porta da *partida* aparece na tela do jogador *eu*: ela está no campo de visão ou um
/// adversário está resolvendo o enigma.
pub fn porta_visivel(partida: Partida, eu: Jogador) -> Bool {
  visivel(partida.mapa.porta, eu.posicao)
  || adversario_na_porta(partida.jogadores, eu.numero)
}
pub fn porta_visivel_examples() {
  let p = partida_teste()
  let longe = Jogador(1, Posicao(9, 9), Andando)
  let perto = Jogador(1, Posicao(1, 2), Andando)
  let parado = Jogador(2, Posicao(1, 1), Andando)
  let na_porta = Jogador(2, Posicao(1, 3), ResolvendoEnigma(enigma_teste(), 9))
  check.eq(porta_visivel(Partida(..p, jogadores: [longe, parado]), longe), False)
  check.eq(porta_visivel(Partida(..p, jogadores: [perto, parado]), perto), True)
  check.eq(porta_visivel(Partida(..p, jogadores: [longe, na_porta]), longe), True)
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

// Desenho

/// Devolve a quantidade de segundos que faltam para *tiques* tiques passarem, arredondada para cima.
pub fn segundos_restantes(tiques: Int) -> Int {
  { tiques + tiques_por_segundo - 1 } / tiques_por_segundo
}
pub fn segundos_restantes_examples() {
  check.eq(segundos_restantes(0), 0)
  check.eq(segundos_restantes(1), 1)
  check.eq(segundos_restantes(90), 9)
  check.eq(segundos_restantes(91), 10)
}

/// Devolve a cor do jogador *numero*.
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

/// Produz uma imagem com o texto *s* em preto, com tamanho *tamanho_fonte*.
pub fn texto(s: String, tamanho_fonte: Int) -> Image {
  image.text(s, tamanho_fonte, fill.black)
}
pub fn texto_examples() {
  check.same(texto("Porta", 18), image.text("Porta", 18, fill.black))
}

/// Empilha as *imagens*, a primeira no topo.
pub fn empilha(imagens: List(Image)) -> Image {
  list.fold(imagens, image.empty, image.above)
}
pub fn empilha_examples() {
  let topo = image.square(14, fill.blue)
  let base = image.circle(5, fill.gold)
  check.same(empilha([]), image.empty)
  check.same(empilha([topo, base]), image.above(topo, base))
}

/// Coloca a *imagem* centralizada na casa *p* da *cena*.
pub fn coloca(cena: Image, p: Posicao, imagem: Image) -> Image {
  image.place_image(
    cena,
    p.col * lado_casa + lado_casa / 2,
    p.lin * lado_casa + lado_casa / 2,
    imagem,
  )
}
pub fn coloca_examples() {
  let cena = image.empty_scene(480, 480)
  let bola = image.circle(10, fill.gold)
  check.same(coloca(cena, Posicao(0, 0), bola), image.place_image(cena, 12, 12, bola))
  check.same(coloca(cena, Posicao(2, 5), bola), image.place_image(cena, 132, 60, bola))
}

/// Desenha o chão ou a parede da casa *p* do *mapa*.
pub fn desenha_casa(mapa: Mapa, p: Posicao) -> Image {
  case simbolo_em(mapa.linhas, p) {
    "#" -> image.square(lado_casa - 1, fill.slategray)
    _ -> image.square(lado_casa - 1, fill.lightyellow)
  }
}

/// Desenha a porta de saída.
pub fn desenha_porta() -> Image {
  image.square(lado_casa - 1, fill.gold)
}
pub fn desenha_casa_examples() {
  let m = mapa_teste()
  check.same(desenha_casa(m, Posicao(0, 0)), image.square(23, fill.slategray))
  check.same(desenha_casa(m, Posicao(1, 2)), image.square(23, fill.lightyellow))
  check.same(desenha_porta(), image.square(23, fill.gold))
}

/// Desenha o personagem do jogador *numero*, com uma borda grossa se *destaque* é True.
pub fn personagem(numero: Int, destaque: Bool) -> Image {
  let borda = case destaque {
    True -> [style.stroke(color.black), style.stroke_width(3)]
    False -> []
  }
  image.square(lado_casa / 2 - 2, style.join([style.fill(cor(numero)), ..borda]))
}
pub fn personagem_examples() {
  check.same(personagem(2, False), image.square(10, style.fill(color.blue)))
  check.same(
    personagem(1, True),
    image.square(
      10,
      style.join([
        style.fill(color.red),
        style.stroke(color.black),
        style.stroke_width(3),
      ]),
    ),
  )
}

/// Coloca na *cena* o personagem do *jogador*, destacado se for o jogador *eu*. O personagem é deslocado para o
/// lado (o jogador 1 para a esquerda e o jogador 2 para a direita) para que os dois sejam vistos na mesma casa.
pub fn coloca_jogador(cena: Image, jogador: Jogador, eu: Int) -> Image {
  let dx = case jogador.numero {
    1 -> -6
    _ -> 6
  }
  image.place_image(
    cena,
    jogador.posicao.col * lado_casa + lado_casa / 2 + dx,
    jogador.posicao.lin * lado_casa + lado_casa / 2,
    personagem(jogador.numero, jogador.numero == eu),
  )
}
pub fn coloca_jogador_examples() {
  let cena = image.empty_scene(480, 480)
  let j = Jogador(2, Posicao(1, 2), Andando)
  check.same(coloca_jogador(cena, j, 1), image.place_image(cena, 66, 36, image.square(10, style.fill(color.blue))))
}

/// Desenha o labirinto para o jogador *eu*: tudo escuro, exceto o quadrado 3x3 ao redor dele. Mostra a porta
/// quando ela está visível e o adversário quando ele está no campo de visão.
pub fn desenha_mapa(partida: Partida, eu: Jogador) -> Image {
  let fundo = image.rectangle(tamanho * lado_casa, tamanho * lado_casa, fill.black)
  let visiveis = list.filter(todas_as_casas(), fn(p) { visivel(p, eu.posicao) })
  let com_casas =
    list.fold(visiveis, fundo, fn(cena, p) {
      coloca(cena, p, desenha_casa(partida.mapa, p))
    })
  let com_porta = case porta_visivel(partida, eu) {
    True -> coloca(com_casas, partida.mapa.porta, desenha_porta())
    False -> com_casas
  }
  list.fold(partida.jogadores, com_porta, fn(cena, j) {
    case j.numero == eu.numero || visivel(j.posicao, eu.posicao) {
      True -> coloca_jogador(cena, j, eu.numero)
      False -> cena
    }
  })
}

/// Produz o aviso de porta para o jogador *numero*.
pub fn aviso_porta(jogadores: List(Jogador), numero: Int) -> String {
  case adversario_na_porta(jogadores, numero) {
    True -> "Adversário na porta!"
    False -> " "
  }
}

/// Produz o aviso de proximidade para o jogador *eu*.
pub fn aviso_perto(jogadores: List(Jogador), eu: Jogador) -> String {
  case adversario_perto(jogadores, eu) {
    True -> "Alguém está perto!"
    False -> " "
  }
}
pub fn avisos_examples() {
  let eu = Jogador(1, Posicao(9, 9), Andando)
  let na_porta = Jogador(2, Posicao(1, 3), ResolvendoEnigma(enigma_teste(), 9))
  let perto = Jogador(2, Posicao(9, 11), Andando)
  check.eq(aviso_porta([eu, na_porta], 1), "Adversário na porta!")
  check.eq(aviso_porta([eu, perto], 1), " ")
  check.eq(aviso_perto([eu, perto], eu), "Alguém está perto!")
  check.eq(aviso_perto([eu, na_porta], eu), " ")
}

/// Desenha a tela de abertura para o jogador *numero*.
pub fn tela_abertura(numero: Int) -> Image {
  empilha([
    texto("Corrida no Labirinto Escuro", 28),
    texto("Os jogadores começam em casas diferentes.", 16),
    texto("Cada um vê só as casas ao redor de si.", 16),
    texto("Ache a porta e resolva a expressão antes do outro.", 16),
    texto("Setas: andar    1, 2 ou 3: responder o enigma", 16),
    image.beside(
      texto("Você é o jogador " <> int.to_string(numero) <> "  ", 20),
      image.square(lado_casa / 2, style.fill(cor(numero))),
    ),
    texto("Pressione Enter para começar", 22),
  ])
}

/// Desenha a tela da *partida* para o jogador *numero*, de acordo com a ação dele.
pub fn tela_partida(partida: Partida, numero: Int) -> Image {
  case acha_jogador(partida.jogadores, numero) {
    Error(_) -> texto("Jogador não encontrado", 20)
    Ok(eu) ->
      case eu.acao {
        Andando -> tela_labirinto(partida, eu)
        ResolvendoEnigma(enigma, tiques) -> tela_enigma(enigma, tiques)
        Bloqueado(tiques) -> tela_bloqueio(tiques)
      }
  }
}

/// Desenha o labirinto, com os avisos no topo, para o jogador *eu*.
pub fn tela_labirinto(partida: Partida, eu: Jogador) -> Image {
  image.above(
    empilha([
      image.text(
        "Você é o jogador " <> int.to_string(eu.numero),
        16,
        style.fill(cor(eu.numero)),
      ),
      texto(aviso_porta(partida.jogadores, eu.numero), 14),
      texto(aviso_perto(partida.jogadores, eu), 14),
    ]),
    desenha_mapa(partida, eu),
  )
}

/// Desenha a tela do enigma: a expressão, as três alternativas e o tempo restante.
pub fn tela_enigma(enigma: Enigma, tiques: Int) -> Image {
  let alternativas =
    list.index_map(enigma.alternativas, fn(a, i) {
      texto(int.to_string(i + 1) <> ") " <> int.to_string(a), 28)
    })
  let inicio = [texto("Resolva a expressão:", 22), texto(enigma.expressao <> " = ?", 32)]
  let fim = [texto("Tempo: " <> int.to_string(segundos_restantes(tiques)) <> " s", 22), texto("Pressione 1, 2 ou 3", 18)]
  empilha(list.append(inicio, list.append(alternativas, fim)))
}

/// Desenha a tela de bloqueio, com o tempo restante.
pub fn tela_bloqueio(tiques: Int) -> Image {
  empilha([
    texto("Resposta errada ou tempo esgotado!", 26),
    texto("Aguarde " <> int.to_string(segundos_restantes(tiques)) <> " s", 24),
    texto("Depois saia da porta e entre de novo.", 16),
  ])
}

/// Desenha a tela de resultado para o jogador *numero*.
pub fn tela_resultado(vencedor: Int, numero: Int) -> Image {
  empilha([
    texto(mensagem_resultado(vencedor, numero), 32),
    texto("Pressione Enter para jogar novamente", 20),
  ])
}

/// Desenha a tela do *estado* para o jogador *numero*.
pub fn tela(estado: Estado, numero: Int) -> Image {
  let conteudo = case estado {
    Abertura(_) -> tela_abertura(numero)
    EmPartida(_, partida) -> tela_partida(partida, numero)
    Resultado(_, vencedor) -> tela_resultado(vencedor, numero)
  }
  image.overlay(conteudo, image.rectangle(largura, altura, fill.white))
}

// Dados para os exemplos

/// Partida para os exemplos: mapa pequeno, os dois jogadores no início.
pub fn partida_teste() -> Partida {
  Partida(
    [Jogador(1, Posicao(1, 1), Andando), Jogador(2, Posicao(1, 1), Andando)],
    mapa_teste(),
  )
}
