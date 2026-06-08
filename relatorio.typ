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

// Acrescentar números de linha, comentários, e outras utilidades nos blocos de código
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
= Funcionamento

== lsp4yap

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

É importante recordar que, na configuração do Emacs, nós definimos que a extensão Eglot deve correr o ficheiro `yap.py` quando entra no modo Prolog, "ignorando" assim estas configurações. Esta é mais uma razão para ter escolhido Emacs, a facilidade de ligar o editor de texto com o ficheiro que especificamos diretamente. Os ficheiros de configuração envolventes que o pygls providencia são úteis quando quisermos adaptar este projeto para Visual Studio Code.
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

== YAP

Ainda no ficheiro `yap.py`, a função `validate_text()` interage com `engine`, que é inicializado da seguinte maneira:

#zebraw(
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  from yap4py.yapi import Engine, EngineArgs

  # [...] #

  def start_yap():
      eargs.jupyter = True
      try:
          engine = Engine( eargs)
          engine.load_library("lsp")
      except Exception:
          print("bad load")
          engine = None
      return engine
  ```,
)

`yap4py.yapi`, em `$YAP/packages/python`, funciona como um interpretador de Prolog dentro do YAP, capaz de receber instruções em Python e corrê-las em Prolog.

Desta maneira, usamos o compilador YAP como um interpretador de texto Prolog que, em vez de converter esse texto para código máquina (como o faria em "modo de compilador"), reporta apenas erros sintáticos e informa-nos acerca de tabelas de símbolos, as funcionalidades que requeremos para implementar um LSP.

Assim, voltando a `yap.py`, a linha:

#zebraw(
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering: false,
  ```python
  data = engine.fun(validate_text(uri,document.source))
  ```,
)

É processada pelo `engine`, que é um "interpretador", e corre a função `validate_text(uri,document.source)`. Consegue fazê-lo porque importa a biblioteca `lsp`, que é definida no ficheiro `lsp.yap`, também em `$YAP/packages/python`. Dentro deste ficheiro está definido o predicado correspondente, `validate_text/3`:

#zebraw(
  highlight-lines: (
    ..range(8, 10),
    (10, [Apaga dados anteriores.]),
    ..range(12, 13),
    (13, [Abre o texto como uma Stream.]),
    (15, [Liga o "modo" LSP.]),
    ..range(17, 18),
    (18, [Carrega e processa a Stream de texto.]),
    (20, [Desliga o "modo" LSP.]),
    (22, [Recolhe todos os erros.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  validate_text(URI,S,Ts) :-

      writeln(user_error, URI),

      string_concat("file://", FileAsS, URI),
      atom_string(FileAsS, File),

      retractall(def(_,_,_,_,File,_)),
      retractall(use(_,_,_,_,_,_,_,File,_)),
      retractall(dec(_,_,_,_,File,_)),

      open(string(S),read,Stream),
      current_source_module(DefaultModule,user),

      assert(lsp(on)),

      load_files(File,[stream(Stream)]),
      current_source_module(_,DefaultModule),

      retractall(lsp(_)),

      findall(T,retract(m(T)),Ts).
  ```,
)

Em Prolog, existem predicados chamadas _hooks_ que são corridos automaticamente pelo YAP#footnote[https://www.swi-prolog.org/pldoc/man?section=hooks]. Assim, a linha `load_files(File,[stream(Stream)])` ativa o hook `term_expansion/2`, que é (re)definido neste ficheiro:

#zebraw(
  highlight-lines: (
    (3, [Só corre se estivermos no "modo" LSP]),
    (10, [Analisa o termo Prolog]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  user:term_expansion(G, GF) :-

      lsp(on),

      prolog_load_context(file, F ),
      prolog_load_context(term_position, Pos ),
      current_source_module(M, M ),
      arg(2, Pos, Line),

      analyse(G,Line,F,M,GF),
      !.
  ```,
)

`analyse/5` descobre que tipo de termo Prolog estamos a tratar:

#zebraw(
  highlight-lines: (
    ..range(1, 3),
    (3, [Cláusulas que só têm corpo.]),
    ..range(5, 6),
    (6, [Outras cláusulas só com corpo.]),
    ..range(8, 9),
    (9, [Cláusulas de Factos e Regras, a maioria do casos.]),
    ..range(11, 13),
    (13, [O resto que não for apanhado pelos casos anteriores.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  analyse((:- G), L, F, M, (:- true)) :-
      !,
      directive(G, L, F, M).

  analyse((:- _G), _L, _F, _M, (:- true)) :-
      !.

  analyse(Cl, L, F, M, Na) :-
      rule(Cl, L, F, M, Na).

  analyse(_G, _L, _F, _M,  Na) :-
      strip_module(G,_MH,A),
      functor(A,Na,_Ar).
  ```,
)

O caso mais comum é uma Cláusula de Factos ou Regras. Relembremos que Factos são do tipo:
#zebraw(
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering: false,
  ```prolog
  p(a).
  ```,
)
E Regras são:
#zebraw(
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering: false,
  ```prolog
  q(a) :- p(a).
  ```,
)

Portanto, para explorar estes casos, usamos o predicado `rule/5`:
#zebraw(
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  rule((A0:- B),Line,File,Module,Na) :-
      strip_module(Module:A0,MH,A),
      functor(A,Na,Ar),
      (
      def(Na,Ar,MH,_,_,predicate)
         ->
      true
         ;
      assert(def(Na,Ar,MH,Line,File,predicate))
      ),
      body(B,Line,File,Module,MH:Na/Ar).
  ```,
)


O predicado seguinte, que também é um hook, corre quando o YAP deteta um erro#footnote[https://sicstus.sics.se/sicstus/docs/3.12.10/html/sicstus/Message-Handling-Predicates.html]. Neste caso, `term_expansion/2` não é chamado, mas sim este predicado:

#zebraw(
  highlight-lines: (
    (6, [Converte a mensagem num tuplo]),
    (9, [Guarda esse tuplo na base de dados]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  user:portray_message(A,B):-
      lsp(on),
      !,
      writeln(user_error,B),
      (
       q_msg(A,B,T),
       A \= "ignored"
      ->
       assert(m(T))
        ;
      true
      ).
  ```,
)

`q_msg/3` filtra os vários tipos de mensagens geradas pelo YAP, e devolve as que são úteis ao LSP em tuplos `t(Severity, Message, StartLine, StartColumn, EndLine, EndColumn)`:

#zebraw(
  highlight-lines: (
    ..range(1, 7),
    (7, [Mensagens informacionais ou de ajuda são ignoradas.]),
    ..range(9, 13),
    (
      13,
      [Um aviso que reporta erros de singletons é formatado num tuplo de tipo "warning", com a string definida aqui, e a sua localização em linhas e colunas.],
    ),
    ..range(15, 21),
    (21, [O mesmo predicado definido múltiplas vezes.]),
    ..range(23, 30),
    (30, [Cláusulas do mesmo predicado que não estão agrupadas.]),
    ..range(32, 37),
    (37, [Erros sintáticos.]),
    ..range(39, 40),
    (40, [Quaisquer outros erros.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  q_msg(informational, _, _) :-
      !,
      fail.

  q_msg(help, _, _) :-
      !,
      fail.

  q_msg(warning, error(style_check(singletons,[VName,Line,Column,_F0],_),_Desc),t("warning",S, Line,Column, Line,EndCol)) :-
      !,
      format(string(S), 'singleton variable ~s.~n ', [VName]),
      atom_length(VName, Len),
      EndCol is Column+Len.

   q_msg(warning, error(style_check(multiple,[F0|L],I ) ,_Desc ), t("warning",S, L,Column,L,EndCol)) :-
      !,
      Column=1,
      format(string(S), '~w previously defined at ~s.~n',[I,F0]),
      I = Name/_,
      atom_length(Name, Len),
      EndCol is Column+Len.

  q_msg(warning, error(style_check(discontiguous,_,_I ), _Desc), t("warning",S, L,Column, L, EndCol)) :-
      !,
      Column=1,
      format(string(S), 'discontiguous definition for ~w.~n',[I]),
      I = Name/_,
      atom_length(Name, Len),
      EndCol is Column+Len,
      S = "discontiguous.~n".

  q_msg(_error, error(syntax_error(_Msg), Desc),  t("error","syntax error", L,LPos,L,LP1)) :-
      exception_property(parserLine, Desc, L),
      exception_property(parserLinePos, Desc, LPos),
      exception_property(parserSize, Desc, Size),
      !,
      LP1 is LPos+Size.

  q_msg(_,Error,t("ignored",Msg,1,0,2,0)) :-
      term_to_string(Error,Msg).
  ```,
)
