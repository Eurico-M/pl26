#set page(
  paper: "a4",
)

#set document(
  title: "Language Server Protocol para YAP",
)

#set text(
  size: 12pt,
)

#set par(
  leading: 1em,
)

#show heading: it => {
  it + v(0.4em)
}

// Texto das legendas das figuras em português
#show figure.caption: emph
#show figure.where(kind: image): set figure(supplement: [Figura])
#show figure.where(kind: table): set figure(supplement: [Tabela])

// Acrescentar números de linha nos blocos de código
#import "@preview/zebraw:0.6.1": *
#show: zebraw

// INÍCIO DO DOCUMENTO //

#figure(
  image("images/fcup-identidade-logotipo-cores.png", width: 50%)
)

#align(center + horizon)[
  #title() \ \ \ \
  #text(size: 14pt)[
    Programação em Lógica \
    CC3012 \ \
    2026
  ]
]

#align(center + bottom)[
  Docente: Vitor Costa \ \
  André Mendes up202307449 \
  Eurico Magalhães up200701520
]

#pagebreak()

#outline(
  title: [Conteúdos]
)
#pagebreak()

#set page(
  numbering: "1/1",
)

= Motivação

Um dos possíveis trabalhos apresentados pelo professor foi o desenvolver uma solução para o seguinte problema: os utilizadores de editores de texto e IDE's esperam que estes programas possuam certas funcionalidades, como coloração de texto consoante a sintaxe da linguagem de programação, verificação e validação dessa sintaxe, procura de símbolos e definições, entre outras.

O compilador de Prolog YAP ainda não tem uma integração com possíveis soluções para este problema. Assim, este trabalho pretende investigar e implementar uma solução, usando o Language Server Protocol.

= Language Server Protocol

O Language Server Protocol
#footnote[https://microsoft.github.io/language-server-protocol/]<lsp>
(LSP) é um protocolo de comunicação entre editores de texto e IDE's, e um servidor de uma linguagem de programação, que providencia ao editor as regras e instruções necessárias à implementação de funcionalidades de formatação e uso dessa linguagem no contexto do editor ou IDE.

Desenvolvido pela Microsoft, e _open source_, é um protocolo usado no Visual Studio Code
#footnote[https://code.visualstudio.com/api/language-extensions/language-server-extension-guide]<vscode>
(VSCode) e, como este editor é bastante usado, atualmente, pelos alunos de Ciência de Computadores, o professor decidiu trabalhar neste contexto.

A motivação por trás do LSP, como explica a Microsoft, é a seguinte: em vez de cada editor de texto ter que implementar todas as linguagens de programação que pretende suportar, porque não ter um protocolo de comunicação que, quando implementado uma vez em cada editor, permite reconhecer todas as linguagens que implementem, por sua vez, esse protocolo.

#figure(
  image("images/lsp-languages-editors.png", width: 70%),
  caption: [Motivação do LSP (fonte: site da API do VSCode#footnote(<vscode>))],
)

Este protocolo implementa mensagens codificadas em JSON RPC
#footnote[https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/]
que são trocadas entre cliente e servidor.

#figure(
  image("images/lsp-illustration.png", width: 80%),
  caption: [Funcionamento do LSP (fonte: site da API do VSCode#footnote(<vscode>))],
)

Como este protocolo se tornou popular, foram desenvolvidas várias ferramentas que permitem mais facilmente implementar um cliente/servidor LSP, evitando assim termos que, por exemplo, implementar todas as mensagens JSON.

Uma destas ferramentas é o pygls
#footnote[https://pygls.readthedocs.io/en/latest/]<pygls>.

= pygls

O pygls é uma "implementação genérica do LSP escrita em Python"
#footnote(<pygls>).
Usando o pygls deve ser posssível escrever um servidor LSP em Python, de uma maneira relativamente simples.

Por exemplo, o código seguinte recebe um documento e, em cada linha que acabe em "hello.", retorna ao editor de texto a hipótese de autocompletar com "world" ou "friend" (linhas 18-20).

Esta sugestão de autocompletar só acontece quando o utilizador insere um " . " (linha 9).

#pagebreak()

```python
from pygls.lsp.server import LanguageServer
from lsprotocol import types

server = LanguageServer("example-server", "v0.1")


@server.feature(
    types.TEXT_DOCUMENT_COMPLETION,
    types.CompletionOptions(trigger_characters=["."]),
)
def completions(params: types.CompletionParams):
    document = server.workspace.get_text_document(params.text_document.uri)
    current_line = document.lines[params.position.line].strip()

    if not current_line.endswith("hello."):
        return []

    return [
        types.CompletionItem(label="world"),
        types.CompletionItem(label="friend"),
    ]


if __name__ == "__main__":
    server.start_io()
```

O cliente dependerá, claro, do editor de texto/IDE. É aqui que surge o primeiro impedimento ao objetivo do trabalho.

= Visual Studio Code ou Emacs

O VSCode
#footnote[https://code.visualstudio.com/],
nas palavras do professor, pode ser "bastante burocrático" na implementação de um cliente LSP. De facto, esse cliente teria de ser um projecto implementado em TypeScript, e o _debugging_ involve também muita burocracia, especialmente quando comparado com a alternativa: Emacs.

O Emacs
#footnote[https://www.gnu.org/software/emacs/] é muito personalizável e, crucialmente, tem uma extensão que permite trabalhar com LSP, Eglot
#footnote[https://joaotavora.github.io/eglot/]. É relativamente fácil fazer com que esta extensão lance o nosso servidor, como veremos no próximo capitulo. Permite também monitorizar as mensagens enviadas entre Emacs e o servidor de uma maneira simples.

= Configuração do sistema
