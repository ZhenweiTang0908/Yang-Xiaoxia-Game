from pathlib import Path
p=Path('scripts/game.gd');s=p.read_text()
s=s.replace('for i in 42:', 'for i in 7:')
a=s.index('\t\tfor row in range(0,int(p.size.y/19)):');b=s.index('\tfor s in spikes:',a)
s=s[:a]+'''\t\t# Broad stone planes, with only sparse seams to preserve silhouette clarity.
\t\tfor i in range(1,int(p.size.x/120)):
\t\t\tvar x=p.position.x+i*120
\t\t\tdraw_line(Vector2(x,p.position.y+12),Vector2(x-8,p.position.y+29),Color("263b49"),2)
'''+s[b:]
s=s.replace('for x in [180,820,1515,2340,3150]:','for x in [180,1515,3150]:')
s=s.replace('for i in 10:', 'for i in 4:')
p.write_text(s)
