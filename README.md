# Lineup_Protection
Examining effects of lineup protection in MLB

It has been a long-held belief that 'protection in the lineup' is an important factor for a player's success in any given season. If that player is the only feared hitter in the lineup,
then the pitcher may as well just pitch around them in favor of the other hitters in the lineup, and so the star player won't get many pitches to hit, degrading their performance.

My hypothesis was that this theory is mostly incorrect, at least by modern standards, in which hitters are rewarded for walks nearly as much as singles. The small grain of truth is, I believe, that having a better overall lineup leads to more runners on base, and pitchers are in general less effective with runners on base.

To test this theory, I filtered database of all 2023 batters by three separate metrics:
- The first was OPS of the on-deck hitter. If the lineup protection theory is true, the OPS of all hitters should increase with the OPS of the on-deck hitter, since the pitcher will throw them more good pitches to hit.
- The second was number of runnners on base. If my theory is true, then the OPS of all hitters should increase with more runners on base.
- The third was Baseball Reference's Leverage Index, LI. This is a scale for how important any single at-bat is to the outcome of the game, with higher LI corresponding to a more pivotal moment. I threw this in out of curiousity to see whether pitchers or hitters performed better in high leverage situations.

I split each of the three test metrics into quartiles (for runners on base, I just used 0, 1, 2, and 3) and then took the average OPS in each situation. The results can be seen pictorally in LineupProt1.png, but I will explain them here.

First, lineup protection. The first quartile has a low OPS, but each of the other three are roughly equal. This tells me that batting in front of a very porr hitter may be detrimental, but batting in front of a superstar is not beneficial. Another consideration is the construction of the lineup; batters batting in front of poor hitters are likely also poor hitters, and same for stars; batters are generally grouped together in the lineup based on production. Therefore, it is surprising to me to see no meaningful correlation between OPS and on-deck OPS. I thought I would have to do some normalization to see that result. Therefore, the idea that batting in front of a star hitter will raise your OPS is debunked.

Second, runners on base. This displays a much more linear relationship, as expected. Pitchers are most effective with the bases empty, less effective with 1 or 2 runners on, and much less effective with the bases loaded. Therefore, batting with runners on in most plate appearances will tend to inflate a batter's OPS, as I predicted.

Third, leverage index. There's not much to take away from this, as the OPS is fairly steady for all quartiles. This should be expected, because pressure affects both pitchers and hitters. However, it is intersting to see a somewhat positive spike in the highest leverage quartile, given that teams generally turn to their best pitchers in high leverage situations.
