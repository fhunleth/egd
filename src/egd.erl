%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2008-2016. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%

%%
%% @doc egd - erlang graphical drawer
%%
%%

-module(egd).

-export([create/2, destroy/1, information/1]).
-export([text/5, line/4, color/1, color/2]).
-export([rectangle/4, filledRectangle/4, filledEllipse/4]).
-export([arc/4, arc/5]).
-export([render/1, render/2, render/3]).

-export([filledTriangle/5, polygon/3]).

-export([save/2]).

-include("egd.hrl").

%%==========================================================================
%% Type definitions
%%==========================================================================

-type egd_image() :: pid().
-type image_type() :: png | raw_bitmap | eps.
-type font() :: term().
%% Internal font representation returned by {@link egd_font:load/1} or
%% {@link egd_font:load_binary/1}

-type point() :: {X::non_neg_integer(), Y::non_neg_integer()}.
-type render_option() :: {'render_engine', 'opaque'} | {'render_engine', 'alpha'}.

-type color3() :: {Red::byte(), Green::byte(), Blue::byte()}.
-type color4() :: {Red::byte(), Green::byte(), Blue::byte(), Alpha::byte()}.
-type normalized_color() :: {float(), float(), float(), float()}.

-type colorNameSimple() :: aqua | black | blue | fuchia | gray | green | lime |
                           maroon | navy | olive | purple | red | silver | teal |
                           white | yellow.
%% HTML default colors

-type colorNameExtended() ::
        aliceblue | antiquewhite | aquamarine | azure | beige | bisque |
        blanchedalmond | blueviolet | brown | burlywood | cadetblue |
        chartreuse | chocolate | coral | cornflowerblue | cornsilk | crimson |
        cyan | darkblue | darkcyan | darkgoldenrod | darkgray | darkgreen |
        darkkhaki | darkmagenta | darkolivegreen | darkorange | darkorchid |
        darkred | darksalmon | darkseagreen | darkslateblue | darkslategray |
        darkturquoise | darkviolet | deeppink | deepskyblue | dimgray |
        dodgerblue | firebrick | floralwhite | forestgreen | fuchsia |
        gainsboro | ghostwhite | gold | goldenrod | greenyellow | honeydew |
        hotpink | indianred | indigo | ivory | khaki | lavender |
        lavenderblush | lawngreen | lemonchiffon | lightblue | lightcoral |
        lightcyan | lightgoldenrodyellow | lightgreen | lightgrey | lightpink |
        lightsalmon | lightseagreen | lightskyblue | lightslategray |
        lightsteelblue | lightyellow | limegreen | linen | magenta |
        mediumaquamarine | mediumblue | mediumorchid | mediumpurple |
        mediumseagreen | mediumslateblue | mediumspringgreen | mediumturquoise |
        mediumvioletred | midnightblue | mintcream | mistyrose | moccasin |
        navajowhite | oldlace | olivedrab | orange | orangered | orchid |
        palegoldenrod | palegreen | paleturquoise | palevioletred | papayawhip |
        peachpuff | peru | pink | plum | powderblue | rosybrown | royalblue |
        saddlebrown | salmon | sandybrown | seagreen | seashell | sienna |
        skyblue | slateblue | slategray | snow | springgreen | steelblue | tan |
        thistle | tomato | turquoise | violet | wheat | whitesmoke |
        yellowgreen.
%% HTML color extensions

-type colorName() :: colorNameSimple() | colorNameExtended().
-type color() :: color3() | color4() | colorName() |
                 {colorName(), Alpha::byte()}.

%%==========================================================================
%% Interface functions
%%==========================================================================

%% @doc Creates an image area and returns its reference.

-spec create(Width :: integer(), Height :: integer()) -> egd_image().

create(Width,Height) ->
    spawn_link(fun() -> init(trunc(Width),trunc(Height)) end).


%% @doc Destroys the image.

-spec destroy(Image :: egd_image()) -> ok.

destroy(Image) ->
   cast(Image, destroy).


%% @equiv render(Image, png, [{render_engine, opaque}])

-spec render(Image :: egd_image()) -> binary().

render(Image) ->
    render(Image, png, [{render_engine, opaque}]).

%% @equiv render(Image, Type, [{render_engine, opaque}])

-spec render(Image :: egd_image(), Type :: image_type()) -> binary().

render(Image, Type) ->
    render(Image, Type, [{render_engine, opaque}]).

%% @doc Renders a binary from the primitives specified by egd_image(). The
%% 	binary can either be a raw bitmap with rgb triplets or a binary in png
%%	format.

-spec render(Image :: egd_image(),
             Type :: image_type(),
             Options :: [render_option()]) -> binary().

render(Image, Type, Options) ->
    {render_engine, RenderType} = proplists:lookup(render_engine, Options),
    call(Image, {render, Type, RenderType}).


%% @hidden
%% @doc Writes out information about the image. This is a debug feature
%%	mainly.

-spec information(Image :: egd_image()) -> ok.

information(Pid) ->
    cast(Pid, information).

%% @doc Creates a line object from P1 to P2 in the image.

-spec line(Image :: egd_image(),
           Point1 :: point(),
           Point2 :: point(),
           Color :: normalized_color()) -> ok.

line(Image, P1, P2, Color) ->
    cast(Image, {line, P1, P2, Color}).

%% @doc Converts an RGB, RGBA, or named color to EGD's normalized RGBA form
%%
%% <h2>Examples</h2>
%%
%% <pre>
%% Red = egd:color({255, 0, 0}).
%% SemiTransparentBlue = egd:color({0, 0, 255, 128}).
%% Green = egd:color(green).
%% SemiTransparentGold = egd:color({gold, 128}).
%% </pre>
%%
%% See <a href="#t:colorName/0">t:colorName/0</a> for named color atoms.
%%

-spec color(Color :: color()) -> normalized_color().

color(Color) ->
    egd_primitives:color(Color).

%% @doc Creates a color reference.
%% @hidden

-spec color(_Image :: egd_image(), Color :: color()) -> normalized_color().

color(_Image, Color) ->
    egd_primitives:color(Color).

%% @doc Creates a text object.

-spec text(Image :: egd_image(),
           Point :: point(),
           Font :: font(),
           Text :: unicode:chardata(),
           Color :: normalized_color()) -> ok.

text(Image, P, Font, Text, Color) when is_binary(Text) ->
    cast(Image, {text, P, Font, unicode:characters_to_list(Text), Color});
text(Image, P, Font, Text, Color) ->
    cast(Image, {text, P, Font, Text, Color}).

%% @doc Creates a rectangle object.

-spec rectangle(Image :: egd_image(),
                Point1 :: point(),
                Point2 :: point(),
                Color :: normalized_color()) -> ok.

rectangle(Image, P1, P2, Color) ->
    cast(Image, {rectangle, P1, P2, Color}).

%% @doc Creates a filled rectangle object.

-spec filledRectangle(Image :: egd_image(),
                      Point1 :: point(),
                      Point2 :: point(),
                      Color :: normalized_color()) -> ok.

filledRectangle(Image, P1, P2, Color) ->
    cast(Image, {filled_rectangle, P1, P2, Color}).

%% @doc Creates a filled ellipse object.

-spec filledEllipse(Image :: egd_image(),
                    Point1 :: point(),
                    Point2 :: point(),
                    Color :: normalized_color()) -> ok.

filledEllipse(Image, P1, P2, Color) ->
    cast(Image, {filled_ellipse, P1, P2, Color}).

%% @hidden
%% @doc Creates a filled triangle object.

-spec filledTriangle(Image :: egd_image(),
                     Point1 :: point(),
                     Point2 :: point(),
                     Point3 :: point(),
                     Color :: normalized_color()) -> ok.

filledTriangle(Image, P1, P2, P3, Color) ->
    cast(Image, {filled_triangle, P1, P2, P3, Color}).

%% @hidden
%% @doc Creates a filled filled polygon object.

-spec polygon(Image :: egd_image(), Points :: [point()], Color :: normalized_color()) -> ok.

polygon(Image, Pts, Color) ->
    cast(Image, {polygon, Pts, Color}).

%% @hidden
%% @doc Creates an arc with radius of bbx corner.

-spec arc(Image :: egd_image(),
          Point1 :: point(),
          Point2 :: point(),
          Color :: normalized_color()) -> ok.

arc(Image, P1, P2, Color) ->
    cast(Image, {arc, P1, P2, Color}).

%% @hidden
%% @doc Creates an arc.

-spec arc(Image :: egd_image(),
          Point1 :: point(),
          Point2 :: point(),
          Radius :: integer(),
          Color :: normalized_color()) -> ok.

arc(Image, P1, P2, D, Color) ->
    cast(Image, {arc, P1, P2, D, Color}).

%% @doc Saves the binary to file.

-spec save(RenderedImage :: binary(), Filename :: string()) -> ok.

save(Binary, Filename) when is_binary(Binary) ->
    ok = file:write_file(Filename, Binary),
    ok.
% ---------------------------------
% Aux functions
% ---------------------------------

cast(Pid, Command) ->
    Pid ! {egd, self(), Command},
    ok.

call(Pid, Command) ->
    Pid ! {egd, self(), Command},
    receive {egd, Pid, Result} -> Result end.

% ---------------------------------
% Server loop
% ---------------------------------

init(W,H) ->
    Image = egd_primitives:create(W,H),
    loop(Image).

loop(Image) ->
    receive
	% Quitting
	{egd, _Pid, destroy} -> ok;

	% Rendering
    	{egd, Pid, {render, BinaryType, RenderType}} ->
	    case BinaryType of
		raw_bitmap ->
		    Bitmap = egd_render:binary(Image, RenderType),
		    Pid ! {egd, self(), Bitmap},
		    loop(Image);
		eps ->
		    Eps = egd_render:eps(Image),
		    Pid ! {egd, self(), Eps},
		    loop(Image);
		png ->
		    Bitmap = egd_render:binary(Image, RenderType),
		    Png = egd_png:binary(
			Image#image.width,
			Image#image.height,
			Bitmap),
		    Pid ! {egd, self(), Png},
		    loop(Image);
		Unhandled ->
		    Pid ! {egd, self(), {error, {format, Unhandled}}},
		    loop(Image)
	     end;

	% Drawing primitives
	{egd, _Pid, {line, P1, P2, C}} ->
	    loop(egd_primitives:line(Image, P1, P2, C));
	{egd, _Pid, {text, P, Font, Text, C}} ->
	    loop(egd_primitives:text(Image, P, Font, Text, C));
	{egd, _Pid, {filled_ellipse, P1, P2, C}} ->
	    loop(egd_primitives:filledEllipse(Image, P1, P2, C));
	{egd, _Pid, {filled_rectangle, P1, P2, C}} ->
	    loop(egd_primitives:filledRectangle(Image, P1, P2, C));
	{egd, _Pid, {filled_triangle, P1, P2, P3, C}} ->
	    loop(egd_primitives:filledTriangle(Image, P1, P2, P3, C));
	{egd, _Pid, {polygon, Pts, C}} ->
	    loop(egd_primitives:polygon(Image, Pts, C));
	{egd, _Pid, {arc, P1, P2, C}} ->
	    loop(egd_primitives:arc(Image, P1, P2, C));
	{egd, _Pid, {arc, P1, P2, D, C}} ->
	    loop(egd_primitives:arc(Image, P1, P2, D, C));
	{egd, _Pid, {rectangle, P1, P2, C}} ->
	    loop(egd_primitives:rectangle(Image, P1, P2, C));
	{egd, _Pid, information} ->
	    egd_primitives:info(Image),
	    loop(Image);
	 _ ->
	    loop(Image)
    end.
