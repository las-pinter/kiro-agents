# Messy stats module that needs refactoring

def do_stats(a,b,c=None):
    # This function does all kinds of stats stuff
    # TODO: fix this later
    x = [a]
    if b is not None:
        x.append(b)
    if c is not None:
        x.append(c)
    
    # Calculate stuff
    s = 0
    for i in x:
        s = s + i
    
    m = s / len(x) if len(x) > 0 else 0
    
    # Find the middle one
    x2 = sorted(x)
    if len(x2) % 2 == 0:
        mid = (x2[len(x2)//2 - 1] + x2[len(x2)//2]) / 2
    else:
        mid = x2[len(x2)//2]
    
    # How spread out
    v = 0
    for i in x:
        v = v + (i - m) ** 2
    v = v / len(x)
    sd = v ** 0.5
    
    # Min and max
    mn = x[0]
    mx = x[0]
    for i in x:
        if i < mn:
            mn = i
        if i > mx:
            mx = i
    
    # Results
    r = {
        'numbers': x,
        'sum': s,
        'avg': round(m, 2),
        'middle': round(mid, 2),
        'spread': round(sd, 2),
        'smallest': mn,
        'largest': mx,
        'how_many': len(x)
    }
    return r


def format_output(d):
    # Format the stats for display - this is way too long
    txt = ""
    txt = txt + "=" * 40 + "\n"
    txt = txt + "STATISTICAL ANALYSIS RESULTS\n"
    txt = txt + "=" * 40 + "\n"
    txt = txt + "Numbers: "
    for n in d['numbers']:
        txt = txt + str(n) + ", "
    txt = txt + "\n"
    txt = txt + "Sum: " + str(d['sum']) + "\n"
    txt = txt + "Average: " + str(d['avg']) + "\n"
    txt = txt + "Median: " + str(d['middle']) + "\n"
    txt = txt + "Std Dev: " + str(d['spread']) + "\n"
    txt = txt + "Min: " + str(d['smallest']) + "\n"
    txt = txt + "Max: " + str(d['largest']) + "\n"
    txt = txt + "Count: " + str(d['how_many']) + "\n"
    txt = txt + "=" * 40
    return txt


def compare(g1, g2, g3=None):
    # Compare multiple groups
    r1 = do_stats(g1[0], g1[1], g1[2] if len(g1) > 2 else None)
    r2 = do_stats(g2[0], g2[1], g2[2] if len(g2) > 2 else None)
    
    print("Group 1:")
    print(format_output(r1))
    print("\nGroup 2:")
    print(format_output(r2))
    
    if g3:
        r3 = do_stats(g3[0], g3[1], g3[2] if len(g3) > 2 else None)
        print("\nGroup 3:")
        print(format_output(r3))
        if r1['avg'] > r2['avg'] and r1['avg'] > r3['avg']:
            print("\n>>> Group 1 has highest average!")
        elif r2['avg'] > r1['avg'] and r2['avg'] > r3['avg']:
            print("\n>>> Group 2 has highest average!")
        else:
            print("\n>>> Group 3 has highest average!")
    else:
        if r1['avg'] > r2['avg']:
            print("\n>>> Group 1 has higher average!")
        elif r2['avg'] > r1['avg']:
            print("\n>>> Group 2 has higher average!")
        else:
            print("\n>>> Groups are equal!")
