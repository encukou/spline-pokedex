<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import db %>\
<%! import re %>\

<%def name="title()">${c.pokemon.full_name} - Pokémon #${c.pokemon.normal_form.id}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li><a href="${url(controller='dex', action='pokemon_list')}">Pokémon</a></li>
    <li>${c.pokemon.full_name}</li>
</ul>
</%def>

${dexlib.pokemon_page_header()}


<%lib:cache_content>
${h.h1('Essentials')}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.pokemon.name}</p>
    % if c.pokemon.form_name:
    <p id="dex-pokemon-forme">${c.pokemon.unique_form.full_name}</p>
    % endif
    <div id="dex-pokemon-portrait-sprite">
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white')}
    </div>
    <p id="dex-page-types">
        % for type in c.pokemon.types:
        ${h.pokedex.type_link(type)}
        % endfor
    </p>
</div>

<div class="dex-page-beside-portrait">
<h2>Abilities</h2>
<%def name="_render_ability(ability)">
    <dt><a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a></dt>
    <dd class="markdown">${ability.short_effect.as_html | n}</dd>
</%def>
<dl class="pokemon-abilities">
    % for ability in c.pokemon.abilities:
    ${_render_ability(ability)}
    % endfor
</dl>
% if c.pokemon.dream_ability:
<h3>Dream Ability</h3>
<dl class="pokemon-abilities">
    ${_render_ability(c.pokemon.dream_ability)}
</dl>
% endif

<h2>Damage Taken</h2>
## Boo not using <dl>  :(  But I can't get them to align horizontally with CSS2
## if the icon and value have no common element..
<ul class="dex-type-list">
    % for type, damage_factor in h.keysort(c.type_efficacies, lambda k: k.name):
    <li class="dex-damage-taken-${damage_factor}">
        ${h.pokedex.type_link(type)} ${h.pokedex.type_efficacy_label[damage_factor]}
    </li>
    % endfor
</ul>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Pokédex Numbers</h2>
    <dl>
        <dt>Introduced in</dt>
        <dd>${h.pokedex.generation_icon(c.pokemon.generation)}</dd>\

        % for number in c.pokemon.normal_form.dex_numbers:
        <dt>${number.pokedex.name}</dt>
        <dd>
            ${number.pokedex_number}
            % if number.pokedex.version_groups:
            ${h.pokedex.version_icons(*[v for vg in number.pokedex.version_groups for v in vg.versions])}
            % endif
        </dd>

        % endfor
    </dl>

    <h2>Names</h2>
    <dl>
        % for foreign_name in c.pokemon.normal_form.foreign_names:
        ## </dt> has to come right after the flag or else there's space between the flag and the colon
        <dt>${foreign_name.language.name}
        <img src="${h.static_uri('spline', "flags/{0}.png".format(foreign_name.language.iso3166))}" alt=""></dt>
        % if foreign_name.language.name == 'Japanese':
        <dd>${foreign_name.name} (${h.pokedex.romanize(foreign_name.name)})</dd>
        % else:
        <dd>${foreign_name.name}</dd>
        % endif
        % endfor
    </dl>
</div>
<div class="dex-column">
    <h2>Breeding</h2>
    <dl>
        <dt>Gender</dt>
        <dd>
            ${h.pokedex.pokedex_img('gender-rates/%d.png' % c.pokemon.gender_rate, alt='')}
            ${h.pokedex.gender_rate_label[c.pokemon.gender_rate]}
            <a href="${url(controller='dex_search', action='pokemon_search', gender_rate=c.pokemon.gender_rate)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Egg groups</dt>
        <dd>
            <ul class="inline-commas">
                % for i, egg_group in enumerate(c.pokemon.egg_groups):
                <li>${egg_group.name}</li>
                % endfor
            </ul>
            % if len(c.pokemon.egg_groups) > 1:
            <a href="${url(controller='dex_search', action='pokemon_search', egg_group=[_.id for _ in c.pokemon.egg_groups])}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="">
            </a>
            % endif
        </dd>

        <dt>Hatch counter</dt>
        <dd>
            ${c.pokemon.hatch_counter}
            <a href="${url(controller='dex_search', action='pokemon_search', hatch_counter=c.pokemon.hatch_counter, sort='evolution-chain')}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Steps to hatch</dt>
        <dd>
            ${(c.pokemon.hatch_counter + 1) * 255} /

            ## If any party Pokémon has Magma Armor or Flame Body, hatch counters go down by two (instead of one) every 255 steps.
            ## Then there's the final lap after the egg hits zero.  So, for MA/FB steps: (ceil(counter / 2.0) + 1) * 255
            ## ceil() returns a float, but we can avoid a messy int(ceil(...)) like so: ceil(x / 2.0) == floor((x + 1) / 2.0) == (x + 1) // 2
            ## And thus: (ceil(x / 2.0) + 1) * 255 == ((x + 1) // 2 + 1) * 255 == (x + 3) // 2 * 255
            <span class="annotation" title="With Magma Armor or Flame Body">${(c.pokemon.hatch_counter + 3) // 2 * 255}</span>
        </dd>
    </dl>

    <h2>Compatibility</h2>
    % if c.pokemon.egg_groups[0].id == 13:
    ## Egg group 13 is the special Ditto group
    <p>Ditto can breed with any other breedable Pokémon, but can never produce a Ditto egg.</p>
    % elif c.pokemon.egg_groups[0].id == 15:
    ## Egg group 15 is the special No Eggs group
    <p>${c.pokemon.name} cannot breed.</p>
    % else:
    <ul class="inline dex-pokemon-compatibility">
        % for pokemon in c.compatible_families:
        <li>${h.pokedex.pokemon_link(
            pokemon,
            h.literal(capture(dexlib.pokemon_icon, pokemon)),
            form=None,
            class_='dex-icon-link',
            title=pokemon.name,
        )}</li>
        % endfor
    </ul>
    % endif
</div>
<div class="dex-column">
    <h2>Training</h2>
    <dl>
        <dt>Base EXP</dt>
        <dd>
            <span id="dex-pokemon-exp-base">${c.pokemon.base_experience}</span>
            <a href="${url(controller='dex_search', action='pokemon_search', base_experience=c.pokemon.base_experience)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
            <br/>
            <span id="dex-pokemon-exp">${h.pokedex.formulae.earned_exp(base_exp=c.pokemon.base_experience, level=100)}</span> EXP
            at level <input type="text" size="3" value="100" id="dex-pokemon-exp-level">
        </dd>
        <dt>Effort points</dt>
        <dd>
            <ul>
                % for pokemon_stat in c.pokemon.stats:
                % if pokemon_stat.effort:
                <li>${pokemon_stat.effort} ${pokemon_stat.stat.name}</li>
                % endif
                % endfor
            </ul>
        </dd>
        <dt>Capture rate</dt>
        <dd>
            ${c.pokemon.capture_rate}
            <a href="${url(controller='dex_search', action='pokemon_search', capture_rate=c.pokemon.capture_rate)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        <dt>Base happiness</dt>
        <dd>
            ${c.pokemon.base_happiness}
            <a href="${url(controller='dex_search', action='pokemon_search', base_happiness=c.pokemon.base_happiness)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        <dt>Growth rate</dt>
        <dd>
            ${c.pokemon.evolution_chain.growth_rate.name}
            <a href="${url(controller='dex_search', action='pokemon_search', growth_rate=c.pokemon.evolution_chain.growth_rate.max_experience)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
    </dl>

    <h2>Wild held items</h2>
    <table class="dex-pokemon-held-items striped-row-groups">
    % for generation, version_dict in h.keysort(c.held_items, lambda k: k.id):
    <tbody>
    % for versions, item_records in h.keysort(version_dict, lambda k: k[0].id):
    <tr class="new-version">
      % for i in range(len(item_records) or 1):
        % if i == 0:
        <td class="versions" rowspan="${len(item_records) or 1}">
            % if len(version_dict) == 1:
            ${h.pokedex.generation_icon(generation)}
            % else:
            ${h.pokedex.version_icons(*versions)}
            % endif
        </td>
        % else:
    </tr>
    <tr>
        % endif

        ## Print the item and rarity.  Might be nothing
        % if i < len(item_records):
        <td class="rarity">${item_records[i][1]}%</td>
        <td class="item">${h.pokedex.item_link(item_records[i][0])}</td>
        % else:
        <td class="rarity"></td>
        <td class="item">nothing</td>
        % endif
      % endfor
    </tr>
    % endfor
    </tbody>
    % endfor
    </table>
</div>
</div>

${h.h1('Evolution')}
<ul class="see-also">
<li>
    <img src="${h.static_uri('spline', 'icons/chart--arrow.png')}" alt="See also:">
    <a href="${url(controller='dex_gadgets', action='compare_pokemon',
        pokemon=[pokemon.full_name for pokemon in c.pokemon.evolution_chain.pokemon]
        )}">Compare this family</a>
</li>
</ul>

<table class="dex-evolution-chain">
<thead>
<tr>
    <th>Baby</th>
    <th>Basic</th>
    <th>Stage 1</th>
    <th>Stage 2</th>
</tr>
</thead>
<tbody>
% for row in c.evolution_table:
<tr>
    % for col in row:
    ## Empty cell
    % if col == '':
    <td></td>
    % elif col != None:
    <td rowspan="${col['span']}"\
        % if col['pokemon'] == c.pokemon.normal_form:
        ${h.literal(' class="selected"')}\
        % endif
    >
        % if col['pokemon'] == c.pokemon:
        <span class="dex-evolution-chain-pokemon">
            ${dexlib.pokemon_icon(col['pokemon'])}
            ${col['pokemon'].name}
        </span>
        % else:
        ${h.pokedex.pokemon_link(
            pokemon=col['pokemon'],
            content=h.literal(capture(dexlib.pokemon_icon, col['pokemon']))
                   + col['pokemon'].name,
            class_='dex-evolution-chain-pokemon',
        )}
        % endif
        % if col['pokemon'].parent_evolution:
        <span class="dex-evolution-chain-method">
            ${h.pokedex.evolution_description(col['pokemon'].parent_evolution)}
        </span>
        % elif col['pokemon'].is_baby and c.pokemon.evolution_chain.baby_trigger_item:
        <span class="dex-evolution-chain-method">
            Either parent must hold ${h.pokedex.item_link(c.pokemon.evolution_chain.baby_trigger_item, include_icon=False)}
        </span>
        % endif
    </td>
    % endif
    % endfor
</tr>
% endfor
</tbody>
</table>
% if c.pokemon.normal_form.form_group:
<h2 id="forms"> <a href="#forms" class="subtle">${c.pokemon.name} Forms</a> </h2>
<ul class="inline">
    % for form in c.pokemon.normal_form.forms:
<%
    link_class = 'dex-box-link'
    if form == c.pokemon.unique_form:
        link_class = link_class + ' selected'
%>\
    <li>${h.pokedex.pokemon_link(c.pokemon, h.pokedex.pokemon_sprite(form, 'black-white'), form=form.name, class_=link_class)}</li>
    % endfor
</ul>
<p> ${c.pokemon.normal_form.form_group.description.as_html | n} </p>
% endif

${h.h1('Stats')}
<%
    # Most people want to see the best they can get
    default_stat_level = 100
    default_stat_effort = 255
%>\
<table class="dex-pokemon-stats">
<colgroup>
    <col class="dex-col-stat-name">
    <col class="dex-col-stat-bar">
    <col class="dex-col-stat-pctile">
</colgroup>
<colgroup>
    <col class="dex-col-stat-result">
    <col class="dex-col-stat-result">
</colgroup>
<thead>
    <tr>
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><!-- percentile --></th>
        <th><label for="dex-pokemon-stats-level">Level</label></th>
        <th><input type="text" size="3" value="${default_stat_level}" disabled="disabled" id="dex-pokemon-stats-level"></th>
    </tr>
    <tr>
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><!-- percentile --></th>
        <th><label for="dex-pokemon-stats-iv">Effort</label></th>
        <th><input type="text" size="3" value="${default_stat_effort}" disabled="disabled" id="dex-pokemon-stats-effort"></th>
    </tr>
    <tr class="header-row">
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><abbr title="Percentile rank">Pctile</abbr></th>
        <th>Min IVs</th>
        <th>Max IVs</th>
    </tr>
</thead>
<tbody>
    % for pokemon_stat in c.pokemon.stats:
<%
        stat_info = c.stats[pokemon_stat.stat.name]

        if pokemon_stat.stat.name == 'HP':
            stat_formula = h.pokedex.formulae.calculated_hp
        else:
            stat_formula = h.pokedex.formulae.calculated_stat
%>\
    <tr class="color1">
        <th>${pokemon_stat.stat.name}</th>
        <td>
            <div class="dex-pokemon-stats-bar-container">
                <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - stat_info['percentile']) * 100}%; background-color: ${stat_info['background']}; border-color: ${stat_info['border']};">${pokemon_stat.base_stat}</div>
            </div>
        </td>
        <td class="dex-pokemon-stats-pctile">${"%0.1f" % (stat_info['percentile'] * 100)}</td>
        <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=0, effort=default_stat_effort)}</td>
        <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=31, effort=default_stat_effort)}</td>
    </tr>
    % endfor
</tbody>
<tr class="color1">
    <th>Total</th>
    <td>
        <div class="dex-pokemon-stats-bar-container">
            <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - c.stats['total']['percentile']) * 100}%; background-color: ${c.stats['total']['background']}; border-color: ${c.stats['total']['border']};">${c.stats['total']['value']}</div>
        </div>
    </td>
    <td class="dex-pokemon-stats-pctile">${"%0.1f" % (c.stats['total']['percentile'] * 100)}</td>
    <td></td>
    <td></td>
</tr>
</table>

% if c.pokeathlon_stats:
${h.h2(h.pokedex.version_icons('HeartGold', 'SoulSilver') + u' Pokéathlon Performance', id='pokeathlon')}
<%
    star_buffed = h.pokedex.pokedex_img('chrome/pokeathlon-star-buffed.png', alt=u'★')
    star_base = h.pokedex.pokedex_img('chrome/pokeathlon-star.png', alt=u'✯')
    star_empty = h.pokedex.pokedex_img('chrome/pokeathlon-star-empty.png', alt=u'☆')
%>

<p>${star_buffed} Minimum; ${star_base} Base; ${star_empty} Maximum</p>

% for stat_set in c.pokeathlon_stats:
<div class="dex-pokeathlon-stats">
    ## Label for this set of stats, if any
    % if stat_set[0]:
    <p>${stat_set[0]}</p>
    % endif

    <dl>
        % for stat in stat_set[1]:
        <dt>${stat.pokeathlon_stat.name}</dt>
        <dd>${star_buffed * stat.minimum_stat}${star_base * (stat.base_stat - stat.minimum_stat)}${star_empty * (stat.maximum_stat - stat.base_stat)}</dd>
        % endfor

        <dt>Total</dt>
        <dd>${sum(stat.minimum_stat for stat in stat_set[1])}/${sum(stat.base_stat for stat in stat_set[1])}/${sum(stat.maximum_stat for stat in stat_set[1])}</dd>
    </dl>
</div>
% endfor
% endif

${h.h1('Flavor')}
<ul class="see-also">
<li> <img src="${h.static_uri('spline', 'icons/arrow-000-medium.png')}" alt="See also:"> <a href="${url.current(action='pokemon_flavor')}">Detailed flavor page covering all versions</a> </li>
</ul>

## Only showing current generation's sprites and text
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>Flavor Text</h2>
	<% flavor_text = filter(lambda text: text.version.generation.id == 4,
	                        c.pokemon.normal_form.flavor_text) %>
	${dexlib.flavor_text_list(flavor_text, 'dex-pokemon-flavor-text')}
</div>
<div class="dex-column">
    <h2>Sprites</h2>
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white')}
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/shiny')}
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back')}
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/shiny')}
    <br/>
    % if c.pokemon.has_gen4_fem_sprite:
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/female')}
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/shiny/female')}
    % endif
    % if c.pokemon.has_gen4_fem_back_sprite:
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/female')}
    ${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/shiny/female')}
    % endif
</div>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Miscellany</h2>
    <dl>
        <dt>Species</dt>
        <dd>
            ${c.pokemon.species}
            <a href="${url(controller='dex_search', action='pokemon_search', species=c.pokemon.species)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Color</dt>
        <dd>
            <span class="dex-color-${c.pokemon.color}"></span>
            ${c.pokemon.color}
            <a href="${url(controller='dex_search', action='pokemon_search', color=c.pokemon.color)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Cry</dt>
<%
        # Shaymin (and nothing else) has different cries for its different forms
        if c.pokemon.normal_form.id == 492:
            cry_path = 'cries/{0}-{1}.ogg'.format(c.pokemon.normal_form.id, c.pokemon.unique_form.name.lower())
        else:
            cry_path = 'cries/{0}.ogg'.format(c.pokemon.normal_form.id)

        cry_path = url(controller='dex', action='media', path=cry_path)
%>\
        <dd>
            <audio src="${cry_path}" controls preload="auto" class="cry">
                <!-- Totally the best fallback -->
                <a href="${cry_path}">Download</a>
            </audio>
        </dd>

        % if c.pokemon.generation.id <= 3:
        <dt>Habitat ${h.pokedex.version_icons(u'FireRed', u'LeafGreen')}</dt>
        <dd>
            ${h.pokedex.pokedex_img('chrome/habitats/%s.png' % h.pokedex.filename_from_name(c.pokemon.habitat))}
            ${c.pokemon.habitat}
            <a href="${url(controller='dex_search', action='pokemon_search', habitat=c.pokemon.habitat)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        % endif

        <dt>Footprint</dt>
        <dd>${h.pokedex.pokemon_sprite(c.pokemon, prefix='footprints', form=None)}</dd>

        % if c.pokemon.generation.id <= 4:
        <dt>Shape ${h.pokedex.generation_icon(4)}</dt>
        <dd>
            ${h.pokedex.pokedex_img('chrome/shapes/%d.png' % c.pokemon.shape.id, alt='', title=c.pokemon.shape.name)}
            ${c.pokemon.shape.awesome_name}
            <a href="${url(controller='dex_search', action='pokemon_search', shape=c.pokemon.shape.name.lower())}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        % endif
    </dl>
</div>
<div class="dex-column">
    <h2>Height</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.pokedex_img('chrome/trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.heights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_height_imperial(c.trainer_height)}" disabled="disabled" id="dex-pokemon-height">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.heights['pokemon'] * 100))}
            <div class="js-dex-size-raw">${c.pokemon.height}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_height_imperial(c.pokemon.height)} <br/>
                ${h.pokedex.format_height_metric(c.pokemon.height)}
            </p>
        </div>
    </div>
</div>
<div class="dex-column">
    <h2>Weight</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.pokedex_img('chrome/trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.weights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_weight_imperial(c.trainer_weight)}" disabled="disabled" id="dex-pokemon-weight">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.weights['pokemon'] * 100))}
            <div class="js-dex-size-raw">${c.pokemon.weight}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_weight_imperial(c.pokemon.weight)} <br/>
                ${h.pokedex.format_weight_metric(c.pokemon.weight)}
            </p>
        </div>
    </div>
</div>
</div>

${h.h1('Locations')}
<ul class="see-also">
<li> <img src="${h.static_uri('spline', 'icons/map--arrow.png')}" alt="See also:"> <a href="${url.current(action='pokemon_locations')}">Ridiculously detailed breakdown</a> </li>
</ul>

<dl class="dex-simple-encounters">
    ## Sort versions by order, which happens to be id
    % for version, terrain_etc in h.keysort(c.locations, lambda k: k.id):
    <dt>${version.name} ${h.pokedex.version_icons(version)}</dt>
    <dd>
        ## Sort terrain by name
        % for terrain, area_condition_encounters in h.keysort(terrain_etc, lambda k: k.id):
        <div class="dex-simple-encounters-terrain">
            ${h.pokedex.pokedex_img('encounters/' + c.encounter_terrain_icons.get(terrain.name, 'unknown.png'), \
                                    alt=terrain.name)}
            <ul>
                ## Sort locations by name
                % for location_area, (conditions, combined_encounter) \
                    in h.keysort(area_condition_encounters, lambda k: (k.location.name, k.name)):
                <li title="${combined_encounter.level} ${combined_encounter.rarity}% ${';'.join(_.name for _ in conditions)}">
                    <a href="${url(controller="dex", action="locations", name=location_area.location.name.lower())}${'#area:' + location_area.name if location_area.name else ''}">
                        ${location_area.location.name}${', ' + location_area.name if location_area.name else ''}
                    </a>
                </li>
                % endfor
            </ul>
        </div>
        % endfor
    </dd>
    % endfor
</dl>

${h.h1('Moves')}
<p>${u' and '.join(t.name for t in c.pokemon.types)} moves get STAB, and have their type highlighted in green.</p>
% if c.better_damage_class:
<p>${c.better_damage_class.name.capitalize()} moves better suit ${c.pokemon.full_name}'s higher ${u'Special Attack' if c.better_damage_class.name == u'special' else u'Attack'}, and have their class highlighted in green.</p>
% endif
<% columns = sum(c.move_columns, []) %>
<table class="dex-pokemon-moves dex-pokemon-pokemon-moves striped-rows">
## COLUMNS
% for column_group in c.move_columns:
<colgroup class="dex-colgroup-versions">
    % for column in column_group:
    <col class="dex-col-version">
    % endfor
</colgroup>
% endfor

<colgroup>\
    ${dexlib.move_table_columns()}\
</colgroup>

% for method, method_list in c.moves:
## HEADERS
<tbody>
<%
    method_id = "moves:" + h.sanitize_id(method.name)
%>\
    <tr class="header-row" id="${method_id}">
        % for column in columns:
            ${dexlib.pokemon_move_table_column_header(column)}
        % endfor
        ${dexlib.move_table_header()}
    </tr>
    <tr class="subheader-row">
        <th colspan="${len(columns) + 8}"><a href="#${method_id}" class="subtle"><strong>${method.name}</strong></a>: ${method.description}</th>
    </tr>
</tbody>
## DATA
<tbody>
% for move, version_group_data in method_list:
    <tr class="\
        % if move.type in c.pokemon.types:
        better-move-type\
        % endif
        % if move.damage_class == c.better_damage_class:
        better-move-stat\
        % endif
    ">
        % for column in columns:
        ${dexlib.pokemon_move_table_method_cell(column, method, version_group_data)}
        % endfor
        ${dexlib.move_table_row(move)}
    </tr>
% endfor
</tbody>
% endfor
</table>

${h.h1('External Links', id='links')}
<%
    # Some sites don't believe in Unicode URLs.  Scoff, scoff.
    # And they all do it differently.  Ugh, ugh.
    if c.pokemon.name == u'Nidoran♀':
        lp_name = 'Nidoran(f)'
        ghpd_name = 'nidoran_f'
        smogon_name = 'nidoran-f'
    elif c.pokemon.name == u'Nidoran♂':
        lp_name = 'Nidoran(m)'
        ghpd_name = 'nidoran_m'
        smogon_name = 'nidoran-m'
    else:
        lp_name = c.pokemon.name
        ghpd_name = re.sub(' ', '_', c.pokemon.name.lower())
        ghpd_name = re.sub('[^\w-]', '', ghpd_name)
        smogon_name = ghpd_name

    if not c.pokemon.is_base_form:
        if c.pokemon.form_name == 'Sandy':
            smogon_name += '-g'
        elif c.pokemon.form_name == 'Mow':
            smogon_name += '-c'
        elif c.pokemon.form_name in ('Fan', 'Trash'):
            smogon_name += '-s'
        else:
            smogon_name += '-' + c.pokemon.form_name[0].lower()
%>
<ul class="classic-list">
% if c.pokemon.generation.id <= 1:
<li>${h.pokedex.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/pokedex/species/${"%03d" % c.pokemon.normal_form.id}.htm">Azure Heights</a></li>
% endif
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${re.sub(' ', '_', c.pokemon.name)}_%28Pok%C3%A9mon%29">Bulbapedia</a></li>
% if c.pokemon.generation.id <= 2:
<li>${h.pokedex.generation_icon(2)} <a href="http://www.pokemondungeon.com/pokedex/${ghpd_name}.shtml">Gengar and Haunter's Pokémon Dungeon</a></li>
% endif
<li><a href="http://www.legendarypokemon.net/pokedex/${lp_name}">Legendary Pokémon</a></li>
<li><a href="http://www.psypokes.com/dex/psydex/${"%03d" % c.pokemon.normal_form.id}">PsyPoke</a></li>
<li><a href="http://www.serebii.net/pokedex-bw/${"%03d" % c.pokemon.normal_form.id}.shtml">Serebii.net</a></li>
<li><a href="http://www.smogon.com/dp/pokemon/${smogon_name}">Smogon</a></li>
</ul>
</%lib:cache_content>
