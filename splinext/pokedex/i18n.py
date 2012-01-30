# encoding: utf8

from spline.i18n import BaseTranslator, NullTranslator
from pokedex.db import markdown

class Translator(BaseTranslator):
    package = 'splinext.pokedex'
    domain = 'spline-pokedex'

    def text(self, texts):
        for language in [self.context.language, self.context.game_language]:
            if language in texts:
                return texts[language]
        identifier_query = splinext.pokedex.db.get_by_identifier_query
        default_language = identifier_query(tables.Language, DEFAULT_LANGUAGE).one()
        return texts[default_language]
