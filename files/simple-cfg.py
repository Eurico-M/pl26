import logging

import ply.lex as lex
import ply.yacc as yacc
from lsprotocol import types
from pygls.cli import start_server
from pygls.lsp.server import LanguageServer
from pygls.workspace import TextDocument

DEBUG = True

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


class PublishDiagnosticServer(LanguageServer):
    """Language server demonstrating "push-model" diagnostics."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.diagnostics = {}

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
