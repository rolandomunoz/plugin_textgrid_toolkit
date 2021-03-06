#Written by Rolando Muñoz (2017-2020)
## Add information from the source tier to the destinty tier

form Merge interval tiers
  natural From_tier 2
  natural To_tier 1
endform

src_tier = from_tier
dst_tier = to_tier

src_nIntervals = Get number of intervals: src_tier
for src_iInterval to src_nIntervals
  src_intervalTmin = Get start time of interval: src_tier, src_iInterval
  src_intervalTmax = Get end time of interval: src_tier, src_iInterval
  src_intervalText$ = Get label of interval: src_tier, src_iInterval
  src_intervalTmid = (src_intervalTmin + src_intervalTmax)*0.5

  if src_intervalText$ <> ""
    @isIntervalEmpty: dst_tier, src_intervalTmin, src_intervalTmax
    if isIntervalEmpty.return
      # Modify interval tier
      nocheck Insert boundary: dst_tier, src_intervalTmin
      nocheck Insert boundary: dst_tier, src_intervalTmax
      dst_interval = Get interval at time: dst_tier, src_intervalTmid
      Set interval text: dst_tier, dst_interval, src_intervalText$
    endif
  endif
endfor

procedure isIntervalEmpty: .tier, .tmin, .tmax
  if .tmin = .tmax
    exitScript: "tmin is equal to tmax"
  elsif .tmax < .tmin
    exitScript: "tmin is greater than tmax"
  endif
  .return = 0
  .tmid = (.tmax + .tmin)*0.5
  .interval = Get interval at time: .tier, .tmid
  .interval_min = Get high interval at time: .tier, .tmin
  .interval_max = Get low interval at time: .tier, .tmax
  .text$ = Get label of interval: .tier, .interval
  .interval_difference = .interval_max - .interval_min
  if .text$ == "" and .interval_difference = 0
    .return = 1
  endif
endproc