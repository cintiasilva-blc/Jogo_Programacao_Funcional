// Cíntia da Silva Bulcão - RA 145107.
// Giovana da Silva Bulcão - RA 144325.
//

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import sgleam/check
import sgleam/env.{type Env}
import sgleam/fill
import sgleam/image.{type Image}
import sgleam/key
import sgleam/mworld

// quantidade de casas em cada lado da grade.
const tamanho = 20

/// lado de uma casa, em pixels.
const lado_casa = 24

//Largura da tela em pixels
const largura = 480

// altura da tela em pixels
const altura = 590

// cada string é uma linha do mapa # é parede; . é caminho; S é o início.
// As posições começam em zero: o S está na linha 9, coluna 9.
const labirinto = [
  "####################",
  "#.......#..........#",
  "#.###.#.#.#######..#",
  "#...#.#...#.....####",
  "###.#.#####.###.#..#",
  "#...#.......#...#..#",
  "#.###########.###..#",
  "#...........#......#",
  "#.#######.#.#####..#",
  "#.......#S......#..#",
  "#######.#######.#..#",
  "#.....#.......#....#",
  "#.###.#######.###..#",
  "#...#.......#......#",
  "###.#######.#####..#",
  "#...#.....#.....#..#",
  "#.###.###.#####.#..#",
  "#...#......#..#....#",
  "#......##.....#....#",
  "####################",
]

/// 
pub type Posicao {
  Posicao(lin: Int, col: Int)
}

/// numero identifica qual jogador é e define a cor
pub type Jogador {
  Jogador(numero: Int, posicao: Posicao)
}

/// Todos compartilham este estado, a lista guarda as posições dos dois jogadores
pub type Estado {
  Estado(jogadores: List(Jogador))
}

// direção de um movimento
pub type Direcao {
  Cima
  Baixo
  Esquerda
  Direita
}

// ----------------------------------------------------------------------
// Mundo
// ----------------------------------------------------------------------

pub fn smain() {
  mworld.create_from(inicio, min: 2, max: 2, to_image: desenha)
  |> mworld.on_key_down(tecla)
}

/// vria os personagens dos participantes, todos no ponto inicial (9, 9).
/// map transforma cada participante em um Jogador, produzindo uma nova lista.
pub fn inicio(_env: Env, participantes: List(mworld.Player)) -> Estado {
  Estado(
    list.map(participantes, fn(p) {
      Jogador(mworld.player_index(p), Posicao(9, 9))
    }),
  )
}

/// O mworld informa qual jogador pressionou a tecla.
fn tecla(estado: Estado, jogador: mworld.Player, evento: key.Event) -> Estado {
  trata_tecla(estado, mworld.player_index(jogador), evento)
}

/// As setas movem; qualquer outra tecla mantém o estado atual.
pub fn trata_tecla(estado: Estado, numero: Int, evento: key.Event) -> Estado {
  case direcao(evento) {
    Some(d) -> move(estado, numero, d)
    None -> estado
  }
}

/// Option representa a presença ou ausência de uma direção para a tecla.
pub fn direcao(evento: key.Event) -> Option(Direcao) {
  case evento {
    key.ArrowUp -> Some(Cima)
    key.ArrowDown -> Some(Baixo)
    key.ArrowLeft -> Some(Esquerda)
    key.ArrowRight -> Some(Direita)
    _ -> None
  }
}

/// Calcula o destino de um passo
pub fn destino(p: Posicao, d: Direcao) -> Posicao {
  case d {
    Cima -> Posicao(p.lin - 1, p.col)
    Baixo -> Posicao(p.lin + 1, p.col)
    Esquerda -> Posicao(p.lin, p.col - 1)
    Direita -> Posicao(p.lin, p.col + 1)
  }
}

/// Só caminhos e o ponto inicial permitem passagem.
/// Consultas fora do mapa são tratadas como parede, sem encerrar o programa.
pub fn caminho_livre(p: Posicao) -> Bool {
  case p.lin < 0 || p.lin >= tamanho || p.col < 0 || p.col >= tamanho {
    True -> False
    False ->
      case labirinto |> list.drop(p.lin) |> list.first {
        Ok(linha) -> {
          let simbolo = string.slice(linha, p.col, 1)
          simbolo == "." || simbolo == "S"
        }
        Error(_) -> False
      }
  }
}

/// Produz um novo estado: apenas o jogador indicado pode mudar de posição.
/// Se o destino é parede, preserva o jogador. Não há bloqueio entre personagens.
pub fn move(estado: Estado, numero: Int, d: Direcao) -> Estado {
  Estado(
    list.map(estado.jogadores, fn(j) {
      let nova_posicao = destino(j.posicao, d)
      case j.numero == numero && caminho_livre(nova_posicao) {
        True -> Jogador(..j, posicao: nova_posicao)
        False -> j
      }
    }),
  )
}

// a mesma lista de jogadores produz uma imagem para cada participante.

fn desenha(estado: Estado, jogador: mworld.Player) -> Image {
  tela(estado, mworld.player_index(jogador))
}

/// Cria uma sequência inclusiva por recursão
pub fn sequencia(inicio: Int, fim: Int) -> List(Int) {
  case inicio > fim {
    True -> []
    False -> [inicio, ..sequencia(inicio + 1, fim)]
  }
}

/// Uma posição está no campo de visão quando difere no máximo uma casa
/// em cada eixo. Isso inclui a própria casa e as oito vizinhas.
pub fn visivel(p: Posicao, centro: Posicao) -> Bool {
  int.absolute_value(p.lin - centro.lin) <= 1
  && int.absolute_value(p.col - centro.col) <= 1
}

/// Desenha o chão ou a parede de uma única casa.
pub fn desenha_casa(p: Posicao) -> Image {
  case caminho_livre(p) {
    True -> image.square(lado_casa - 1, fill.lightyellow)
    False -> image.square(lado_casa - 1, fill.slategray)
  }
}

/// As cores são fixas: jogador 1 azul e jogador 2 laranja.
pub fn desenha_jogador(numero: Int) -> Image {
  case numero {
    1 -> image.circle(5, fill.dodgerblue)
    _ -> image.circle(5, fill.red)
  }
}

pub fn desenha_mapa(estado: Estado, _eu: Jogador) -> Image {
  // Cria todas as posições do mapa
  let casas =
    sequencia(0, tamanho - 1)
    |> list.map(fn(lin) {
      list.map(sequencia(0, tamanho - 1), fn(col) { Posicao(lin, col) })
    })
    |> list.flatten

  let fundo = image.square(tamanho * lado_casa, fill.white)

  // Desenha todas as casas caminhos e paredes.
  let mapa =
    list.fold(casas, fundo, fn(cena, p) {
      image.place_image(
        cena,
        p.col * lado_casa + 12,
        p.lin * lado_casa + 12,
        desenha_casa(p),
      )
    })

  // Desenha todos os jogadores, independentemente da distância.
  list.fold(estado.jogadores, mapa, fn(cena, j) {
    // Permite identificar ambos quando ocupam a mesma casa.
    let deslocamento = case j.numero {
      1 -> -5
      _ -> 5
    }

    image.place_image(
      cena,
      j.posicao.col * lado_casa + 12 + deslocamento,
      j.posicao.lin * lado_casa + 12,
      desenha_jogador(j.numero),
    )
  })
}

/// O número determina o centro da visão, por isso cada pessoa vê sua tela.
pub fn tela(estado: Estado, numero: Int) -> Image {
  let fundo = image.rectangle(largura, altura, fill.white)
  case list.find(estado.jogadores, fn(j) { j.numero == numero }) {
    Error(_) ->
      image.place_image(
        fundo,
        240,
        295,
        image.text("Jogador não encontrado", 18, fill.black),
      )
    Ok(eu) ->
      fundo
      |> image.place_image(
        240,
        25,
        image.text(
          "Labirinto - jogador " <> int.to_string(numero),
          22,
          fill.black,
        ),
      )
      |> image.place_image(240, 300, desenha_mapa(estado, eu))
      |> image.place_image(
        240,
        558,
        image.text("Setas: mover | Azul: J1 | Vermelho: J2", 16, fill.black),
      )
  }
}

pub fn direcao_examples() {
  check.eq(direcao(key.ArrowUp), Some(Cima))
  check.eq(direcao(key.ArrowDown), Some(Baixo))
  check.eq(direcao(key.ArrowLeft), Some(Esquerda))
  check.eq(direcao(key.ArrowRight), Some(Direita))
  check.eq(direcao(key.Enter), None)
}

pub fn movimento_examples() {
  let j1 = Jogador(1, Posicao(9, 9))
  let j2 = Jogador(2, Posicao(9, 9))
  let estado = Estado([j1, j2])
  check.eq(move(estado, 1, Direita), Estado([Jogador(1, Posicao(9, 10)), j2]))
  check.eq(move(estado, 1, Esquerda), estado)
  check.eq(move(estado, 99, Direita), estado)
  check.eq(trata_tecla(estado, 1, key.Enter), estado)
  check.eq(
    trata_tecla(estado, 2, key.ArrowRight),
    Estado([j1, Jogador(2, Posicao(9, 10))]),
  )
  check.eq(move(Estado([]), 1, Direita), Estado([]))
  check.eq(caminho_livre(Posicao(9, 9)), True)
  check.eq(caminho_livre(Posicao(0, 0)), False)
  check.eq(caminho_livre(Posicao(-1, 0)), False)
  check.eq(caminho_livre(Posicao(0, 20)), False)
}

pub fn visibilidade_examples() {
  check.eq(visivel(Posicao(8, 8), Posicao(9, 9)), True)
  check.eq(visivel(Posicao(9, 9), Posicao(9, 9)), True)
  check.eq(visivel(Posicao(11, 9), Posicao(9, 9)), False)
  check.eq(sequencia(2, 1), [])
  check.eq(sequencia(1, 3), [1, 2, 3])
  check.same(desenha_jogador(1), image.circle(5, fill.dodgerblue))
  check.same(desenha_casa(Posicao(0, 0)), image.square(23, fill.slategray))
}
