extensions [nw]             ;; Import extension for creating networks

breed [individuals person]  ;; Create breed of turtles

;; Define the properties of each individual in created breed
;; Description of each variable is in the info tab under "Entities, State Variables and Scales"
individuals-own [morality obtained-software? license-period obtained-version wait-period price-range]

globals [profit loss current-month version cracked-version]        ;; Create global variables for tracking profit, loss, current month and software versions

;; Setup procedure
to setup
  ca                    ;; Clear the world
  reset-ticks           ;; Reset ticks at the start of new simulation

  if Network-Type = "Wattz Strogatz" [                   ;; Check the type of network, if the network chosen is "Wattz Strogatz"
    ;; Use the "nw" extension to generate a wattz strogatz network with breed individuals having "Num-People"
    ;; "Num-People" is defined using the slider
    ;; Create the links such that each individual is connected to 2 individuals on each side with rewire probability as 0.50
    nw:generate-watts-strogatz individuals links Num-People 2 0.50 [
      fd 10
      set shape "circle"                                ;; Set the shape of each individual as circle
      set morality one-of [0 1]                         ;; Initialize the ethical value of each individual by randomly chosing from the list
      ifelse morality = 0 [                             ;; Set the color of the node according to the chosen ethical value
        set color red
      ] [
        set color green
      ]
      set obtained-software? false                      ;; Initialize obtained software
      set obtained-version 0                            ;; Initialize obtained version
      set license-period 0                              ;; Initialize license period
      set wait-period random Waiting-Threshold          ;; Randomly initialize the maximum waiting period for each individual
      set price-range random-float Price-Threshold      ;; Randomly initialize the maximum price threshold for each individual
    ]
  ]

  if Network-Type = "Preferential Attachment" [         ;; Check the type of network, if the network chosen is "Preferential Attachment"
    ;; Use the "nw" extension to generate a preferential attachment network with breed individuals having "Num-People"
    ;; "Num-People" is defined using the slider
    ;; Create the links such that each individual is connected to 1 previously created individual
    nw:generate-preferential-attachment individuals links Num-People 1 [
      fd 10
      set shape "circle"                                ;; Set the shape of each individual as circle
      set morality one-of [0 1]                         ;; Initialize the ethical value of each individual by randomly chosing from the list
      ifelse morality = 0 [                             ;; Set the color of the node according to the chosen ethical value
        set color red
      ] [
        set color green
      ]
      set obtained-software? false                      ;; Initialize obtained software
      set obtained-version 0                            ;; Initialize obtained version
      set license-period 0                              ;; Initialize license period
      set wait-period random Waiting-Threshold          ;; Randomly initialize the maximum waiting period for each individual
      set price-range random-float Price-Threshold      ;; Randomly initialize the maximum price threshold for each individual
    ]
  ]

  ask one-of individuals with [color = red] [set color yellow]     ;; Assign the work to crack the software to one individual of low ethical value

  set current-month 0           ;; Initialize the current month
  set profit 0                  ;; Initialize the profit value
  set loss 0                    ;; Initialize the loss value
  set version 1                 ;; Initialize the original software version number
  set cracked-version 0         ;; Initialize the cracked software version number

  repeat 30 [ layout-spring individuals links 0.2 5 1]        ;; Initialize the layout of the network created
end

;; Go procedure
to go
  if ticks > 36000 [stop]            ;; Stop the simulation after 10 years i.e. 36000 ticks

  ;; At the start of the simulation ethical individuals buy the software and the non ethical individual
  ;; starts cracking the latest release
  if ticks = 0 [
    buy-software                    ;; Call buy software procedure
    crack-software                  ;; Call crack software procedure
  ]

  if (ticks != 0 and ticks mod 300 = 0) [   ;; At each time step, i.e. 300 ticks
    set current-month (current-month + 1)   ;; Increase the current month
    change-morality-green                   ;; Call change morality green procedure
    change-morality-red                     ;; Call change morality red procedure
    reset-license                           ;; Call reset license procedure
    buy-software                            ;; Call buy software procedure
    get-cracked-software                    ;; Call get cracked software procedure
  ]

  tick       ;; Increase the ticks

end

;; Change morality green procedure
to change-morality-green
  ;; All ethical individuals check if their waiting threshold is less than the original software release interval
   ask individuals with [color = green][
      if wait-period < New-Version-Release-Interval [
        ;; If the threshold is less, check if their price threshold is also less than the price of the software
        ;; Or if their waiting threshold is greater than the cracked software release interval
        ;; Or if the cracking period is less than the original software release interval
        ;; In any of the above case, individuals change their morality
        if wait-period > Months-To-Crack or Months-To-Crack < New-Version-Release-Interval or price-range < price [
          set color red                   ;; Change color
          set morality 0                  ;; Change ethical value
          set obtained-software? false    ;; Reset obtained software
          set license-period 0            ;; Reset license
          set obtained-version 0          ;; Reset obtained version
        ]
      ]
    ]

end

;; Change morality red procedure
to change-morality-red
   ;; All non ethical individuals check if their waiting threshold is less than the cracked software release interval
    ask individuals with [color = red][
      if wait-period < Months-To-Crack [
        ;; If the threshold is less, check if their waiting threshold is greater than the original software release interval
        ;; Or if the cracking period is greater than the original software release interval
        ;; In any of the above case, individuals change their morality
        if wait-period > New-Version-Release-Interval or Months-To-Crack > New-Version-Release-Interval [
          set color green                 ;; Change color
          set morality 1                  ;; Change ethical value
          set obtained-software? false    ;; Reset obtained software
          set license-period 0            ;; Reset license
          set obtained-version 0          ;; Reset obtained version
        ]
      ]
    ]

end

;; Reset license procedure
to reset-license
   ask individuals with [obtained-software? = true][             ;; All ethical individuals check if their license has expired
    if (color = green and current-month = license-period) [      ;; If the license has expired reset obtained software
      set obtained-software? false
    ]
   ]

end

;; Buy software procedure
to buy-software
  if current-month mod New-Version-Release-Interval = 0 [       ;; Check if a new version of the original software is released
    if current-month != 0 [set version (version + 1)]           ;; Increase the original software version number
  ]

  ;; Count a random number of ethical individuals who want to obtain the software
  let buyers (random count individuals with [color = green and not obtained-software?])

  ;; Ask the previoulsy chosen number of ethical individuals to buy the software
  ask n-of buyers individuals with [color = green and not obtained-software?] [
    set profit (profit + price)                                           ;; Increase profit by the price of software
    set obtained-software? true                                           ;; Set obtained software
    set license-period (random Max-License-Period + 1 + current-month)    ;; Generate a license period
    set obtained-version version                                          ;; Set obtained version as current version
  ]

end

;; Crack software procedure
to crack-software
  ;; Ask the individual with color yellow to crack the software
  ;; The individual buys an official copy of the latest version of the software
  ;; Then cracks it in some duration of time
  ask individuals with [color = yellow][
    ;; Increase the profit by the price of software since the individual first bought the software
    set profit (profit + price)
    ;; Set obtained version as current version
    ;; This will later become the cracked version
    set obtained-version version
  ]

end

;; Get cracked software procedure
to get-cracked-software
  if (current-month != 0 and current-month mod Months-To-Crack = 0)[      ;; Check if a new cracked version of the software is released
    ask individuals with [color = yellow][
      set cracked-version obtained-version                                ;; Set the cracked version
      ;; Distribute the cracked software to non ethical individuals in `Crack Distribution Radius` of yellow individual
      ;; Only distribute the crack to those non ethical individuals who don't have the latest cracked version
      ask individuals in-radius Crack-Distribution-Radius with [color = red and obtained-version < cracked-version][
        set loss (loss + price)                ;; Increase the loss by the price of the software
        set obtained-software? true            ;; Set obtained software
        set obtained-version cracked-version   ;; Set obtained version
      ]
    ]
    crack-software                             ;; Ask the yellow individual to again start cracking the latest software
  ]

  ;; Non ethical individuals who have obtained the latest cracked software distribute it to other non ethical individuals
  ask individuals with [color = red and obtained-version >= cracked-version][
    ;; Count a random number of non ethical individuals in crack distribution radius who want to obtain the software
    let downloaders (random count individuals in-radius Crack-Distribution-Radius with [color = red and obtained-version < cracked-version])
    if downloaders != 0 [
      ;; Ask the previoulsy chosen number of non ethical individuals to download the cracked software
      ask n-of downloaders individuals in-radius Crack-Distribution-Radius with [color = red and obtained-version < cracked-version][
        set loss (loss + price)                ;; Increase the loss by the price of the software
        set obtained-software? true            ;; Set obtained software
        set obtained-version cracked-version   ;; Set obtained version
      ]
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
303
10
740
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
11
10
267
43
Num-People
Num-People
1
150
100.0
1
1
NIL
HORIZONTAL

BUTTON
23
373
110
418
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

SLIDER
11
57
267
90
Months-To-Crack
Months-To-Crack
1
12
8.0
1
1
Months
HORIZONTAL

SLIDER
11
104
270
137
New-Version-Release-Interval
New-Version-Release-Interval
1
12
8.0
1
1
Months
HORIZONTAL

INPUTBOX
800
291
905
351
Price
10.0
1
0
Number

PLOT
757
10
1133
276
Profit and Loss
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Profit" 1.0 0 -13840069 true "" "plot profit"
"Loss" 1.0 0 -2674135 true "" "plot loss"

BUTTON
145
373
232
420
NIL
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

MONITOR
770
369
864
414
Current Month
current-month
17
1
11

SLIDER
10
153
271
186
Max-License-Period
Max-License-Period
1
36
7.0
1
1
Months
HORIZONTAL

MONITOR
887
369
995
414
Software Version
version
17
1
11

MONITOR
1018
370
1120
415
Cracked Version
cracked-version
17
1
11

SLIDER
12
203
271
236
Waiting-Threshold
Waiting-Threshold
0
12
12.0
1
1
Months
HORIZONTAL

INPUTBOX
952
291
1067
351
Price-Threshold
20.0
1
0
Number

SLIDER
11
250
269
283
Crack-Distribution-Radius
Crack-Distribution-Radius
2
10
5.0
1
1
NIL
HORIZONTAL

CHOOSER
14
302
270
347
Network-Type
Network-Type
"Wattz Strogatz" "Preferential Attachment"
0

@#$#@#$#@
# Software Piracy Model ODD Description

The model description follows the ODD (Overview, Design concepts, Details) protocol for describing individual- and agent-based models (Grimm et al. 2006; 2010; Railsback and Grimm 2018).


## 1. Purpose and Patterns
The primary purpose of this model is to exlore the effects of moral values or ethics on software piracy in society which in turn affects the profits and losses of a software company. What are the reasons due to which people download pirated software? What measures can software companies take to ensure that their software is not pirated and distributed easily? The model is designed for theoretical exploration and hypothesis generation. The model represents general people and so general criteria like Software Release Intervals, Software Availability etc. can be applied to determine the patterns and answer the above questions.

## 2. Entities, State Variables, and Scales
The entities in this model are individuals (turtles) who want to use the software either legally or illegally which is determined by their ethical value. The state variables of the individuals along with their description is described below:

	State Variables			Description
	morality			Store the ethical value of the individual
	obtained-software?		Store whether individual has obtained any version of the software
	license-period			The license period of currently obtained software (if obtained legally)
	obtained-version		The version of the obtained software
	wait-period			Maximum time individuals can wait for new version of software before changing their ethical value
	price-range			Maximum price they would like to pay for obtaining the software (if obtained legally)
 
The model's timestep is 300 ticks for 1 month and the simulations run for 10 years.

## 3. Process Overview and Scheduling
The model includes the following actions that are executed at each time step in the given order:

**Change Morality Green**: The individuals with high ethical value can chanhe their morality due to the price of the software being higher than their price range or due to their waiting threshold for a newer version to be available being less than the release interval of the new software version. In such cases, the individuals change their morality and download cracked software throughout the run of the model.

**Change Morality Red**: The individuals with low ethical value can chanhe their morality due to their waiting threshold for a newer cracked version to be available being less than the release interval of the cracked software. In such cases, the individuals change their morality and buy original software from the company throughout the run of the model.

**Reset License**: The individuals with high ethical value check if their license period has expired and if it has expired set the variable `obtained-software?` to `false` so that they can buy the latest version of the software.

**Buy Software**: A random number of individuals with high ethical value check if their license period has expired or whether they have the software or not. If they don't have the software or if their license period has expired, they are selected as potential buyers of the software. Each such buyer increases the profit of the company by the price of the software and is assigned a random license duration less than the maximum license period given by the company. The license period of each buyer is calculated as `random Max-License-Period + 1 + current-month`, i.e at the end of the calculated month, the buyer's license will be expired.

**Crack Software**: An individual with color yellow is assigned the work to crack the software whenever a new version is available. This individual has a low ethical value and although buys the software legally from the company, but cracks it within a period of time and distributes it to all other individuals with low ethical value in a certain radius of the individual. The radius of distribution is calculated using the `in-radius` command.

**Get Cracked Software**: A random number of individuals with low ethical value check if a new veriosn of cracked software is available and if it's software version is higher than the one, they currently have or that they do not have the cracked software but it is available. In either of the above cases they download the cracked software and distribute it to other individuals with low ethical value in a certain radius of them. Each such downloader increases the loss of the company by the price of the software. 

**Update Plot and Monitors**: The plot showing profit and loss of the software company is updated and the monitor values are updated.

All the described procedures, except Update Plot and Monitors procedure, are run at each timestep, i.e 300 ticks or 1 month.

## 4. Design Concepts
**_Basic Principle_**: The basic topic of this model is how the ethical value of individuals affect their decision of obtaining software legally or illegally. This decision of the individuals is affected by various parameters like their price range, maximum period they can wait for new version release etc. These parameters the ethical value of the individuals and hence their decision. 

**_Emergence_**: The model's only output is the profit and loss incurred by the software company over time. The output emerges from how the individuals decide to obtain the software, legally or illegally, which is determined by various parameters like version releases, price range, waiting periods etc.

**_Adaptive Behaviour_**: The adaptive behaviour of individuals is changing their ethical value, i.e. the decision to obtain the software legally or illegally. At each time step the individuals can decide whether to change their ethical value or retain it. The decision to change their ethical value is done by checking their waiting threshold, i.e. the maximum time each individual can wait for new version of software to release and the checking the price of the software. The individuals with high ethical value check for their waiting threshold along with their price range while the individuals with low ethical value only check for their waiting threshold since they download the cracked software and thus price is irrelevant in this case.

**_Objective_**: Each individual is assigned thresholds of waiting and price when they are created and uses them to either change their ethical value or not. In the current version of the model these thresholds do not change during the course of the model run. The assignment of these thresholds are random and are determined by the paramaters provided as input. Each individual with either of the ethical value tries to obtain the latest version of the software in accordance with their own parameters throughout the run of the model.

**_Sensing_**:  The individual agents are assumed to sense the price of the software, the release interval of the new version of the software, both original and pirated and the current month.

**_Interaction_**: The interactions between the individuals are direct. The individuals with low ethical value determine the individuals also with low ethical value in their vicinity who want to obtain the cracked version that they have. They then distribute the software to such individuals in a certain radius of themselves. 

**_Stochasticity_**: The ethical value, maximum waiting period and maximum price range of each individual is set stochastically during the setup procedure. The individuals also download the software stochastically for both legal and illegal downloads. At each time step a random number of individuals with high/low ethical value check if they want to obtain the latest version of the original/cracked software respectively. If they want the software, high morality individuals buy it, thus increasing the profits of the company while the low morality individuals distribute and download the cracked version, thereby increasing the losses of the company. 

**_Collectives_**: The individuals are divided into individuals having high ethical value and low ethical value which form a collective and affects their behaviours.

**_Observation_**: Observations include a plot for profit and loss of the software company.

Learning and Prediction are not represented.

## 5. Initialization
The number of individuals created are determined by the `Num-People` slider and their ethical value is set randomly to either high or low. The waiting threshold and price threshold of each individual is determined randomly from the sliders `Waiting-Threshold` and `Price-Threshold` respectively. At the start of the simulation no individual has obtained any software, so their `obtained-software?` variable is set to `false`, `obtained-version` and `license period` variables are set to 0. The `current-month`, `profit`, `loss` and `cracked-version` number variables are all set to 0 while the original software `version` is set to 1 assuming that the software is released at the start of simulation.

## 6. Input Data
No input from external sources are used.

## 7. Submodels
**Change Morality Green**: The individuals with high ethical value can chanhe their morality due to the price of the software being higher than their price range or due to their waiting threshold for a newer version to be available being less than the release interval of the new software version. In such cases, the individuals change their morality and download cracked software throughout the run of the model.

**Change Morality Red**: The individuals with low ethical value can chanhe their morality due to their waiting threshold for a newer cracked version to be available being less than the release interval of the cracked software. In such cases, the individuals change their morality and buy original software from the company throughout the run of the model.

**Reset License**: The individuals with high ethical value check if their license period has expired and if it has expired set the variable `obtained-software?` to `false` so that they can buy the latest version of the software.

**Buy Software**: A random number of individuals with high ethical value check if their license period has expired or whether they have the software or not. If they don't have the software or if their license period has expired, they are selected as potential buyers of the software. Each such buyer increases the profit of the company by the price of the software and is assigned a random license duration less than the maximum license period given by the company. The license period of each buyer is calculated as `random Max-License-Period + 1 + current-month`, i.e at the end of the calculated month, the buyer's license will be expired.

**Crack Software**: An individual with color yellow is assigned the work to crack the software whenever a new version is available. This individual has a low ethical value and although buys the software legally from the company, but cracks it within a period of time and distributes it to all other individuals with low ethical value in a certain radius of the individual. The radius of distribution is calculated using the `in-radius` command.

**Get Cracked Software**: A random number of individuals with low ethical value check if a new veriosn of cracked software is available and if it's software version is higher than the one, they currently have or that they do not have the cracked software but it is available. In either of the above cases they download the cracked software and distribute it to other individuals with low ethical value in a certain radius of them. Each such downloader increases the loss of the company by the price of the software. 

## 8. Credits and References
[1] Peace, A. G., Galletta D. F. & Thong, J. Y. L. (2003).  Software Piracy in the Workplace:  A Model andEmpirical Test. Journal of Management Information Systems, 20:1, 153-177, DOI:10.1080/07421222.2003.11045759.

[2] Corwin, J.A. (2018). Preventing Pirated Software Use within an Organization.
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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Price Variation Preferential" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>profit</metric>
    <metric>loss</metric>
    <enumeratedValueSet variable="Crack-Distribution-Radius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Waiting-Threshold">
      <value value="12"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Price" first="1" step="1" last="20"/>
    <enumeratedValueSet variable="Months-To-Crack">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="New-Version-Release-Interval">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price-Threshold">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network-Type">
      <value value="&quot;Preferential Attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-License-Period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Num-People">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Distribution Radius Variation Preferential" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>profit</metric>
    <metric>loss</metric>
    <steppedValueSet variable="Crack-Distribution-Radius" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="Waiting-Threshold">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Months-To-Crack">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="New-Version-Release-Interval">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price-Threshold">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network-Type">
      <value value="&quot;Preferential Attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-License-Period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Num-People">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Release Interval Variation Preferential" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>profit</metric>
    <metric>loss</metric>
    <enumeratedValueSet variable="Crack-Distribution-Radius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Waiting-Threshold">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Months-To-Crack" first="1" step="1" last="12"/>
    <steppedValueSet variable="New-Version-Release-Interval" first="1" step="1" last="12"/>
    <enumeratedValueSet variable="Price-Threshold">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network-Type">
      <value value="&quot;Preferential Attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-License-Period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Num-People">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Price Variation Watts Strogatz" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>profit</metric>
    <metric>loss</metric>
    <enumeratedValueSet variable="Crack-Distribution-Radius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Waiting-Threshold">
      <value value="12"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Price" first="1" step="1" last="20"/>
    <enumeratedValueSet variable="Months-To-Crack">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="New-Version-Release-Interval">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price-Threshold">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network-Type">
      <value value="&quot;Wattz Strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-License-Period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Num-People">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Distribution Radius Variation Watts Strogatz" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>profit</metric>
    <metric>loss</metric>
    <steppedValueSet variable="Crack-Distribution-Radius" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="Waiting-Threshold">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Months-To-Crack">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="New-Version-Release-Interval">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Price-Threshold">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network-Type">
      <value value="&quot;Wattz Strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-License-Period">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Num-People">
      <value value="100"/>
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
0
@#$#@#$#@
