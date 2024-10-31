turtles-own [is-scarce? just-moved? ever-moved?]
patches-own [is-city? makes-scarce? common-count scarce-count spawn-rate time-since-spawn
  radius value adjval movval costs bankrupt?]
globals [modifier is-below-replacement-rate? delta-scarce flat-delta-scarce]


to setup
  ca
  ask patches [set makes-scarce? false set is-city? false set bankrupt? false]
  reset-ticks
  set is-below-replacement-rate? false ;; stopping condition: are scarce resources below their replacement rate?
  set delta-scarce 0 ;; for how many iterations has the number of scarce resources remained constant?
  set flat-delta-scarce 0 ;;  stopping condition: have scarce resources remained constant for 5 iterations?

  ;; create resource patches


  ;; make cities
  ask patches
  [
    set modifier 0.0 ;; this number allows sites of a particular type to clump together
    ;; determine city placement
    if (city-distribution = "clumped") and ((count patches with [is-city?]) / (count patches) <= percent-cities)
    [
      set modifier modifier +  0.5 * count (neighbors with [is-city?])
    ]

    if (((random 100) / (100 - modifier)) < percent-cities) ;; control number of cities
    [
      ifelse city-distribution = "centralized"
      [
        if (sqrt( pxcor ^ 2 + pycor ^ 2) < 10) ;;  centralized cities are within sqrt(10) units of 0,0
        [
          make-a-city
        ]

      ]
      [
        make-a-city
      ]
      ;; cities start with one common resource
      sprout 1 [ set is-scarce? makes-scarce? set color [pcolor] of patch-here * 11 set shape "plant"]
    ]
  ]
  ask patches
  [
    if (not is-city?)
    [
      make-a-resource-site
    ]
  ]

  ask turtles [set just-moved? false set ever-moved? false]


end

to go
  ;; spawn resources
  ask patches with [not is-city?]
  [
    spawn-resources
  ]
  ;; mobilize cities to obtain resources
  ask patches with [is-city?]
  [
    set common-count count turtles-here with [not is-scarce?]
    set scarce-count count turtles-here with [is-scarce?]
    set value (common-count + scarce-value * scarce-count)
    set bankrupt? ifelse-value (value = 0) [true] [false]
    get-resources
  ]

  ;; check stopping conditions
  set is-below-replacement-rate? ((count turtles with [is-scarce?]) / (count turtles) < max-spawn-rate) and (count turtles with [is-scarce?] < 2 )

  set flat-delta-scarce ifelse-value ((delta-scarce - (count turtles with [is-scarce?])) = 0)
  [
    flat-delta-scarce + 1
  ]
  [
    0
  ]

  set delta-scarce count turtles with [is-scarce?]

  tick
  if ((ticks mod 4) = 0)
  [cd]

  ;; check stopping conditions

  if ((count turtles with [is-scarce?]) = 0  or (is-below-replacement-rate? and stop-if-below-replacement?) or (flat-delta-scarce > 6))
  [stop]
end

to get-resources
  ;; located at a city

  set radius value / terrain-factor
  if count turtles-here > 0
  [
    ask turtles-here
    [
      set just-moved? False
    ]
  ;; query all resources within range
  ask patches in-radius radius
    [
    ;; get values at all patches (cities and natural resource sites in radius)
    set common-count count turtles-here with [not is-scarce?]
    set scarce-count count turtles-here with [is-scarce?]
    set value (common-count + scarce-value * scarce-count)
    set adjval value - (terrain-factor * distance myself )
    set movval ifelse-value ((adjval > 0) and (([value] of myself) > 0)) [(adjval /([value] of myself))] [0]
    ;; compute value - tf*distancexy
  ]
  ;; move resources to a city, making sure not to consider resources currently at that city
  let mysites patch-set patches in-radius radius with [self != myself]
  let myname self

  if (count mysites) > 0 [
    let tradesite
     max-one-of mysites [
    movval
  ]

    ask turtles-on tradesite [set just-moved? True set ever-moved? True pen-down set color white  move-to myname ]

  ;; compute the amount of resources needed to pay to move external resources to city
  set costs floor (count turtles-here with [just-moved?]) * terrain-factor * (distance tradesite)
    let consumables turtle-set turtles-here with [not just-moved?]

    while [(costs > 0) and (count consumables) > 0 ] [
      let burned one-of consumables
      set costs ifelse-value ([is-scarce?] of burned)
      [costs - scarce-value]
      [costs - 1]
      ask burned [die]
    ]

  ]
  ]
end

to make-a-resource-site
  set pcolor brown
  set spawn-rate random-float max-spawn-rate
  set time-since-spawn (1 / spawn-rate ) + 1
  set common-count -999
  set scarce-count -999
  set modifier 0.0
  if (resource-distribution = "clumped") and ((count patches with [makes-scarce?]) / (count patches) <= percent-scarce-sites)
  [
    set modifier modifier +  0.5 * count (neighbors with [makes-scarce?])
  ]
  if (((random 100) / 100 - modifier) < percent-scarce-sites)
  [
    ifelse ;; loop to decide resource distribution
    resource-distribution = "centralized"
    [
      if (sqrt( pxcor ^ 2 + pycor ^ 2) < 12)
      [
        be-scarce
        repeat 3 ;; address imbalance of resource sites in a centralized distribution--hacky fix
        [
          ask one-of neighbors
          [
            if not is-city?
            [
              be-scarce
            ]
          ]
        ]
      ]
    ]
    [
      be-scarce
    ]
  ]
  spawn-resources
end

to make-a-city
  set is-city? True
  set pcolor gray
  set time-since-spawn -99999 ;; cities should NEVER spawn new resources
end


to spawn-resources
  ;; resource-site (patch) function
  ifelse (time-since-spawn * spawn-rate) > 1
 [
   sprout 1 [ set is-scarce? makes-scarce? set color [pcolor] of patch-here * 11 set shape "plant" set ever-moved? False set just-moved? False]
   set time-since-spawn 0

 ]
 [
  set time-since-spawn time-since-spawn + 1
 ]

end

to be-scarce
  ;; resource-site (patch) function
  set makes-scarce? True
  set pcolor green
end
@#$#@#$#@
GRAPHICS-WINDOW
180
20
648
489
-1
-1
13.94
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
0
25
172
58
terrain-factor
terrain-factor
0
1
0.4
.05
1
NIL
HORIZONTAL

SLIDER
0
120
175
153
percent-cities
percent-cities
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
0
155
174
188
percent-scarce-sites
percent-scarce-sites
0
.125
0.11
0.005
1
NIL
HORIZONTAL

CHOOSER
0
260
139
305
resource-distribution
resource-distribution
"uniform" "clumped" "centralized"
1

CHOOSER
0
306
139
351
city-distribution
city-distribution
"uniform" "clumped" "centralized"
0

SLIDER
-2
60
171
93
scarce-value
scarce-value
2
102
98.0
2
1
NIL
HORIZONTAL

PLOT
660
185
874
335
% Resources Harvested
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 100 * (count turtles with [just-moved?]) / (count turtles + 1)"

BUTTON
0
420
64
454
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
0
380
64
414
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
660
28
873
178
Resource Count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SLIDER
0
190
175
223
max-spawn-rate
max-spawn-rate
0
.05
0.0125
0.0025
1
NIL
HORIZONTAL

BUTTON
70
420
160
454
go forever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
879
27
1133
177
Scarce Resource Count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [is-scarce?]"

SWITCH
0
505
181
538
stop-if-below-replacement?
stop-if-below-replacement?
1
1
-1000

PLOT
880
185
1133
335
% Scarce Resources Harvested
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 100 * (count turtles with [just-moved? and is-scarce?]) / (count turtles with [is-scarce?] + 1)"

PLOT
660
370
874
520
% Bankrupt Cities
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 100 * (count patches with [(is-city?) and (bankrupt?)]) / ((count patches with [is-city?]) + 1)"

TEXTBOX
690
10
840
28
Consumption of all Resources\n
11
0.0
1

TEXTBOX
925
10
1155
55
Consumption of Scarce Resources
11
0.0
1

TEXTBOX
724
352
874
370
Welfare of Cities\n
11
0.0
1

TEXTBOX
5
485
155
503
Special Stopping Conditions\n
11
0.0
1

TEXTBOX
5
245
225
271
Spatial Distribution of Patch Types
11
0.0
1

TEXTBOX
5
105
155
123
Environment Parameters\n
11
0.0
1

TEXTBOX
5
10
155
28
Economic Parameters
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

### Summary and Scope
This is a model of how scarce resources are drawn into cities from the natural world and then consumed. Because gathering these resources costs money, attempting to get more and more resources can bankrupt a city. On the other hand, because these resources are scarce, they can go extinct. 

This process of discovery, consumption, and extinction of scarce resources might be a mechanism behind fads that depend on natural products.

### Detailed Narrative Description
In everyday life, we experience fads (for example, playing with fidget spinners, eating the ‘orange roughy’ fish, or wearing hats that are decorated with drooping feathers) that seem to come from nowhere, become popular quickly, and then disappear quickly. They exhibit a nonlinear growth and decay in popularity. Adoption can be driven by a relatively small number of influential people or markets.  An important subset of fads comprises those that depend on scarce natural resources, so that they end suddenly because the resource is depleted. These are often fads related to food or clothing made from animals.
I hypothesize that the onset of popularity and depletion of resources in such fads is much quicker when the resources are scarce but easy to access from many locations (example: cod fish in the North Atlantic) than when they are harder to access (example: blue whales in the Southern Ocean). This means that local interactions also play a role in the timing of fads (and may be what distinguishes a fad that disappears from one that tapers off). 
There are historical records of hunting and fashion fads causing extinctions before the industrial age, so it is plausible to model the flow of resources from natural resource sites to cities using the action of individual traders as agents who capture resources in nature and move them in discrete units to population centers in exchange for payment.

I am hoping to observe the rate at which scarce resources are drawn into cities and also the rate at which they are consumed (compared to the replacement rate), and ultimately how many time-steps it takes for them to go extinct. I think that the greater the value of a scarce resource relative to a common one, the more quickly they will be consumed. Similarly, I think that resources which are uniformly distributed are more likely to be consumed quickly than clumped resources which I expect to be consumed more quickly than centralized resources. 

## HOW IT WORKS
### Agent Types
1. **Natural Resources** (plant shapes): represent plant and animal products (heron skins and feathers, orchids, fish schools) that humans gather and move to cities. SCARCE resources (such as saffron or sturgeon) are yellow and have a value greater than 1 (set with the SCARCE-VALUE slider); COMMON resources (such as wild grapes or deer) have a value above 1 are blue (or green when they are part of a city's initial resources). When resources are harvested by a city, they turn white. 
2. **Cities** (gray patches): search for the nearby patch with the most valuable Natural Resource and expend their own VALUE to move it from the distant patch to themselves;
3. **Resource Sites** (brown and green patches): regularly spawn new natural resources. Brown sites spawn common resources and green sites spawn scarce resources. 

### Agent Properties
1. **Natural Resources** (plant shapes): 
	* IS-SCARCE?: boolean, True for SCARCE resources, False otherwise
	* JUST-MOVED?: boolean, has the resource moved to a city during this time-step? Used to distinguish resources that a city needs to pay for vs. those it can spend. 
	* EVER-MOVED?: boolean, has this resource ever been harvested by a city or is it still in its natural state?
2. **Cities** (gray patches):
	* IS-CITY?: boolean, distingushes cities from resource sites
	* COMMON-COUNT: integer, number of common resources at the city 
	* SCARCE-COUNT: integer, number of scarce resources at the city
	* VALUE: integer, value of all resources currently at the city  
	* RADIUS: float, distance that a city can afford to move resources from (defined as the ratio of the city's VALUE to the global TERRAIN-FACTOR)
	* COSTS: integer, amount of resources needed to pay to move external resources to city
	* BANKRUPT?: boolean, True if there are no resources at the city
3. **Resource Sites** (brown and green patches):
	* MAKES-SCARCE?: boolean, distinguishes natural resource sites that make scarce resources from other sites
 	* SPAWN-RATE: float, number new resources to spawn per time-step--less than 1--for example, a SPAWN rate of 1/10 means spawn a new resource every 10 ticks
	* TIME-SINCE-SPAWN: integer, number of ticks since last time a resource spawned
	* VALUE: integer, value of all resources currently at the resource site
	* ADJVAL: float, used in computing whether a city should draw resources from the patch (net value that the city expects to gain from gathering resources at a given resource site)
	* MOVVAL: float, used in computing whether a city should draw resources from the patch (measures the profitability of gathering resources from this site relative to other sites near the city)

### Agent Actions
1. **Natural Resources** (plant shapes): move to cities, die when expended by cities
2. **Cities** (gray patches): compute own value, identify profitable resource sites in radius (GET-RESOURCES function), expend natural resources
3. **Resource Sites** (brown and green patches): spawn new natural resources (SPAWN-RESOURCES function), compute own value and net value if resources at the site are moved to a city

### The Environment 

The agents operate in a spatial environment, which represents a geographical region that is occupied by cities. Traders move between cities, and between natural resource sites and the cities. Given enough resources, a city should be able to send a trader to any natural resource site. On the other hand, with no resources, a city will not be able to pay traders and will drop out of the simulation.  


### Order of Events at Each Time Step
1.	Resource sites spawn new resources, if enough time steps have passed since the last spawn.
2.	Each city C:
a.	Counts the resources at its patch by type (common vs scarce) (determine trade budget) 
b.	Identifies the patches within radius r (scout for resources), where 
RADIUS = VALUE / TERRAIN-FACTOR
i.	Asks each patch within this radius the value of its common resources (each has value 1) and scarce resources (each has value > 1) 
c.	Finds the patch P\* with the largest value for its distance from C 
(i.e., the quantity ADJVAL =  (VALUE – TERRAIN-FACTOR * distancexy(C, P\*) ) is maximal) (hire a trader)
d.	Asks the resource at P* to move to C (trader moves goods)
i.	If the total value at any patch within radius r exceeds the quantity given by TERRAIN-FACTOR\*distancexy(C, P\*), move up to RADIUS resources
e.	Asks resources at C to die (pay the trader with resources already at hand), in order to generate value needed, up to the integer quantity FLOOR(TERRAIN-FACTOR\*distancexy(C, P\*)). 



## HOW TO USE IT

SETUP - Prepare variables and environment to run model.

GO - Run the model for one iteration. 

GO FOREVER - Run the model until it reaches a stopping condition (bankrupt cities, no new resources being harvested for 9 iterations, extinction of scarce resources) 

TERRAIN-FACTOR - Profitability of moving resources. The terrain factor is less than or equal to 1. For example, if 2 common resources are at 3 units of distance from a city, it does not make sense for the city to spend 6 of its own common resources to pay a trader to gather the 2 new resources. However, if the terrain factor is 0.25, the price of moving those resources is 1.5 = (2 resources* 3 distance * (0.25 terrain factor)) and moving the new resources to the city is profitable.

SCARCE-VALUE - Relative value of a scarce resource to a common one; i.e. 99 means a scarce resource is 99x the value of a common one

PERCENT-CITIES - Percentage of grid patches to make cities. The rest will be resource sites.

PERCENT-SCARCE-SITES - Percentage of resource sites (non-city patches) that generate scarce resources

MAX-SPAWN-RATE - number of new resources to generate per resource per iteration.

STOP-IF-BELOW-REPLACEMENT - Stop the simulation if the proportion of unharvested scarce resources is below the replacement rate

RESOURCE-DISTRIBUTION - Choose whether scarce resources are uniformly distributed on the map, clumped together, or centralized (all within a circle of sqrt(10) units radius of the center of the map)

CITY-DISTRIBUTION - Choose whether cities are uniformly distributed on the map, clumped together, or centralized (all within a circle of sqrt(10) units radius of the center of the map)

## THINGS TO NOTICE
A very high terrain factor, corresponding to it being prohibitively expensive to travel far in search of resources, will often protect scarce resources, giving a chance for population recovery and/or growth.

A low scarce-value can have the same effect. It is not worth it to seek scarce resources, so cities will claim 

Resources turn white when moved by traders.  

## THINGS TO TRY
Set the TERRAIN-FACTOR to 0.95 and the SCARCE-VALUE to 100
Repeat with SCARCE-VALUE of 3.

While doing this, compare UNIFORM, CLUMPED, and CENTRALIZED city/resource distributions.


## EXTENDING THE MODEL

Currently, resources are "immortal" in that they will not die unless consumed, but new resources spawn. It would be interesting to see how giving resources a lifespan would affect the population.

In real life, habitat destruction contributes to extinctions; it would be interesting to have scarce-resource producing sites convert to common-resource sites when harvested and also to have overharvesting of common-resource sites to convert them to bankrupt cities.

This model could also be extended to market research, drawing an analogy between scarce resources and customers who are unlikely to churn, or to archaeology, replacing scarce resources with scarce trade goods and updating rules.

## RELATED MODELS

This model attempts to reltate path-seeking to resource accumulation and depletion, which is an aspect of many models in the Modeling Commons, but NetLogo Urban Suite - Path Dependence model is very close: 

* Rand, W. and Wilensky, U. (2007).  NetLogo Urban Suite - Path Dependence model.  http://ccl.northwestern.edu/netlogo/models/UrbanSuite-PathDependence.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Webster, H., &amp; Steele, G. (n.d.). Flight of fashion: When feathers were worth twice their weight in gold. Museums Victoria. https://museumsvictoria.com.au/article/flight-of-fashion-when-feathers-were-worth-twice-their-weight-in-gold/ 
* Lack, M., S., Short, K., & Willock, A. (2003). Managing risk and uncertainty in deep-sea fisheries: lessons from orange roughy. TRAFFIC Oceania, https://www.traffic.org/site/assets/files/9431/managing-risk-and-uncertainty-in-deep-sea-fisheries.pdf
* T. A. Branch (2001) A review of orange roughy Hoplostethus atlanticus fisheries, estimation methods, biology and stock structure, South African Journal of Marine Science, 23:1, 181-203, DOI: 10.2989/025776101784529006
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="city-distribution">
      <value value="&quot;clumped&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="terrain-factor">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-spawn-rate">
      <value value="0.0025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-rare-sites">
      <value value="0.065"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resource-distribution">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-if-below-replacement?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-cities">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scarce-value">
      <value value="44"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
