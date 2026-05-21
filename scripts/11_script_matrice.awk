BEGIN {
    FS = "\t"
    num_p = split(per_list, p_array, " ")
    for (i = 1; i <= num_p; i++) {
        n = split(p_array[i], parts, "_")
        period_prefix[parts[n]] = p_array[i]
    }
    
}
FILENAME ~ /dict_temp/ {
    gsub(/\r/, "", $0)
    dict[$1] = $2
    taxons[$2] = 1
    next
}

{
    gsub(/\r/, "", $0)

    # 1. Extraction de la période
    file_name = FILENAME
    sub(/.*\//, "", file_name)
    match(file_name, /^[0-9]+/)
    prefixe = substr(file_name, RSTART, RLENGTH)
    if (!(prefixe in period_prefix)) next
    p_name = period_prefix[prefixe]

    # 2. Extraction du taxon
    split($13, desc, " ")
    nom_blast = desc[1]" "desc[2]
    # Si le taxon n'est pas dans notre dictionnaire, on passe tout de suite
    if (!(nom_blast in dict)) next
    cible = dict[nom_blast]

    # 3. SÉCURITÉ ANTI-DOUBLON : On vérifie l'ID unique du read ($1)
    # Si ce read précis a DEJA été compté pour cette période et ce taxon cible, on l'ignore
    read_id = $1
    if ((read_id, p_name, i) in dejavu) {
        next
    }
    # Sinon, on marque ce read comme "vu" pour ne plus le reprendre
    dejavu[read_id, p_name, cible] = 1

    # 4. Extraction du count (size=N)
    count = 1
    if ($1 ~ /size=[0-9]+/) {
        match($1, /size=[0-9]+/)
        split(substr($1, RSTART, RLENGTH), s, "=")
        count = int(s[2])
    }
    # 5. On ajoute les reads normalement (sans aucune division)
    matrice[cible, p_name] += count
}

END {
    for (t in taxons) {
        if (t == "") continue
        printf "%s", t
        for (i = 1; i <= num_p; i++) {
            val = ((t, p_array[i]) in matrice) ? matrice[t, p_array[i]] : 0
            printf ",%d", val
        }
        printf "\n"
    }
}