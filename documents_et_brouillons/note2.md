Paiement #9 semble intéressant.
Je viens d'appeler mon oncle qui est livreur et voici sa reponse: lorsque le client est absent à la livraison, le livreur attend 10min max(appel au moins 2 fois), 
- si c'est un paiement à la livraison et que le client n'est pas là, le livreur appel le vendeur qui lui indique la marche à suivre(ramener le colis ou le garder), dans ce cas c'est le vendeur qui paie la livraison dans tous les cas(il faut donc que le vendeur puisse indiquer s'il accepte ou non les paiement à la livraison).
- si c'est un paiement par défaut(avant livraison), et que le client est absent, le colis est envoyé à notre base(il doit appeler d'abord, si on ne décroche pas, il va avec le colis). Pour certaincolis, Notre représentant déclenchera une vente au enchère dans un certain délais si le client ne viens pas chercher, celà s'affichera sur la plateforme mais avec cout réduit.

dans tous les cas le livreux devra cliquer sur un bouton `retourner la commande` dans l'app

Tech #11: tu as raison.
- il faut un systheme hybride deep link et sms:
- avant meme d'envoyer le deep link, il faut envoyer les détaille utile de la commande et lieu de livraison, lieu d'achat dans le sms. le livreur repond par 1 s'il est intéressé et `n` s'il ne l'est pas.
- alors le second sms contenant le deeplink peut s'afficher, dans ce cas, il peu cliquer pour ouvrire l'app juste pour plus de graphisme(de toute les facons et devra continuer par sms pour confirmer le retrait etc...)

pas besoins score de fiabilité du livreur, on s'appuyera sur sa note et on avisera plus tard pour ce cas