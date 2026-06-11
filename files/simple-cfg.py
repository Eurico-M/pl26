import logging

import ply.lex as lex
import ply.yacc as yacc
from lsprotocol import types
from pygls.cli import start_server
from pygls.lsp.server import LanguageServer
from pygls.workspace import TextDocument

# ─────────────────────────── LEXER ───────────────────────────

tokens = (
    "ATOM",
    "VARIABLE",
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

t_ignore = " \t\r"
t_ignore_COMMENT = r"%[^\n]*"


def t_newline(t):
    r"\n+"
    t.lexer.lineno += len(t.value)


def t_error(t):
    raise SyntaxError(f"Illegal character '{t.value[0]}' at line {t.lineno}")


lexer = lex.lex()


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
        raise SyntaxError(f"Syntax error at '{p.value}' (line {p.lineno})")
    else:
        raise SyntaxError("Unexpected end of file")


parser = yacc.yacc()

# ─────────────────────────── LSP SERVER ───────────────────────────


class PrologServer(LanguageServer):
    """Simple Prolog LSP server with PLY grammar integration."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.diagnostics = {}

    def parse(self, document: TextDocument):
        diagnostics = []

        try:
            result = parser.parse(document.source, lexer=lexer)

        except SyntaxError as e:
            diagnostics.append(
                types.Diagnostic(
                    message=str(e),
                    severity=types.DiagnosticSeverity.Error,
                    range=types.Range(
                        start=types.Position(line=0, character=0),
                        end=types.Position(
                            line=len(document.lines) - 1,
                            character=len(document.lines[-1]) if document.lines else 0,
                        ),
                    ),
                )
            )

        self.diagnostics[document.uri] = (document.version, diagnostics)


server = PrologServer("prolog-server", "v1")


@server.feature(types.TEXT_DOCUMENT_DID_OPEN)
def did_open(ls: PrologServer, params: types.DidOpenTextDocumentParams):
    doc = ls.workspace.get_text_document(params.text_document.uri)
    ls.parse(doc)
    ls._publish_diagnostics()


@server.feature(types.TEXT_DOCUMENT_DID_CHANGE)
def did_change(ls: PrologServer, params: types.DidChangeTextDocumentParams):
    doc = ls.workspace.get_text_document(params.text_document.uri)
    ls.parse(doc)
    ls._publish_diagnostics()


def _publish_diagnostics(self):
    for uri, (version, diagnostics) in self.diagnostics.items():
        self.text_document_publish_diagnostics(
            types.PublishDiagnosticsParams(
                uri=uri,
                version=version,
                diagnostics=diagnostics,
            )
        )


PrologServer._publish_diagnostics = _publish_diagnostics


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    start_server(server)
