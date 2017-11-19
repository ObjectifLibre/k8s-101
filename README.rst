Capitole du Libre 2017 : Hands On Kubernetes
###########################################

Ce Hands On est basé sur le matériel fourni par Kelsey Hightower lors d'un talk
à la Kubecon Europe en 2016 :
https://github.com/kelseyhightower/talks/tree/master/kubecon-eu-2016/demo

TP1 : Préparation de l’environnement
====================================

Environnement OVH (recommandé)
------------------------------

Merci à OVH pour la mise à disposition de l'environnemnt du Hands On

La procédure de lancement de votre environnememnt ets la suivante :

1. Créer un compte OVH

* Aller sur ovh.com
* Dans la section cloud, choisissez "Public Cloud"
* Cliquer sur commencer pour créer votre compte

2. Créer votre projet Cloud

* Une fois authentifié sur votre compte, cliquer sur l'onglet Cloud
* Cliquer sur commander, "Projet Cloud", entrer le voucher et créer le projet.

3. Lancer votre instance

* Cliquer sur ajouter, ajouter un serveur, choisir le modèle **C2-15**
* Dans l'onglet "Options avancées" ajouter le script suivant pour activer le mot de passe ssh:

.. code-block:: bash

  #!/bin/sh
  echo 'ubuntu:OVHPassCDL2017!' | chpasswd
  sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config
  service ssh restart

* Lancer la création de la machine
* Connecter vous à votre serveur

.. code-block:: bash

  ssh ubuntu@votre_IP

4. Récupération du matériel du Hands On

Avant de commencer les travaux pratiques, télécharger (clone) les fichiers dont vous aurez besoin.

.. code-block:: bash

  git clone https://github.com/ObjectifLibre/k8s-101

5. Installation de l'environnement

L'environnement utilise la solution de test de cluster K8s minikube.
Cette solution se base sur virtualbox dans notre cas.

.. code-block:: bash

 ./tools/install.sh

Environnement matériel perso (non testé)
----------------------------------------

L'environnement du Hands On utilise minikube **https://github.com/kubernetes/minikube**
La solution se base sur une machine virtuelle et support plusieurs hyperviseurs

* Virtualbox
* Kvm
* xhyve (OSX)
* Hyper-V

1. Télécharger minikube et kubectl:

* Linux :

.. code-block:: bash

  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl

* Mac (avec homebrew) :

.. code-block:: bash

  brew cask install minikube
  curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/darwin/amd64/kubectl
  chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl

* Windows :

.. code-block:: bash

  Récupérer https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe et l'ajouter à son path
  Récupérer https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/windows/amd64/kubectl.exe et l'ajouterà son path

2. Lancement de l'environnement

.. code-block:: bash

  minikube start --driver=[votre hyperviseur]

.. note::

  Les drivers KVM et xhyve nécéssite une configuration particulière :
  https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm-driver

3. Récupération du matériel du Hands On

Avant de commencer les travaux pratiques, télécharger (clone) les fichiers dont vous aurez besoin.

.. code-block:: bash

  git clone https://github.com/ObjectifLibre/k8s-101

Utilisation de Kubernetes
-------------------------

1. Vérifier le bon fonctionnement de l'environnement

.. code-block:: bash

  kubectl get nodes

2. Lancement de notre premier conteneur

La prise en main de Kubernetes peut etre un peu austère avec la multiplication des fichiers YAML.
La commande kubectl permet de s'affranchir du YAML dans les cas simples.
Nous allons commencer par créer un premier conteneur web simple qui affiche sa configuration quand on le requete :

.. code-block:: bash

  kubectl run hello-minikube --image=objectiflibre/nginx-demo:blue --port=80

Veŕifier que tout va bien :

.. code-block:: bash

  kubectl get pods

Nous allons exposer le port de ce conteneur pour pouvoir l'utiliser :

.. code-block:: bash

  kubectl expose deployment hello-minikube --type=NodePort

Pour pouvoir accèder à votre conteneur depuis l'exterieur sur la plateforme OVH, il faut exposer le port de la VM minikube :

.. code-block:: bash

  kubectl get services
  # Récupérer le port externe 
  VBoxManage controlvm "minikube" natpf1 "guestweb,tcp,,[port],,[port]"

3. Dashboard kubernetes

Il existe un dashboard web pour voir et manipuler les objets kubernetes accessible sur le port 30000

4. Faire le ménage

.. code-block:: bash

  kubectl delete deployment hello-minikube
  kubectl delete pods --all

TP2 : Déployer un service web
=============================

Déploiements et services
------------------------

Appliquer le manifest du fichier **manifest/nginx-deployment.yml** pour déployer un pod nginx.
Ce manifest reprend le lancement de notre premier pod avec kubectl en explicitant la configuration YAML

.. code-block:: bash

  kubectl apply -f nginx-deployment.yml
 
Utiliser le manifest **manifest/nginx-service.yml** pour créer un service et exposer le port de notre pod

.. code-block:: bash

  kubectl apply -f nginx-service.yml
  VBoxManage controlvm "minikube" natpf1 "guestnginx,tcp,,8080,,8080"

Scaling & update strategy
-------------------------

1. Scaling

Deux solutions possibles pour "scaler" votre service :

* Editer le déploiement manifest/nginx-deployment.yml et changer le nombre de replicas pour scaler le serveur: 

.. code-block:: bash

  kubectl edit deployment nginx-deployment

* Utiliser kubectl directement : 

.. code-block:: bash

  kubectl scale deployment nginx-deployment  --replicas=3

Vérifier que le load balancing est en place.

2. Rolling update

La stratégie de rolling update consiste à remplacer au fur et à mesure les pods de la version 1 par les pods de la version 2.
Il suffit de changer la version d'image dans notre déploiement :

.. code-block:: bash

  kubectl set image deployment/nginx-deployment  nginx=objectiflibre/nginx-demo:blue
  kubectl get rs -w

3. Rollback

Une erreur s'est produite et nous avons besoin de faire un retour arrière :

.. code-block:: bash

  kubectl rollout undo deployment/nginx-deployment

4. Blue/Green

La stratégie Blue/Green consiste à avoir en parallèle les 2 versions de l'application :
Il faut créer un deuxième fichier de déploiement et changer le tag red en blue, changer la version d'image et le nom du déploiement.
Enfin, lancer le deuxième déploiement

Un fois les conteneurs blue prets, on bascule de version:

.. code-block:: bash

  kubectl edit service nginx-service

Déploiement de notre application
================================

Gestion des données
-------------------

1. Persistence

Le but de notre application est d'avoir des données persistentes en base.
Pour faire ca on va créer un **PersistentVolumeClaim** (pvc) de 15 Go :

.. code-block:: bash

  kubectl apply -f sql-pvc.yml
  kubectl get pvc
 

2. Mots de passe

L'accès et l'authentification à notre base de données va nécéssiter l'utilisation d'un mot de passe.
Comme c'est une donnée sensible, on va utiliser le mécanisme de secret de Kubernetes :

.. code-block:: bash

  kubectl create secret generic sql-pwd --from-literal=root=RootSup3rPwd! --from-literal=ghost=K4sp3r
  kubectl describe secret sql-pwd

Déploiement de la base de données
---------------------------------

Le fichier de déploiement sql-deployment.yml est utilisé. Nous pouvons voir dedans l'utilisation des données
gérées précédemment.

.. code-block:: bash

  kubectl apply -f sql-deployment.yml
  kubectl get pods

Il faut ensuite exposer un service pour pouvoir utiliser la base de données. 
Comme la base de données ne devra etre accessible que par les pods de notre application, pas
besoin de l'exposer à l'exterieur, on utilise donc un service de type ClusterIP :

.. code-block:: bash

  kubectl apply -f sql-service.yml
  kubectl get service

Pour tester le bon fonctionnement de mysql :

.. code-block:: bash

  kubectl run -ti mysql-test --image mysql --command /bin/bash
  root@mysql-test-69fd78d964-g4k5d:/# mysql -h mysql.default.svc.cluster.local -u ghost -p
  mysql> show databases;
  kubectl delete deploy mysql-test

Déploiement de Ghost
--------------------

Ghost est une application de blogging en node.js (un peu plus moderne que wordpress)
Notre pod sera composé d'un conteneur avec l'application node.js (fait par Kelsey Hightower) ecoutant en local sur le port 2368
et d'un conteneur nginx servant de reverse proxy

1. Gestion des secrets

Ghost va stocker ses informations dans notre base de données, ,il a donc besoin de connaitre son mot de passe.
On passe donc par un secret : 

.. code-block:: bash

  kubectl create secret generic ghost --from-file=config.js

2. Gestion de la configuration

La configuration du vhost nginx sera elle stockée dans un ConfigMap puisqu'elle ne contient pas de secret

.. code-block:: bash

  kubectl create configmap nginx-ghost --from-file=ghost.conf

3. Déploiement de l'application

Notre déploiement contient les 2 conteneurs et les accès au secret et configmap :

.. code-block:: bash

  kubectl apply -f ghost-deployment.yml

4. Exposition du service

Vous avez maintenant l'habitude :

.. code-block:: bash

  kubectl apply -f ghost-service.yml
  VBoxManage controlvm "minikube" natpf1 "guestghost,tcp,,32000,,32000"

Nettoyage
=========

Stopper et supprimer minikube :

.. code-block:: bash

  minikube stop
  minikube delete

That's all folks
