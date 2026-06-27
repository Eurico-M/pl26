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
  Docente: Vitor Santos Costa \ \
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
  header: [*Exemplo de um lsp.py*],
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
  source $ENV/bin/activate
  ```,
)
#zebraw(
  numbering: false,
  ```fish
  source $ENV/bin/activate.fish
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
  header: [*packages.json*],
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
  header: [*yap.py*],
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
  header: [*yap.py*],
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

== validate_text/3

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

#pagebreak()

#zebraw(
  header: [*lsp.yap*],
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

#pagebreak()

== term_expansion/2

Em Prolog, existem predicados chamadas _hooks_ que são corridos automaticamente pelo YAP#footnote[https://www.swi-prolog.org/pldoc/man?section=hooks]. Assim, a linha `load_files(File,[stream(Stream)])` ativa o hook `term_expansion/2`, que é (re)definido neste ficheiro:

#zebraw(
  header: [*lsp.yap*],
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

== analyze/5

`analyse/5` descobre que tipo de termo Prolog estamos a tratar:

#zebraw(
  header: [*lsp.yap*],
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

== rule/5

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
  header: [*lsp.yap*],
  highlight-lines: (
    ..range(3, 4),
    (4, [Extrair nome do predicado, o seu módulo e argumentos.]),
    ..range(7, 9),
    (9, [Verificar se a definição desse predicado já existe. Se existir, não fazer nada.]),
    (11, [Se não existir, guardar na base de dados.]),
    (14, [Analisar o Corpo da Regra.]),
  ),
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

Aqui encontramos o que pensamos ser um _bug_. Repare-se que ao fazer _pattern matching_ no predicado `analyze/5`, uma cláusula do tipo Facto ou Regra seria apanhada pela terceira regra de `analyze/5`.

No entanto, essa regra chama o predicado `rule/5`. Este predicado só faz _pattern matching_ com Regras (`A0 :- B`). Assim, Factos não são guardados na base de dados que depois será usada (eventualmente) para funções do LSP como _go-to-definitions_, análise semântica, entre outras.

#pagebreak()

Uma possível solução seria acrescentar o código seguinte ao predicado `rule/5`:

#zebraw(
  header: [*lsp.yap*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  rule(A0, Line, File, Module, Na) :-
      strip_module(Module:A0, MH, A),
      functor(A, Na, Ar),
      (
          def(Na, Ar, MH, _, _, predicate)
      ->
          true
      ;
          assert(def(Na, Ar, MH, Line, File, predicate))
      ).
  ```,
)

== body/5

O corpo de uma regra é tratado pelo predicado `body/5`:

#zebraw(
  header: [*lsp.yap*],
  highlight-lines: (
    ..range(1, 3),
    (3, [Variáveis são ignoradas.]),
    ..range(24, 26),
    (26, [Caso Base para o qual as outras regras convergem. Guardamos os vários predicados do corpo na base de dados.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  body(A,_L,_F,_M,_) :-
      var(A),
  !.

  body(M:A,L,F,_M,P0) :-
      !,
      body(A,L,F,M,P0).

  body((A,B),L,F,M,P0) :-
      !,
      body(A,L,F,M,P0),
      body(B,L,F,M,P0).

  body((A;B),L,F,M,P0) :-
      !,
      body(A,L,F,M,P0),
      body(B,L,F,M,P0).

  body((A->B),L,F,M,P0) :-
      !,
      body(A,L,F,M,P0),
      body(B,L,F,M,P0).

  body(A,L,F,M,M0:Na0/Ar0) :-
      functor(A,NA,Ar),
      assert(use(NA,Ar,M,Na0,Ar0,M0,L,F,predicate)).
  ```,
)

== directive/4

Ainda a partir do predicado `analyze/5`, se encontrarmos uma directiva, ela é processada pelo predicado `directive/4`:

#zebraw(
  header: [*lsp.yap*],
  highlight-lines: (
    ..range(1, 5),
    (5, [Uma directiva do tipo `module` é guardada na base de dados, incluindo os seus `export`.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  directive(module(M,Ls),L,F,M0) :-
      assert(def('',0,M,L,F,module)),
      assert(use('',0,M,'',0,M0,L,F,module)),
      current_source_module(M0,M),
      maplist(mod(L,F,M),Ls).

  directive(op(A,B,C), _Line,_File,M) :-
      op(A,B,M:C).

  directive(use_module(_A), _Line,_File,_M) :-
      !.
  directive(use_module(_A,_B), _Line,_File,_M) :-
      !.
  directive(load_files(_A,_B), _Line,_File,_M) :-
      !.
  directive(ensure_loaded(_A), _Line,_File,_M) :-
      !.
  directive(consult(_A), _Line,_File,_M) :-
      !.
  directive(reconsult(_A), _Line,_File,_M) :-
      !.
  directive(compile(_A), _Line,_File,_M) :-
      !.
  directive(use_module(_A,_B,_C), _Line,_File,_M) :-
      !.

  directive((A,B), Line,File,M) :-
      !,
      directive(A, Line,File,M),
      directive(B, Line,File,M).
  ```,
)

#pagebreak()

== portray_message/2 e q_msg/3

O predicado seguinte, que também é um hook, corre quando o YAP deteta um erro#footnote[https://sicstus.sics.se/sicstus/docs/3.12.10/html/sicstus/Message-Handling-Predicates.html]. Neste caso, `term_expansion/2` não é chamado, mas sim este predicado:

#zebraw(
  header: [*lsp.yap*],
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
  header: [*lsp.yap*],
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

#pagebreak()

= Problemas

O projeto encontra-se ainda em fase de desenvolvimento, tendo sido encontrados vários problemas ao longo do semestre.

Em primeiro lugar, e já mencionado acima, a intenção original era desenvolver uma extensão para o Visual Studio Code. No entanto, a excessiva burocracia e complexidade do VSCode levaram-nos, com a sugestão do professor, a desenvolver primeiro a parte do servidor LSP, e para isso usámos o Emacs, para ter o mínimo de fricção da parte do cliente/editor de texto.

Porém, também na parte do servidor encontrámos problemas que não conseguimos resolver dentro do prazo.

O primeiro destes, que não deve ser menosprezado, é o entender o projeto em si. Este é o nosso primeiro contacto com uma linguagem lógica como o Prolog. Apesar de sermos familiares com linguagens funcionais, nós preferimos linguagens imperativas (por exemplo, no semestre passado, na Unidade Curricular de Compiladores, quando enfrentados com a escolha de escrever um compilador em Haskell ou C, escolhemos C). Assim, saltar de cabeça para um projeto tão complexo como este requereu estudar o código linha a linha, antes de tentar sequer implementar alguma coisa.

Tivemos também vários problemas com a configuração do projeto em várias máquinas. Por exemplo, o Eurico continua com erros no seu desktop:

#zebraw(
  ```
  [stderr]  Traceback (most recent call last):
  [stderr]    File "/home/eurico/Cloned-Repositories/Codeberg/lsp4yap/yap.py", line 41, in <module>
  [stderr]      from yap4py.yapi import Engine, EngineArgs
  [stderr]    File "/home/eurico/Projects/env/lib/python3.14/site-packages/yap4py/yapi.py", line 25, in <module>
  [stderr]      from yap4py.queries import top_query
  [stderr]    File "/home/eurico/Projects/env/lib/python3.14/site-packages/yap4py/queries.py", line 10, in <module>
  [stderr]      from yap4py.yap import YAPQuery
  [stderr]  ModuleNotFoundError: No module named 'yap4py.yap'
  [jsonrpc] D[09:21:32.141] Connection state change: `exited abnormally with code 1
  ```,
)

Estes erros apontam para o módulo `yap4py`, do repositório `yap`, que o Eurico diz ter instalado correctamente, seguindo o guia de configuração apresentado neste relatório mais acima, com várias variações e a partir de vários repositórios de `yap` e `lsp4yap`.

Enquanto que no seu portátil, o Eurico reporta outro erro, este muito mais verboso, com linhas que apontam para, por exemplo:

#zebraw(
  ```
  /usr/local/share/Yap/yapi.yap:18:33: error: stream(0,pipe(9)):0:0: error executing prolog:throw/1
  [...]
  %%% domain error: consulted_at(_119) does not belong to domain implemented_option.
  [...]
  % info: yapi:load_files(library(maplist),[if(not_loaded),must_be_module(true),consulted_at(_119)])
  ```,
)

Seria imprático colocar no relatório as centenas de linhas deste erro, mas o ponto é o seguinte: este projeto encontrou muitos erros de configuração e comunicação entre os vários ficheiros e programas que o compõem. O que é compreensível e até expectável, dada a dimensão e complexidade do projeto.

#pagebreak()

= Alternativas

Seguem-se algumas alternativas que explorámos ao longo do trabalho, por vários motivos, o principal dos quais a simples exploração académica.

== Expressões Regulares

Num primeiro encontro com o pygls, a maioria dos exemplos fornecidos na documentação envolvem alterar apenas o ficheiro principal Python (no nosso caso, `yap.py`). Deste modo, este ficheiro não dependeria de nada, para além das dependências intrínsecas ao pygls.

Usando o exemplo de Publish Diagnostics da documentação do pygls#footnote[https://pygls.readthedocs.io/en/latest/servers/examples/publish-diagnostics.html] como base, é relativamente simples construir o seguinte ficheiro, que reconhece apenas factos e regras de prolog:

#zebraw(
  header: [*regex-linebyline.py*],
  highlight-lines: (
    (9, [Facto: "p(a)."]),
    (10, [Regra: "q(a) :- p(a)."]),
    ..range(23, 25),
    (25, [Em cada linha do documento, verificar se é um facto ou uma regra.]),
    ..range(27, 40),
    (40, [Se não for um facto ou uma regra, marcar toda a linha como um erro.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  import logging
  import re

  from lsprotocol import types
  from pygls.cli import start_server
  from pygls.lsp.server import LanguageServer
  from pygls.workspace import TextDocument

  FACT = re.compile(r"^\s*([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*\.$")
  RULE = re.compile(r"^\s*([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*\:\-\s*(([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*[\,\;]?\s*)+\.$")


  class PublishDiagnosticServer(LanguageServer):
      """Language server demonstrating "push-model" diagnostics."""

      def __init__(self, *args, **kwargs):
          super().__init__(*args, **kwargs)
          self.diagnostics = {}

      def parse(self, document: TextDocument):
          diagnostics = []

          for idx, line in enumerate(document.lines):
              fact = FACT.match(line)
              rule = RULE.match(line)

              if fact is None and rule is None:
                  message = "Not a fact or rule"
                  severity = types.DiagnosticSeverity.Error

                  diagnostics.append(
                      types.Diagnostic(
                          message=message,
                          severity=severity,
                          range=types.Range(
                              start=types.Position(line=idx, character=0),
                              end=types.Position(line=idx, character=len(line) - 1),
                          ),
                      )
                  )

          self.diagnostics[document.uri] = (document.version, diagnostics)
          # logging.info("%s", self.diagnostics)


  server = PublishDiagnosticServer("diagnostic-server", "v1")


  @server.feature(types.TEXT_DOCUMENT_DID_OPEN)
  def did_open(ls: PublishDiagnosticServer, params: types.DidOpenTextDocumentParams):
      """Parse each document when it is opened"""
      doc = ls.workspace.get_text_document(params.text_document.uri)
      ls.parse(doc)

      for uri, (version, diagnostics) in ls.diagnostics.items():
          ls.text_document_publish_diagnostics(
              types.PublishDiagnosticsParams(
                  uri=uri,
                  version=version,
                  diagnostics=diagnostics,
              )
          )


  @server.feature(types.TEXT_DOCUMENT_DID_CHANGE)
  def did_change(ls: PublishDiagnosticServer, params: types.DidOpenTextDocumentParams):
      """Parse each document when it is changed"""
      doc = ls.workspace.get_text_document(params.text_document.uri)
      ls.parse(doc)

      for uri, (version, diagnostics) in ls.diagnostics.items():
          ls.text_document_publish_diagnostics(
              types.PublishDiagnosticsParams(
                  uri=uri,
                  version=version,
                  diagnostics=diagnostics,
              )
          )


  if __name__ == "__main__":
      logging.basicConfig(level=logging.INFO, format="%(message)s")
      start_server(server)

  ```,
)

É obviamente um LSP muito básico, e a maneira como iteramos pelo documento (linha a linha) impede que este sistema consiga detetar blocos multi-linha. É útil apenas para ficheiros prolog de factos e regras, um por linha.

#figure(
  image("images/regex-emacs.png", width: 50%),
  caption: [Falta de um ponto final na segunda linha é detetado.],
)

== Gramática Independente de Contexto

Uma ferramenta mais poderosa para este tipo de aplicação seria uma gramática independente de contexto (CFG). Se conseguirmos alimentar o texto completo do documento a uma gramática que reconheça Prolog, e que reporte erros com expressão suficiente para o nosso caso de uso, teremos construído um LSP interessante.

Para a gramática de Prolog o professor apontou-nos para o Tree Sitter de Prolog#footnote[https://github.com/DataGrout/tree-sitter-grammars/blob/main/tree-sitter-prolog/grammar.js], que define por completo a CFG do Prolog.

Para construir este sistema encontrámos o PLY#footnote[https://github.com/dabeaz/ply]#super[,]#footnote[https://ply.readthedocs.io/en/latest/ply.html], uma implementação em Python das ferramentas lex#footnote[https://en.wikipedia.org/wiki/Lex_(software)] e Yacc#footnote[https://en.wikipedia.org/wiki/Yacc]. O que é relevante porque o nosso grupo usou ferramentas análogas (Flex#footnote[[https://ftp.gnu.org/old-gnu/Manuals/flex-2.5.4/html_mono/flex.html]] e GNU Bison#footnote[https://www.gnu.org/software/bison/manual/html_node/index.html#SEC_Contents]) para construir um compilador em C#footnote[https://github.com/Eurico-M/compiladores/tree/main], na Unidade Curricular de Compiladores no primeiro semestre.

Usando a nossa (pouca) experiência em GNU Bison desse trabalho, construímos uma gramática simples (a notação é a que é usada pelo Bison, uma adaptação de Backus–Naur form#footnote[https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form]):

#zebraw(
  header: [*CFG simples*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```bnf
  source_file
      : clauses
      ;

  clauses
      : clauses clause
      | clause
      ;

  clause
      : fact
      | rule
      ;

  fact
      : ATOM "(" arglist ")" "."
      ;

  rule
      : ATOM "(" arglist ")" ":-" body "."
      ;

  body
      : ATOM "(" arglist ")"
      | ATOM "(" arglist ")" "," body
      ;

  arglist
      : term
      | term "," arglist
      ;

  term
      : ATOM
      | VARIABLE
      | NUMBER
      | ATOM "(" arglist ")"
      ;
  ```,
)

Nesta gramática, um ficheiro é uma lista de cláusulas (definida recursivamente). Uma cláusula é um facto ou uma regra, que são definidos seguidamente. Seguindo a notação de Prolog, átomos e variáveis são diferentes (átomos começam por letras minúsculas, variáveis por letras maiúsculas).

Para implementar esta gramática, precisamos primeiro de criar tokens a partir do nosso ficheiro de texto. Para isso usamos a parte Lex do PLY:

#zebraw(
  header: [*simple-cfg.py*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  import ply.lex as lex

  tokens = (
      "ATOM",
      "VARIABLE",
      "NUMBER",
      "COMMA",
      "LPAREN",
      "RPAREN",
      "IMPLIES",
      "PERIOD",
  )

  t_COMMA = r","
  t_LPAREN = r"\("
  t_RPAREN = r"\)"
  t_IMPLIES = r":-"
  t_PERIOD = r"\."
  t_VARIABLE = r"[A-Z_][a-zA-Z0-9_]*"
  t_ATOM = r"[a-z][a-zA-Z0-9_]*"
  t_NUMBER = r"[0-9]+"

  t_ignore = " \t\r"
  t_ignore_COMMENT = r"%[^\n]*"


  def t_newline(t):
      r"\n+"
      t.lexer.lineno += len(t.value)


  def t_error(t):
      raise SyntaxError(f"Illegal character '{t.value[0]}' at line {t.lineno}")


  lexer = lex.lex()
  ```,
)

Definimos os nossos tokens, as expressões regulares que os definem, e funções auxiliares para contar números de linha e lidar com caracteres desconhecidos.

Com o tokenizer construído, podemos fazer um parser ao estilo do Yacc/Bison:

#zebraw(
  header: [*simple-cfg.py*],
  highlight-lines: (
    ..range(3, 7),
    (
      7,
      [No comentário da função temos a definição da regra gramatical, e depois temos uma notação inspirada pelo Yacc, `$$ = $1`, ou seja, o source_file é o resultado de uma lista de clauses.],
    ),
    ..range(25, 27),
    (27, [Aqui definimos valores que são guardados no nó da AST.]),
    ..range(69, 74),
    (
      74,
      [Aproveitamos o SyntaxError do Python para guardar, para além da string de erro, informação do número de linha (e, eventualmente, coluna, que para já é 0).],
    ),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  import ply.yacc as yacc

  def p_source_file(p):
      """source_file : clauses
      | empty"""
      if len(p) == 2:
          p[0] = p[1]


  def p_clauses(p):
      """clauses : clauses clause
      | clause"""
      if len(p) == 3:
          p[0] = p[1] + [p[2]]
      else:
          p[0] = [p[1]]


  def p_clause(p):
      """clause : fact
      | rule"""
      p[0] = p[1]


  def p_fact(p):
      """fact : ATOM LPAREN arglist RPAREN PERIOD"""
      p[0] = ("fact", p[1], p[3], p.lineno(1))


  def p_rule(p):
      """rule : ATOM LPAREN arglist RPAREN IMPLIES body PERIOD"""
      p[0] = ("rule", p[1], p[3], p[6], p.lineno(1))


  def p_body(p):
      """body : ATOM LPAREN arglist RPAREN
      | ATOM LPAREN arglist RPAREN COMMA body"""
      if len(p) == 5:
          p[0] = [(p[1], p[3])]
      else:
          p[0] = [(p[1], p[3])] + p[6]


  def p_arglist(p):
      """arglist : term
      | term COMMA arglist"""
      if len(p) == 2:
          p[0] = [p[1]]
      else:
          p[0] = [p[1]] + p[3]


  def p_term(p):
      """term : ATOM
      | VARIABLE
      | NUMBER
      | ATOM LPAREN arglist RPAREN"""
      if len(p) == 2:
          p[0] = p[1]
      else:
          p[0] = (p[1], p[3])


  def p_empty(p):
      """empty :"""
      p[0] = []


  def p_error(p):
      if p:
          raise SyntaxError(
              f"Syntax error at '{p.value}' (line {p.lineno})",
              ("error", p.lineno, 0, "error"),
          )


  parser = yacc.yacc()
  ```,
)

Repare-se que, como é expectável de um parser, podemos construir uma Abstract Syntax Tree. Assim, esta informação pode ser usada pelo nosso LSP para todas as funções mais complexas (análise semântica, _go-to-definition_, encontrar referências, etc.).

Estas funções não foram ainda implementadas no ficheiro exemplo `simple-cfg.py`. De facto, a nossa função `parse()` é bastante simples:


#zebraw(
  header: [*simple-cfg.py*],
  highlight-lines: (
    (
      7,
      [O resultado do parser é a AST, e poderia ser usado para várias funções do LSP. Aqui está simplesmente a ser ignorado (e imprimido directamente).],
    ),
    ..range(9, 14),
    (14, [Podemos ver o resultado da impressão no buffer das mensagens de EGLOT no Emacs.]),
  ),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```python
  def parse(self, document: TextDocument):
      diagnostics = []

      try:
          lexer.lineno = 1

          result = parser.parse(document.source, lexer=lexer)

          if DEBUG:
              import sys

              print("--- AST ---", file=sys.stderr)
              print(result, file=sys.stderr)
              print("--- END OF AST ---", file=sys.stderr)

      except SyntaxError as e:

          if e.lineno is not None:
              error_line = e.lineno - 1
          else:
              error_line = 0

          line_length = len(document.lines[error_line])

          diagnostics.append(
              types.Diagnostic(
                  message=str(e),
                  severity=types.DiagnosticSeverity.Error,
                  range=types.Range(
                      start=types.Position(line=error_line, character=0),
                      end=types.Position(line=error_line, character=line_length),
                  ),
              )
          )

      self.diagnostics[document.uri] = (document.version, diagnostics)
  ```,
)

É uma função muito simples que serve apenas de exemplo, e carece de vários melhoramentos. Por exemplo, só assinalamos a linha onde o erro é reportado, não calculamos a coluna. Mas o mais crucial, o parser só lida com um erro. Se houver dois erros no ficheiro, só lidámos com o primeiro que for apanhado pelo parser. Para isso, teríamos que acrescentar recuperação de erros ao nosso parser.

Podemos, para já, ver a AST que é construída pelo PLY.

#figure(
  image("images/cfg-emacs.png", width: 50%),
  caption: [Simples base de dados Prolog com facto e regra.],
)

#figure(
  image("images/ast-emacs.png", width: 100%),
  caption: [AST imprimida no buffer do EGLOT.],
)

Podemos ver que a nossa AST é constituída por um `fact`, `p`, que tem como argumentos `a`, na linha 1, e uma `rule`, `q`, com argumentos `a` e cujo corpo é uma lista, neste caso unitária, `p` com argumentos `a`, na linha 3.

#pagebreak()

= Global

A pedido do professor, criámos um pequeno programa, `global.pl`.

Mantemos os predicados `validate_file/2`, `validate_source/3`, `validate_text/3`, `term_expansion/2`, `analyze/5`, `rule/5`, `directive/4`, `body/5`, do ficheiro `lsp.yap`.

Podemos lançar este programa com o YAP, e usando como exemplo `file.pl`:

#zebraw(
  numbering: false,
  ```bash
  yap
  ```,
)

#zebraw(
  numbering: false,
  ```YAP
  ?- [global].
  ?- validate_file('./file.pl', E).
  ```,
)

Para verificar os `def` e `use` na base de dados:

#zebraw(
  numbering: false,
  ```YAP
  ?- listing(def/6).
  ?- listing(use/9).
  ```,
)

Para criar imagens de grafos, podemos criar um ficheiro DOT#footnote[https://en.wikipedia.org/wiki/DOT_(graph_description_language)], para mostrar os predicados usados por outros predicados:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  write_dot :-
      open('graph.dot', write, Out),
      writeln(Out, 'digraph Calls {'),

      forall(use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
          format(Out, '  "~w/~w" -> "~w/~w:~w";~n', [Caller, CallerArity, Called, CalledArity, Line])),

      writeln(Out, '}'),
      close(Out).
  ```,
)

E usando Graphviz#footnote[https://graphviz.org/doc/info/command.html]:

#zebraw(
  numbering: false,
  ```bash
  dot -Tpng graph.dot -o graph.png
  ```,
)

Obtemos o seguinte grafo:

#figure(
  image("files/graph.png", width: 60%),
  caption: [Grafo de chamadas.],
)

Que corresponde a `file.pl`:

#zebraw(
  header: [*file.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  p(a).
  p(X) :-
      q(X),
      r(X).
  p(X) :-
      u(X).

  q(X) :-
      r(X).
  q(X, Y) :-
      s(X),
      t(Y).

  r(a).
  r(b).

  s(a).
  s(b).
  s(c).

  u(d).

  v(X, Y, Z) :-
      r(X);
      q(Y, Z).
  ```,
)

Os seguintes predicados foram acrescantados e são úteis à análise do documento prolog:

== list_calls/1

Podemos listar todos os `use`, que podemos pensar como se fossem as arestas do grafo que ligam os predicados:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  list_calls(L) :-
      findall((Caller/CallerArity, Called/CalledArity: Line),
          use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
      L).
  ```,
)

== list_by_caller/2

Se estivermos interessados num único predicado que chama outros:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  list_by_caller(Caller, L) :-
      findall((Caller/CallerArity, Called/CalledArity: Line),
          use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
      L).
  ```,
)

== list_by_called/2

Ou um predicado que é chamado por outros:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  list_by_called(Called, L) :-
      findall((Caller/CallerArity, Called/CalledArity: Line),
          use(Called, CalledArity, _, Caller, CallerArity, _, Line, _, _),
      L).
  ```,
)

== list_by_arity/2

Para listar todos os predicados com uma determinada aridade:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  list_by_arity(Arity, L) :-
      findall(Name/Arity: Line, def(Name, Arity, _, Line, _, _), L).
  ```,
)

== entry_points/1

Se um predicado é definido, mas nunca é usado, é um ponto de entrada:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  entry_points(L) :-
      findall(Name/Arity:Line,
          (
              def(Name, Arity, _, Line, _, _),
              \+ use(Name, Arity, _, _, _, _, _, _, _)
          ),
          L).
  ```,
)

== undefined_calls/1

De uma maneira semelhante, podemos listar os predicados que são usados mas nunca foram definidos:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  undefined_calls(L) :-
      findall(Name/Arity:Line,
          (
              use(Name, Arity, _, _, _, _, Line, _, _),
              \+ def(Name, Arity, _, _, _, _)
          ),
          L).
  ```,
)

== connected/3

Dados dois predicados, podemos verificar se estão "ligados", ou seja, se, transitivamente, o primeiro chama o segundo. A lista devolvida representa o caminho da chamada:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  connected(Start/StartArity, End/EndArity, Path) :-
      connected(Start/StartArity, End/EndArity, Path, [Start/StartArity]).

  connected(Start/StartArity, End/EndArity, [Start/StartArity, End/EndArity], _Visited) :-
      use(End, EndArity, _, Start, StartArity, _, _, _, _).

  connected(Start/StartArity, End/EndArity, [Start/StartArity|Rest], Visited) :-
      use(Middle, MiddleArity, _, Start, StartArity, _, _, _, _),
      \+ member(Middle/MiddleArity, Visited),
      connected(Middle/MiddleArity, End/EndArity, Rest, [Middle/MiddleArity|Visited]).
  ```,
)

== cycles/1

Para detetar ciclos, podemos pensar nas chamadas como se fossem arestas dirigidas de um grafo que liga os predicados (nós). Assim, usámos o algoritmo de três cores (branco, cinzento, preto) para deteção de ciclos em grafos#footnote[https://www.geeksforgeeks.org/dsa/detect-cycle-in-a-graph/]:

#zebraw(
  header: [*global.pl*],
  highlight-lines: (),
  comment-flag: "",
  comment-font-args: (
    style: "italic",
  ),
  numbering-separator: true,
  ```prolog
  cycles(L) :-
      findall(Name/Arity, cycle_path(Name/Arity, [], []), L).

  edge(A/Aar, B/Bar) :-
      use(B, Bar, _, A, Aar, _, _, _, _).

  cycle_path(Node, Visited, RecStack) :-
      member(Node, RecStack),
      !.

  cycle_path(Node, Visited, RecStack) :-
      member(Node, Visited),
      !,
      fail.

  cycle_path(Node, Visited, RecStack) :-
      edge(Node, Next),
      cycle_path(Next, [Node|Visited], [Node|RecStack]).
  ```,
)


#pagebreak()

= Conclusão

O trabalho realizado foi singular, na medida em que envolveu o estudo e compreensão de vários componentes e a sua interação. De certo modo, fez-nos lembrar o trabalho de desenvolver um compilador na Unidade Curricular de Compiladores.

Apesar de não ser um trabalho desenvolvido totalmente em Prolog, ganhámos uma compreensão desta linguagem, através do estudo da sua Gramática Independente de Contexto, e principalmente da análise do ficheiro `lsp.yap`.

Os vários componentes do projeto requereram o uso de Prolog, Python, JSON, TypeScript (numa fase inicial de integração com o VSCode), Lisp (quando Emacs substituiu VSCode), o que para os membros mais generalistas do grupo foi um aspeto positivo e enriquecedor (ainda que por vezes complexo).

Sem a ajuda do professor, a nossa intuição seria seguir o caminho descrito no capítulo Alternativas: construir um parser da gramática de Prolog, capaz de criar uma Abstract Syntax Tree útil para as funcionalidades do LSP, e capaz de reportar erros de uma maneira robusta suficiente para uso no LSP.

É possível que também tivéssemos ficado um pouco perdidos na complexidade de implementar uma extensão de Visual Studio Code, que estudámos inicialmente, e cujo _debugging_ se começava a revelar moroso. Assim, outra vantagem deste trabalho foi o facto de nos expôr ao Emacs. Por ser simples de personalizar (através da sua configuração escrita em Lisp) e com o seu sistema de _buffers_ que expõe várias mensagens úteis, percebemos porque é que este programa ainda é usado atualmente.

Temos assim várias avenidas de exploração para o futuro: projectos em Prolog, em particular alguns dos outros trabalhos mencionados pelo professor nas aulas (interrogação de bases de dados e jogos são dois projetos que considerámos como alternativa); extensões de Visual Studio Code; LSP vs Tree Sitter, e outros sistemas de análise sintática e semântica de código fonte, e a sua integração com editores de texto e IDEs; o uso de Emacs; entre outras.
