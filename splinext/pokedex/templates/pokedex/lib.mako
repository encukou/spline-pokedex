<%! from splinext.pokedex import i18n %>\

<%def name="pokemon_icon(pokemon)">\
% if pokemon.is_default:
<span class="sprite-icon sprite-icon-${pokemon.species.id}"></span>\
% else:
${h.pokedex.pokemon_form_image(pokemon.default_form, prefix='icons')}\
% endif
</%def>


<%def name="pokemon_page_header(icon_form=None)">
<div id="dex-header">
    <a href="${url.current(name=c.prev_pokemon.species.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${pokemon_icon(c.prev_pokemon)}
        ${c.prev_pokemon.species.id}: ${c.prev_pokemon.species.name}
    </a>
    <a href="${url.current(name=c.next_pokemon.species.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_pokemon.species.id}: ${c.next_pokemon.species.name}
        ${pokemon_icon(c.next_pokemon)}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${h.pokedex.pokemon_form_image(icon_form or c.pokemon.default_form, prefix='icons')}
    <br>${c.pokemon.species.id}: ${c.pokemon.species.name}
    <ul class="inline-menu">
    <% form = c.pokemon.default_form.form_identifier if not c.pokemon.is_default else None %>\
    % for action, label in (('pokemon', u'Pokédex'), \
                            ('pokemon_flavor', u'Flavor'), \
                            ('pokemon_locations', u'Locations')):
        % if action == request.environ['pylons.routes_dict']['action']:
        <li>${label}</li>
        % else:
        <li><a href="${url.current(action=action, form=form if action != 'pokemon_locations' else None)}">${label}</a></li>
        % endif
    % endfor
    </ul>
</div>
</%def>


## Pretty-prints a version group selector, arranged by generation
<%def name="pretty_version_group_field(field, generations)">
<% version_group_controls = dict((control.data, control) for control in field) %>\
<table id="dex-pokemon-search-move-versions">
    % for generation in generations:
    <tr>
        % for version_group in generation.version_groups:
        <td>
            ${version_group_controls[ unicode(version_group.id) ]()}
            ${version_group_controls[ unicode(version_group.id) ].label()}
        </td>
        % endfor
    </tr>
    % endfor
</table>
% for error in field.errors:
<p class="error">${error}</p>
% endfor
</%def>


###### Common tables
<%def name="pokemon_move_table_column_header(column)">
<th class="version">
  % if len(column) == len(column[0].generation.version_groups):
    ## If the entire gen has been collapsed into a single column, just show
    ## the gen icon instead of the messy stack of version icons
    ${h.pokedex.generation_icon(column[0].generation)}
  % else:
    % for i, version_group in enumerate(column):
    % if i != 0:
    <br>
    % endif
    ${h.pokedex.version_icons(*version_group.versions)}
    % endfor
  % endif
</th>
</%def>


## Given a method and some data, returns a cell indicating in some useful
## manner how a move is learned.
## Makes some use of c.move_tutor_version_groups, if it exists.
## XXX How to sort these "correctly"...?
## XXX How to sort these "correctly"...?
<%def name="pokemon_move_table_method_cell(column, method, version_group_data)">
<% version_group = column[0] %>\
% if method.name == 'Tutor' and c.move_tutor_version_groups:
<td class="tutored">
  ## Tutored moves never ever collapse!  Have to merge all the known values,
  ## rather than ignoring all but the first
  % for version_group in column:
    % if version_group in version_group_data:
    ${h.pokedex.version_icons(*version_group.versions)}
    % elif version_group in c.move_tutor_version_groups:
    <span class="no-tutor">${h.pokedex.version_icons(*version_group.versions)}</span>
    % endif
  % endfor
</td>
% elif version_group not in version_group_data:
## Could be an empty hash, in which case it's here but has no metadata
<td></td>
% elif method.name == 'Level up':
<td>
  % if version_group_data[version_group]['level'] == 1:
    —
  % else:
    ${version_group_data[version_group]['level']}
  % endif
</td>
% elif method.name == 'Machine':
<% machine_number = version_group_data[version_group]['machine'] %>\
<td>
  % if machine_number > 100:
  ## HM
    <strong>H</strong>${machine_number - 100}
  % else:
    ${"%02d" % machine_number}
  % endif
</td>
% elif method.name == 'Egg':
<td class="dex-moves-egg">${h.pokedex.chrome_img('egg-cropped.png', alt=u"&bull;")}</td>
% else:
<td>&bull;</td>
% endif
</%def>


<%def name="pokemon_table_columns()">
<col class="dex-col-icon">
<col class="dex-col-name">
<col class="dex-col-type2">
<col class="dex-col-ability">
<col class="dex-col-gender">
<col class="dex-col-egg-group">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat-total">
</%def>

<%def name="pokemon_table_header()">
<th></th>
<th>Pokémon</th>
<th>Type</th>
<th>Ability</th>
<th>Gender</th>
<th>Egg Group</th>
<th><abbr title="Hit Points">HP</abbr></th>
<th><abbr title="Attack">Atk</abbr></th>
<th><abbr title="Defense">Def</abbr></th>
<th><abbr title="Special Attack">SpA</abbr></th>
<th><abbr title="Special Defense">SpD</abbr></th>
<th><abbr title="Speed">Spd</abbr></th>
<th>Total</th>
</%def>

<%def name="_pokemon_ability_link(ability)">
<a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a>
</%def>

<%def name="pokemon_table_row(pokemon)">
<td class="icon">${pokemon_icon(pokemon)}</td>
<td>${h.pokedex.pokemon_link(pokemon)}</td>
<td class="type2">
    % for type in pokemon.types:
    ${h.pokedex.type_link(type)}
    % endfor
</td>
<td class="ability">
  % for i, ability in enumerate(pokemon.abilities):
    % if i > 0:
    <br />
    % endif
    ${_pokemon_ability_link(ability)}
  % endfor
  % if pokemon.dream_ability and pokemon.dream_ability not in pokemon.abilities:
    <br />
    <em>${_pokemon_ability_link(pokemon.dream_ability)}</em>
  % endif
</td>
<td>${h.pokedex.chrome_img('gender-rates/%d.png' % pokemon.species.gender_rate, alt=h.pokedex.gender_rate_label[pokemon.species.gender_rate])}</td>
<td class="egg-group">
  % for i, egg_group in enumerate(pokemon.species.egg_groups):
    % if i > 0:
    <br>
    % endif
    ${egg_group.name}
  % endfor
</td>
% for pokemon_stat in pokemon.stats:
<td class="stat stat-${pokemon_stat.stat.name.lower().replace(u' ', u'-')}">${pokemon_stat.base_stat}</td>
% endfor
<td>${sum((pokemon_stat.base_stat for pokemon_stat in pokemon.stats))}</td>
</%def>


<%def name="move_table_columns()">
<col class="dex-col-name">
<col class="dex-col-type">
<col class="dex-col-type">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-effect">
</%def>

<%def name="move_table_header(gen_instead_of_type=False)">
<th>Move</th>
% if gen_instead_of_type:
<th>Gen</th>
% else:
<th>Type</th>
% endif
<th>Class</th>
<th>PP</th>
<th>Power</th>
<th>Acc</th>
<th>Pri</th>
<th>Effect</th>
</%def>

<%def name="move_table_row(move, gen_instead_of_type=False, pp_override=None)">
<td><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></td>
% if gen_instead_of_type:
## Done on type pages; we already know the type, so show the generation instead
<td class="type">${h.pokedex.generation_icon(move.generation)}</td>
% else:
<td class="type">${h.pokedex.type_link(move.type)}</td>
% endif
<td class="class">${h.pokedex.damage_class_icon(move.damage_class)}</td>
<td>
    % if pp_override and pp_override != move.pp:
    <s>${move.pp}</s> <br> ${pp_override}
    % else:
    ${move.pp or u'—'}
    % endif
</td>
<td>
    % if move.power == 0:
    —
    % elif move.power == 1:
    *
    % else:
    ${move.power}
    % endif
</td>
<td>
    % if move.accuracy is None:
    —
    % else:
    ${move.accuracy}%
    % endif
</td>
## Priority is colored red for slow and green for fast
% if move.priority == 0:
<td></td>
% elif move.priority > 0:
<td class="dex-priority-fast">${move.priority}</td>
% else:
<td class="dex-priority-slow">${move.priority}</td>
% endif
<td class="markdown effect">${move.short_effect}</td>
</%def>

<%def name="move_table_blank_row()">
<td>&mdash;</td>
<td colspan="7"></td>
</%def>

###### Miscellaneous flavour presentation

<%def name="flavor_text_list(flavor_text, classes='')">
<%
obdurate = session.get('cheat_obdurate', False)
collapse_key = h.pokedex.collapse_flavor_text_key(literal=obdurate)
%>
<dl class="dex-flavor-text${' ' if classes else ''}${classes}">
% for generation, group in h.pokedex.group_by_generation(flavor_text):
% if generation:
<dt class="dex-flavor-generation">${h.pokedex.generation_icon(generation)}</dt>
<dd>
  <dl>
  % for versions, text in h.pokedex.collapse_versions(group, key=collapse_key):
    <dt>${h.pokedex.version_icons(*versions)}</dt>
    <dd><p${' class="dex-obdurate"' if obdurate else '' |n}>${text}</p></dd>
  % endfor
  </dl>
</dd>
% else:
% for versions, text in h.pokedex.collapse_versions(group, key=collapse_key):
<p class="dex-flavor-text${' ' if classes else ''}${classes}${' dex-obdurate' if obdurate else ''}">${text}</p>
% endfor
% endif
% endfor
</dl>
</%def>

<%def name="pokemon_cry(pokemon)">
<%
# Shaymin (and nothing else) has different cries for its different forms
if pokemon.species.id != 492:
    pokemon = pokemon.species.default_pokemon
cry_url = url(controller='dex', action='media', path=h.pokedex.pokemon_media_path(
    pokemon, 'cries', 'ogg'))
%>
<audio src="${cry_url}" controls preload="auto" class="cry">
    <!-- Totally the best fallback -->
    <a href="${cry_url}">${_('Download')}</a>
</audio>
</%def>

<%def name="subtle_search(**kwargs)">
    <% _ = kwargs.pop('_', unicode) %>
    <a href="${url(controller='dex_search', **kwargs)}"
        class="dex-subtle-search-link">
        <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="${_('Search: ')}" title="${_('Search')}">
    </a>
</%def>

<%def name="foreign_names(object, name_attr='name')">
    <dl>
        % for language, foreign_name in h.keysort(getattr(object, name_attr + '_map'), lambda lang: lang.order):
        % if language != c.game_language and foreign_name:
        ## </dt> needs to come right after the flag or else there's space between it and the colon
        <dt>${language.name}
        <img src="${h.static_uri('spline', "flags/{0}.png".format(language.iso3166))}" alt=""></dt>
        % if language.identifier == 'ja':
        <dd>${foreign_name} (${h.pokedex.romanize(foreign_name)})</dd>
        % else:
        <dd>${foreign_name}</dd>
        % endif
        % endif
        % endfor
    </dl>
</%def>
