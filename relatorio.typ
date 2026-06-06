#set page(
  paper: "a4",
)

#set document(
  title: "Language Server Protocol para YAP",
)

#set text(
  size: 12pt,
)
// Espaço entre linhas
#set par(
  leading: 1em,
)
// Espaço depois dos cabeçalhos
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
  image("images/fcup-identidade-logotipo-cores.png", width: 50%),
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
  title: [Conteúdos],
)
#pagebreak()

#set page(
  numbering: "1/1",
)

= Motivação

Um dos possíveis trabalhos apresentados pelo professor foi o desenvolver uma solução para o seguinte problema: os utilizadores de editores de texto e IDE's esperam que estes programas possuam certas funcionalidades, como coloração de texto consoante a sintaxe da linguagem de programação, verificação e validação dessa sintaxe, procura de símbolos e definições, entre outras.

O compilador de Prolog YAP ainda não tem uma integração com possíveis soluções para este problema. Assim, este trabalho pretende investigar e implementar uma solução, usando o Language Server Protocol.

= Language Server Protocol

O Language Server Protocol#footnote[https://microsoft.github.io/language-server-protocol/]<lsp>(LSP) é um protocolo de comunicação entre editores de texto e IDE's, e um servidor de uma linguagem de programação, que providencia ao editor as regras e instruções necessárias à implementação de funcionalidades de formatação e uso dessa linguagem no contexto do editor ou IDE.

Desenvolvido pela Microsoft, e _open source_, é um protocolo usado no Visual Studio Code#footnote[https://code.visualstudio.com/api/language-extensions/language-server-extension-guide]<vscode>(VSCode) e, como este editor é bastante usado, atualmente, pelos alunos de Ciência de Computadores, o professor decidiu trabalhar neste contexto.

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

Uma destas ferramentas é o pygls#footnote[https://pygls.readthedocs.io/en/latest/]<pygls>.

= pygls

O pygls é uma "implementação genérica do LSP escrita em Python"#footnote(<pygls>).
Usando o pygls deve ser posssível escrever um servidor LSP em Python, de uma maneira relativamente simples.

Por exemplo, o código seguinte recebe um documento e, em cada linha que acabe em "hello.", retorna ao editor de texto a hipótese de autocompletar com "world" ou "friend", sempre que é introduzido um " . ".

#pagebreak()
#zebraw(
  highlight-lines: (
    (9, [O autocompletar só aparece quando se insere um "."]),
    ..range(19, 20),
    (20, [Itens que aparecem no autocompletar do editor de texto]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
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
  ```,
)

O cliente dependerá, claro, do editor de texto/IDE. É aqui que surge o primeiro impedimento ao objetivo do trabalho.

= Visual Studio Code ou Emacs

O VSCode#footnote[https://code.visualstudio.com/], nas palavras do professor, pode ser "bastante burocrático" na implementação de um cliente LSP. De facto, esse cliente teria de ser um projecto implementado em TypeScript, e o _debugging_ involve também muita burocracia, especialmente quando comparado com a alternativa: Emacs.

O Emacs#footnote[https://www.gnu.org/software/emacs/] é muito personalizável e, crucialmente, tem uma extensão que permite trabalhar com LSP, Eglot#footnote[https://joaotavora.github.io/eglot/]. É relativamente fácil fazer com que esta extensão lance o nosso servidor, como veremos no próximo capitulo. Permite também monitorizar as mensagens enviadas entre Emacs e o servidor de uma maneira simples.

= Configuração do sistema

No seu presente estado, este projecto precisa de três componentes:
- Um editor de texto/IDE. Usaremos Emacs, pelas razões mencionadas acima. Este editor de texto tem um cliente de LSP (Eglot);
- Um servidor de LSP. O professor providenciou o repositório lsp4yap, tanto no GitHub#footnote[https://github.com/vscosta/lsp4yap]<lsp4yapgit> como no Codeberg#footnote[https://codeberg.org/vscosta/lsp4yap]<lsp4yapberg>. Crucialmente, este repositório contém um ficheiro `yap.py`, que é o ponto de entrada do servidor. Este ficheiro, atualmente, recebe mensagens do editor (cliente LSP) e usa o próprio YAP para processar e assinalar com erros o texto do documento, enviando mensagens ao servidor `yap.py`, que depois as reenvia ao cliente;
- Um compilador de Prolog. Como vimos na entrada anterior, o nosso servidor precisa do YAP para funcionar. E obviamente faz sentido que, se estamos a escrever código em Prolog, temos um compilador dessa linguagem no mesmo sistema.

#figure(
  image("images/global-vision.png", width: 90%),
  caption: [Visão global do projeto],
)

Exploraremos os vários componentes com mais detalhe, mas primeiro preparemos o sistema.

Alguns caminhos importantes:
- `$ENV` é o caminho para um ambiente virtual Python, por exemplo `~/env`;
- `$LSP4YAP` é o caminho para o clone do repositório lsp4yap#footnote(<lsp4yapgit>)#super[,]#footnote(<lsp4yapberg>)\;
- `$YAP` é o caminho para o clone do repositório yap#footnote[https://github.com/vscosta/yap]<yapgit>#super[,]#footnote[https://codeberg.org/vscosta/yap]<yapberg>;

Procedemos da seguinte maneira:

== Ambiente Virtual Python

1. Criar um ambiente virtual Python. Navegar para o local pretendido (por exemplo `~/`) e executar:
#zebraw(
  numbering: false,
  ```bash
  python3 -m venv env
  ```,
)
2. Este ambiente tem de ser ativado, para podermos usar os comandos `python` e `pip` a partir de `$ENV`, e não do sistema. Se a shell usada for `fish`, o ficheiro a tocar é ligeiramente diferente:
#zebraw(
  numbering: false,
  ```bash
  source ./$ENV/bin/activate
  ```,
)
#zebraw(
  numbering: false,
  ```fish
  source ./$ENV/bin/activate.fish
  ```,
)
Para verificar se estamos a usar o ambiente virtual, executar os comandos seguintes e confirmar que o caminho devolvido é em `$ENV`:
#zebraw(
  numbering: false,
  ```bash
  which python
  which pip
  ```,
)
3. Podemos agora instalar as dependências Python:
#zebraw(
  numbering: false,
  ```bash
  pip install lsprotocol pygls numpy
  ```,
)

== YAP

4. Clonar o repositório yap#footnote(<yapgit>)#super[,]#footnote(<yapberg>) para `$YAP`:
#zebraw(
  numbering: false,
  ```bash
  git clone <yap_URL>
  ```,
)
5. No diretório `$YAP`, criar um diretório `Build` e navegar para aí:
#zebraw(
  numbering: false,
  ```bash
  mkdir Build
  cd Build
  ```,
)
6. Compilar e instalar YAP, a partir de `Build`:
#zebraw(
  numbering: false,
  ```bash
  cmake ../
  make
  sudo make install
  ```,
)
7. Navegar para `$YAP` e instalar o pacote Python `yap4py` no ambiente virtual (confirmar que está ativado, ponto 2):
#zebraw(
  numbering: false,
  ```bash
  pip install packages/python/yap4py
  ```,
)

== LSP4YAP

8. Clonar o repositório lsp4yap#footnote(<lsp4yapgit>)#super[,]#footnote(<lsp4yapberg>) para `$LSP4YAP`:
#zebraw(
  numbering: false,
  ```bash
  git clone <lsp4yap_URL>
  ```,
)

== Emacs

9. Instalar Emacs;
10. Configurar Emacs: no ficheiro de configuração, colocar:
#zebraw(
  numbering: false,
  ```lisp
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '(prolog-mode . ("$ENV/bin/python" "$LSP4YAP/yap.py"))))

  (add-hook 'prolog-mode-hook 'eglot-ensure)

  (setq auto-mode-alist (append '(("\\.pl\\'" . prolog-mode)
                                  ("\\.yap\\'" . prolog-mode))
                                  auto-mode-alist))
  ```,
)

== Utilizar lsp4yap

11. No Emacs, abrir um ficheiro de Prolog e fazer `M-x eglot` (`Alt+X`, escrever `eglot`, pressionar `Enter`)

#pagebreak()
= LSP4YAP

Atentemos agora com algum cuidado ao diretório `lsp4yap`.

O ficheiro `yap.py` é o ponto de entrada do nosso servidor. De notar que, no ficheiro `packages.json`, alguma variáveis devem ser definidas. Por exemplo:
#zebraw(
  numbering-separator: true,
  ```json
  "configuration": [
    {
      "type": "object",
      "title": "Server Configuration",
      "properties": {
        "pygls.server.launchScript": {
          "scope": "resource",
          "type": "string",
          "default": "examples/servers/yap.py",
          "description": "The python script to run when launching the server.",
          "markdownDescription": "The python script to run when launching the server.\n Relative to #pygls.server.cwd#"
        }
      }
    }
  ]
  ```,
)

Define que o servidor `pygls` deve correr `yap.py` quando inicia.
#pagebreak()

No ficheiro `yap.py`, uma função importante é `validate()`:

#zebraw(
  highlight-lines: (
    (4, [Este array de Diagnostics é preenchido com os vários erros]),
    (
      7,
      [A função validate_text() interage com o YAP, processando assim o documento num contexto de prolog, e recebendo como retorno erros, que são guardados em data.],
    ),
    (
      12,
      [Esse array de erros é depois processado aqui, num contexto de pygls. Range, Position, Diagnostic, entre outras, são construções que o pygls usa para definir as mensagens JSON RPC trocadas entre cliente e servidor LSP.],
    ),
    ..range(25, 30),
    (
      30,
      [Aqui construimos os vários Diagnostic, para cada erro reportado. Usamos os valores retornados pela função YAP validate_text() (sev, msg, e valores de linha e coluna).],
    ),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  def validate(self, document: TextDocument):
      """Validates prolog file."""

      diagnostics = []
      uri = document.uri
      print(" Master!!!!!!!!!!!!", file = sys.stderr)
      data = engine.fun(validate_text(uri,document.source))
      print(" Master:vdone")

      errs = data

      if errs:
          for (sev,msg,i0,j0,i1,j1) in errs:

              if sev == "warning":
                  sev=types.DiagnosticSeverity.Warning
              else:
                  sev=types.DiagnosticSeverity.Error

              location=types.Range(
                  start=types.Position(line=i0-1, character=j0-1),
                  end=types.Position(line=i1-1, character= j1-1)
              )

              diagnostics.append(
                  types.Diagnostic(
                  message  = msg,
                  severity=types.DiagnosticSeverity.Warning,
                  range = location
                  )
              )

      return document.version,diagnostics
  ```,
)
