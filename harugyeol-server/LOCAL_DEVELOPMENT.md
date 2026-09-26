# 백엔드 로컬 개발

`npm run dev`는 시작할 때 `POSTGRES_URL`의 PostgreSQL에 연결해 스키마를 초기화합니다. `localhost:5432`에서 `ECONNREFUSED`가 나오면 해당 주소에서 PostgreSQL이 실행 중이지 않은 상태입니다. 배포용 `docker-compose.yml`에는 API 서비스만 있으며 로컬 DB를 시작하지 않습니다.

## macOS에서 로컬 PostgreSQL 사용

Homebrew를 사용하는 경우:

```bash
brew install postgresql
brew services start postgresql
"$(brew --prefix postgresql)/bin/createdb" harugyeol
"$(brew --prefix postgresql)/bin/pg_isready" -h localhost -p 5432
```

`createdb`가 이미 존재한다고 알리면 DB 생성 단계는 건너뛰어도 됩니다. Homebrew의 초기 PostgreSQL 역할은 보통 macOS 사용자 이름과 같습니다. 서버 디렉터리에서 `.env.example`을 복사한 뒤 필요한 키를 채우고 `POSTGRES_URL`을 다음 형태로 설정하세요. `<macOS 사용자 이름>`은 `whoami` 출력으로 바꾸세요.

```bash
cd harugyeol-server
cp .env.example .env
```

```dotenv
POSTGRES_URL=postgresql://<macOS 사용자 이름>@localhost:5432/harugyeol
```

그다음 서버를 실행합니다.

```bash
npm ci
npm run dev
```

별도 PostgreSQL을 사용하는 경우에는 `POSTGRES_URL`을 해당 서버의 실제 주소와 계정으로 설정하세요. Supabase URL과 키는 인증에 사용하며, PostgreSQL 연결 주소를 대신하지 않습니다.
