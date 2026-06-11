import logging
import re

from lsprotocol import types
from pygls.cli import start_server
from pygls.lsp.server import LanguageServer
from pygls.workspace import TextDocument

FACT = re.compile(r"^\s*([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*\.$")
RULE = re.compile(
    r"^\s*([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*\:\-\s*(([a-z]\w*)\(((\s*\w+\s*\,*\s*)+)\)\s*[\,\;]?\s*)+\.$"
)


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
