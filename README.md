Дипломная работа. Васёв А.В.

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте инструкцию.

## Инфраструктура

### Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/vm_website.png)

### Создайте Target Group, включите в неё две созданных ВМ.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/target_group_vm_website.png)

### Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/backend_group_vm_website.png)

### Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/http_router_vm_website.png)

### Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/application_load_balancer_vm_website.png)

### Протестируйте сайт curl -v <публичный IP балансера>:80

![alt text](https://github.com/rus42/SYS-18_diplom/blob/main/curl.png)


## Мониторинг

### Проведите разведку системы и определите, какие сетевые службы запущены на защищаемой системе:
