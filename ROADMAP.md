# 1.0.0-beta.0

 - Check depot destroy by weapon/artillery/bitters
 - Move depot inventory in player inventory on deconstruct
 - TEST. Order 3 try, mark for disband all 3 train. Depot sometimes create unnecessary train
 - add raise event with force name instead player ?
 - add `atd` prefix for all mod events
 - [?] Not save lua train in train model
 - Test construction train with nuclear fuel
 - Not show schedules with TEMP point in train builder
 - Remove possibility to send any train manually to ATD (remove stops from map)
   - [?] Send trains to deconstruction using temporal waypoint? 
   - [?] Set correct name for input stop ?
 - Test removing ATD building in different situations. Save all groups on delete
   - Propose choose action on deleted/changed group trains? (send to deconstruction; attach to another group)
 - By removing and changing train template - send train to deconstruction
 - Add texture for ATD building
 - Show uncontrolled trains on map
   - Add button to send uncontrolled train to deconstruction
 - Show controlled trains on map
   - Add button to send train to deconstruction (automatically decrease train quantity in template)
 - Fix very big train building, Window to wide
 - Construct train only if exists items
 - Hide depot trains stations from train stations list
 - Test disbanding with cargo (fluid and solid)
 - Add logistic containers settings (Set automatically, off)
 - Add annotations for atd.defines

# next

- [Train Builder] Copy train part on Ctrl + Click
- [?] Remove gui and components data for user what logout/ban/deleted
- On train constructing page show train potential speed per wagons count