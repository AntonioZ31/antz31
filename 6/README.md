# 6. Управление пакетами. Дистрибьюция софта.

## Создаём свой RPM пакет

Устанавливаем требуемые пакеты 

```
yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc
```

Загружаем nginx

```
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
rpm -i nginx-1.*
```
Загружаем и распаковываем OpenSSL

```
wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
unzip OpenSSL_1_1_1-stable.zip
```
Заранее ставим все зависимости, чтобы в процессе сборки не было ошибок

```
sudo yum-builddep rpmbuild/SPECS/nginx.spec
```
Правим spec файл, указывая путь до OpenSSL, добавляем опцию --with-openssl=/root/OpenSSL_1_1_1-stable, при этом отключаем дебаг

```
vi rpmbuild/SPECS/nginx.spec
```

Собираем RPM пакет, проверяем

```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
ll rpmbuild/RPMS/x86_64/
```
Устанавливаем пакет, запускаем nginx и проверяем его статус.

```
sudo yum localinstall -y \
rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm
sudo systemctl start nginx
sudo systemctl status nginx
```

# Создаём репозиторий.

Создаём каталог под репозиторий

```
mkdir /usr/share/nginx/html/repo

```

Копируем в репозиторий наш пакет и скачиваем из Интернета ещё один пакет

```
cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm \
  -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
```

Инициализируем репозиторий

```
createrepo /usr/share/nginx/html/repo/
```

В location / в файле /etc/nginx/conf.d/default.conf добавляем директиву autoindex on для автоматического создания страницы оглавления. Затем проверяем конфиг nginx на ошибки синтаксиса, перезапускаем и проверяем курлом.

```
vi /etc/nginx/conf.d/default.conf
sudo nginx -t
sudo nginx -s reload
curl -a http://localhost/repo/
```
Добавляем готовый репозиторий в /etc/yum.repos.d/otus.repo 

```
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Доступные в репозитории пакеты, даже если они уже установлены, можно увидеть следующей командой:

```
yum list --disablerepo=* --enablerepo=otus --showduplicates
```

Т.к. nginx у нас уже стоит, установим репозиторий percona.

```
yum install percona-orchestrator.x86_64 -y
```
