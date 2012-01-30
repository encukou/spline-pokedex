# encoding: utf8
import os.path
from pkg_resources import resource_filename

from pylons import config, tmpl_context as c
from routes import url_for as url
from sqlalchemy.orm.exc import MultipleResultsFound, NoResultFound

import pokedex.db
import pokedex.db.tables as tables
import pokedex.lookup
import spline.lib.markdown
import splinext.pokedex.model
import splinext.pokedex.db
from splinext.pokedex import helpers as pokedex_helpers
import spline.lib.helpers as h
from spline.lib.plugin import PluginBase, PluginLink, Priority
from splinext.pokedex import i18n
from spline.lib.base import BaseController


DEFAULT_LANGUAGE = u'en'

def add_routes_hook(map, *args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""

    def connect(*args, **kwargs):
        kwargs.setdefault('i18n_class', i18n.Translator)
        map.connect(*args, **kwargs)

    connect('/dex/media/*path', controller='dex', action='media')
    connect('/dex/lookup', controller='dex', action='lookup')
    connect('/dex/suggest', controller='dex', action='suggest')
    connect('/dex/parse_size', controller='dex', action='parse_size')

    # These are more specific than the general pages below, so must be first
    connect('/dex/moves/search', controller='dex_search', action='move_search')
    connect('/dex/pokemon/search', controller='dex_search', action='pokemon_search')

    connect('/dex/abilities/{name}', controller='dex', action='abilities')
    connect('/dex/items/{pocket}', controller='dex', action='item_pockets')
    connect('/dex/items/{pocket}/{name}', controller='dex', action='items')
    connect('/dex/locations/{name}', controller='dex', action='locations')
    connect('/dex/moves/{name}', controller='dex', action='moves')
    connect('/dex/natures/{name}', controller='dex', action='natures')
    connect('/dex/pokemon/{name}', controller='dex', action='pokemon')
    connect('/dex/pokemon/{name}/flavor', controller='dex', action='pokemon_flavor')
    connect('/dex/pokemon/{name}/locations', controller='dex', action='pokemon_locations')
    connect('/dex/types/{name}', controller='dex', action='types')

    connect('/dex/abilities', controller='dex', action='abilities_list')
    connect('/dex/items', controller='dex', action='items_list')
    connect('/dex/locations', controller='dex', action='locations_list')
    connect('/dex/natures', controller='dex', action='natures_list')
    connect('/dex/moves', controller='dex', action='moves_list')
    connect('/dex/pokemon', controller='dex', action='pokemon_list')
    connect('/dex/types', controller='dex', action='types_list')

    connect('/dex/gadgets/chain_breeding', controller='dex_gadgets', action='chain_breeding')
    connect('/dex/gadgets/compare_pokemon', controller='dex_gadgets', action='compare_pokemon')
    connect('/dex/gadgets/pokeballs', controller='dex_gadgets', action='capture_rate')
    connect('/dex/gadgets/stat_calculator', controller='dex_gadgets', action='stat_calculator')
    connect('/dex/gadgets/whos_that_pokemon', controller='dex_gadgets', action='whos_that_pokemon')

    # JSON API
    connect('/dex/api/pokemon', controller='dex_api', action='pokemon')

class PokedexBaseController(BaseController):
    def __before__(self, action, **params):
        super(PokedexBaseController, self).__before__(action, **params)

        identifier_query = splinext.pokedex.db.get_by_identifier_query
        c.game_language = identifier_query(tables.Language, DEFAULT_LANGUAGE).one()
        try:
            c.language = identifier_query(tables.Language, c.lang or DEFAULT_LANGUAGE).one()
        except NoResultFound:
            c.language = c.game_language

        db.pokedex_session.default_language_id = c.game_language.id

    def __call__(self, *args, **params):
        """Run the controller, making sure to discard the Pokédex session when
        we're done.

        Stolen from the default Pylons lib.base.__call__.
        """
        try:
            return super(PokedexBaseController, self).__call__(*args, **params)
        finally:
            db.pokedex_session.remove()


### Extend markdown to turn [Eevee]{pokemon:eevee} into a link in effects and
### descriptions

import pokedex.db.markdown
class SplineExtension(pokedex.db.markdown.PokedexLinkExtension):
    def object_url(self, category, obj):
        return pokedex_helpers.make_thingy_url(obj)

def after_setup_hook(config, *args, **kwargs):
    """Hook to do some housekeeping after the app starts."""
    # Connect to the database
    splinext.pokedex.db.connect(config)
    session = splinext.pokedex.db.pokedex_session

    # Extend the pokedex code's default markdown rendering
    session.configure(markdown_extension_class=SplineExtension)

    # And extend spline's markdowning, to make it available to forums etc.
    spline.lib.markdown.register_extension(SplineExtension(session))


def before_controller_hook(*args, **kwargs):
    """Hook to inject suggestion-box Javascript into every page."""
    c.javascripts.append(('pokedex', 'pokedex-suggestions'))


class PokedexPlugin(PluginBase):
    def __init__(self, *args, **kwargs):
        """Stuff our helper module in the Pylons h object."""
        super(PokedexPlugin, self).__init__(*args, **kwargs)

        # XXX should we really be doing this here?
        h.pokedex = pokedex_helpers

    def controllers(self):
        import splinext.pokedex.controllers.pokedex
        import splinext.pokedex.controllers.pokedex_api
        import splinext.pokedex.controllers.pokedex_search
        import splinext.pokedex.controllers.pokedex_gadgets

        return {
            'dex': controllers.pokedex.PokedexController,
            'dex_api': controllers.pokedex_api.PokedexAPIController,
            'dex_search': controllers.pokedex_search.PokedexSearchController,
            'dex_gadgets': controllers.pokedex_gadgets.PokedexGadgetsController,
        }

    def hooks(self):
        return [
            ('routes_mapping',    Priority.NORMAL, add_routes_hook),
            ('after_setup',       Priority.NORMAL, after_setup_hook),
            ('before_controller', Priority.NORMAL, before_controller_hook),
        ]

    def links(self):
        _ = unicode  # _ is a no-op here, only used for marking the texts for translation
        # Wrap PluginLink do that the correct translator is given
        # (Unfortunately it's too early in the bootstrapping process to actually translate now)
        def TranslatablePluginLink(*args, **kwargs):
            kwargs.setdefault('translator_class', i18n.Translator)
            return PluginLink(*args, **kwargs)
        # All good, return the structure now
        return [
            TranslatablePluginLink(_(u'Pokédex'), url('/dex'), children=[
                TranslatablePluginLink(_(u'Core pages'), None, children=[
                    TranslatablePluginLink(_(u'Pokémon'), url(controller='dex', action='pokemon_list'), i18n_context='plural', children=[
                        TranslatablePluginLink(_(u'Awesome search'), url(controller='dex_search', action='pokemon_search')),
                    ]),
                    TranslatablePluginLink(_(u'Moves'), url(controller='dex', action='moves_list'), children=[
                        TranslatablePluginLink(_(u'Awesome search'), url(controller='dex_search', action='move_search')),
                    ]),
                    TranslatablePluginLink(_(u'Types'), url(controller='dex', action='types_list')),
                    TranslatablePluginLink(_(u'Abilities'), url(controller='dex', action='abilities_list')),
                    TranslatablePluginLink(_(u'Items'), url(controller='dex', action='items_list')),
                    TranslatablePluginLink(_(u'Natures'), url(controller='dex', action='natures_list')),
                ]),
                TranslatablePluginLink(_(u'Gadgets'), None, children=[
                    TranslatablePluginLink(_(u'Compare Pokémon'), url(controller='dex_gadgets', action='compare_pokemon')),
                    TranslatablePluginLink(_(u'Pokéball performance'), url(controller='dex_gadgets', action='capture_rate')),
                    TranslatablePluginLink(_(u'Stat calculator'), url(controller='dex_gadgets', action='stat_calculator')),
                ]),
                TranslatablePluginLink(_(u'Etc.'), None, children=[
                    TranslatablePluginLink(_(u'Downloads'), url('/dex/downloads')),
                ]),
            ]),
        ]

    def widgets(self):
        return [
            ('page_header', Priority.NORMAL, 'widgets/pokedex_lookup.mako'),
            ('head_tag',    Priority.NORMAL, 'widgets/pokedex_suggestion_css.mako'),
        ]
