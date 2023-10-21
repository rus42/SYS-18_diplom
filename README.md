Дипломная работа. Васёв А.В.

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности.

## Инфраструктура

### Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/vm_website.png)

### Создайте Target Group, включите в неё две созданных ВМ.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/target_group_vm_website.png)

### Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/backend_group_vm_website.png)

### Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/http_router_vm_website.png)

### Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/application_load_balancer_vm_website.png)

На вирутальных машинах с использованием ansibe [ansible/nginx.yaml](ansible/nginx.yml) установлен nginx и развернут сайт. 

### Протестируйте сайт curl -v <публичный IP балансера>:80

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/curl.png)


## Мониторинг

### Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix агенты, настройте агенты на отправление метрик в Zabbix.

Zabbix сервер на виртуальной машине развернут с использованием ansibe [ansible/zabbix_server.yaml](ansible/zabbix_server.yml)

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/zabbix.png)

Веб-консоль zabbix доступна из сети интернет по адресу http://51.250.39.9/zabbix
Данные для авторизации:
Логин: Admin
Пароль: zabbix

На вирутальные машины с вебсайтом с использованием ansibe [ansible/zabbix_agent.ayml](ansible/zabbix_agent.yml) установлены zabbix агенты. 

Настроено автоматическое обнаружение хостов.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/discovery_actions.png)

Настроены дашборды.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/img/dashboard.png)


## Логи