[Решение](#anchor)

#  Дипломная работа по профессии «Системный администратор»

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая.

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

---

<a id="anchor"></a>

# Решение

## Создание виртуальных машин.

Создаю файл main.tf с учетом условий:

_Создайте Target Group, включите в неё две созданных ВМ._

_Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP._

_Создайте HTTP router. Путь укажите — /, backend group — созданную ранее._

_Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80._

[main.tf](https://github.com/ZelinskiyAN/diplom/blob/main/img/main.tf)

Выполнив команду terraform apply создаем веб-сервера web_1 и web_2, а также остальные необходимые ресурсы на Ubuntu 22.04 LTS.

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/e09347f0-9342-4452-af4d-f593294ddd70)

Terraform outputs:

[external_ip_address_bast_7 = "178.154.220.115"](http://178.154.220.115)

[external_ip_address_elas_5 = "51.250.13.221"](http://51.250.13.221)

[external_ip_address_graf_4 = "84.201.132.243"](http://84.201.132.243)

[external_ip_address_kib_6 = "51.250.65.29"](http://51.250.65.29)

[external_ip_address_l7 = "158.160.152.157"](http://158.160.152.157)

[external_ip_address_prom_3 = "158.160.121.254"](http://158.160.121.254)

[external_ip_address_web_1 = "158.160.96.189"](http://158.160.96.189)

[external_ip_address_web_2 = "62.84.122.148"](http://62.84.122.148)

[internal_ip_address_bast_7 = "192.168.10.37"](http://192.168.10.37)

[internal_ip_address_elas_5 = "192.168.10.6"](http://192.168.10.6)

[internal_ip_address_graf_4 = "192.168.10.21"](http://192.168.10.21)

[internal_ip_address_kib_6 = "192.168.10.7"](http://192.168.10.7)

[internal_ip_address_prom_3 = "192.168.10.5"](http://192.168.10.5)

[internal_ip_address_web_1 = "192.168.10.33"](http://192.168.10.33)

[internal_ip_address_web_2 = "192.168.20.12"](http://192.168.20.12)

Устанавливаю ansible на терминал и накатываю с помощью него nginx на web-сервера.

Создаем конфигурационный файл [ansible.cfg](https://github.com/ZelinskiyAN/diplom/blob/main/img/ansible.cfg)

Описываем окружение в файле [hosts.txt](https://github.com/ZelinskiyAN/diplom/blob/main/img/hosts.txt)

Описываем [playbook.yaml](https://github.com/ZelinskiyAN/diplom/blob/main/img/nginx.rar)

Вводим команду:

    ansible-playbook -b /home/user/project/playbook.yaml

Проверяем сайт:

[внешний IP адрес L7 балансировщика](http://158.160.152.157/)

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/4902bc26-3e01-4a75-a814-17aee211cf7f)

---

## Устройство мониторинга посредством Prometheus и Grafana.

### Cтавим prometheus на ВМ prom_3

Вводим команды:

    ssh user@158.160.121.254
    sudo -i
    useradd --no-create-home --shell /bin/false prometheus
    wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
    tar xvfz prometheus-2.47.1.linux-amd64.tar.gz
    cd prometheus-2.47.1.linux-amd64/
    mkdir /etc/prometheus
    mkdir /var/lib/prometheus
    cp ./prometheus promtool /usr/local/bin/
    cp -R ./console_libraries /etc/prometheus
    cp -R ./consoles /etc/prometheus
    cp ./prometheus.yml /etc/prometheus
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    chown prometheus:prometheus /usr/local/bin/prometheus
    chown prometheus:prometheus /usr/local/bin/promtool
    nano /etc/systemd/system/prometheus.service

[prometheus.service](https://github.com/ZelinskiyAN/diplom/blob/main/img/prometheus.service)

    chown -R prometheus:prometheus /var/lib/prometheus
    systemctl enable prometheus
    sudo systemctl start prometheus
    sudo systemctl status prometheus

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/84e5340c-ca98-4117-8c22-18fa488cba92)

Правим конфиг prometheus.yml:

    nano /etc/prometheus/prometheus.yml

[prometheus.yml](https://github.com/ZelinskiyAN/diplom/blob/main/img/prometheus.yml)

    systemctl restart prometheus
    systemctl status prometheus

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/05034400-7c42-4ab9-8c6b-0b220060bf10)

Переходим в интерфейс prometheus в браузере:

### Ставим node-exporter на web-сервера web_1 и web_2

Подключаемся к web-сервера по ssh и вводим команды:

    sudo -i
    sudo useradd --no-create-home --shell /bin/false prometheus
    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
    cd node_exporter-1.6.1.linux-amd64/
    mkdir /etc/prometheus
    mkdir /etc/prometheus/node-exporter
    cp ./* /etc/prometheus/node-exporter
    chown -R prometheus:prometheus /etc/prometheus/node-exporter/
    nano /etc/systemd/system/node-exporter.service

[node-exporter.service](https://github.com/ZelinskiyAN/diplom/blob/main/img/node-exporter.service)

    systemctl enable node-exporter
    systemctl start node-exporter
    systemctl status node-exporter

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/d3921773-90bd-408e-b0dd-4f883d8a50f9)

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/f910f6a5-1ffa-4432-a80e-6421dff1556a)

### Ставим prometheus-nginxlog-exporter web-сервера web_1 и web_2

Подключаемся к web-сервера по ssh и вводим команды:

    sudo -i
    wget https://github.com/martin-helmich/prometheus-nginxlog-exporter/releases/download/v1.9.2/prometheus-nginxlog-exporter_1.9.2_linux_amd64.deb
    apt install ./prometheus-nginxlog-exporter_1.9.2_linux_amd64.deb
    wget -O /etc/systemd/system/prometheus-nginxlog-exporter.service https://raw.githubusercontent.com/martin-helmich/prometheus-nginxlog-exporter/master/res/package/prometheus-nginxlog-exporter.service
    nano /etc/systemd/system/prometheus-nginxlog-exporter.service

[prometheus-nginxlog-exporter.service](https://github.com/ZelinskiyAN/diplom/blob/main/img/prometheus-nginxlog-exporter.service)

Правим конфиг nginx.conf:

    nano /etc/nginx/nginx.conf

[nginx.conf](https://github.com/ZelinskiyAN/diplom/blob/main/img/nginx.conf)

Правим конфиг myapp.conf:

    rm -rf /etc/nginx/sites-enabled/default
    nano /etc/nginx/conf.d/myapp.conf

[myapp.conf](https://github.com/ZelinskiyAN/diplom/blob/main/img/myapp.conf)

    systemctl restart nginx
    systemctl status nginx

    systemctl daemon-reload
    chown -R prometheus:prometheus /var/log/nginx/access.log
    systemctl restart prometheus-nginxlog-exporter
    systemctl status prometheus-nginxlog-exporter

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/9b78b41d-719a-405a-b48f-e5ea7271219e)

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/c91c52b1-f6d1-4bdc-9e82-0aacfc29ab11)

Переходим в интерфейс prometheus в браузере:

[Targets prometheus](http://158.160.121.254:9090/targets?search=)

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/1feb1645-e140-45cf-978d-a8702b1837a4)

### Cтавим grafana на ВМ graf_4

Подключаемся по ssh и вводим команды:

    sudo -i
    apt-get install -y adduser libfontconfig1 musl
    wget https://dl.grafana.com/oss/release/grafana_10.1.5_amd64.deb
    dpkg -i grafana_10.1.5_amd64.deb
    systemctl enable grafana-server
    systemctl start grafana-server
    systemctl status grafana-server

![image](https://github.com/ZelinskiyAN/diplom/assets/149052655/98fa835a-bc4a-48ba-8153-8ce020db0805)

Переходим в интерфейс grafana в браузере:

[Интерфейс grafana](http://84.201.132.243:3000/d/rYdddlPWk/grafana?orgId=1&refresh=1m&var-datasource=default&var-job=prometheus&var-node=192.168.10.33:9100&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B)











