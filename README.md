# CI - GitHub Package Registry

## 설명
> [README] 해당 프로젝트는 `actor` 와 `GITHUB_TOKEN`를 각각 `GPR_USER`와 `GPR_TOKEN` 이라는 이름으로 전달합니다. `publish`스크립트에서 시스템 환경변수로 이를 읽어 인증할 수 있습니다. 

본 `repo`는 `GitHub Package Registry`에 패키지를 배포하는 서비스 (예: 유틸리티) 의 `CI`를 위해 작성된 코드 저장소입니다.\
`publishing` 아닌, `GHCR`에 배포 및 의존성 추가로 사용되는 서비스 (예: 애플리케이션) 라면, 
<a href="https://github.com/cho-hm/ci-ghcr">해당 저장소</a>의 코드를 사용해주세요.
> 기본적으로는 `GitHub Package Registry`의 배포를 기준으로 하지만, `gradle/maven`스크립트를 사용한 어떤 배포도 문제 없습니다.

> [WARN] 해당 프로젝트는 `gradle/maven`등 스크립트 파일에 이미 배포를 위한 설정이 완료된 상태를 가정합니다.<br/>


## 프로젝트 포함하기
본 `ci` 프로젝트는 `submodule`<sup>(1)</sup>로 사용하거나, `source code`<sup>(2)</sup>를 직접 다운로드(혹은 복사)하여 사용할 수 있습니다. (`fork` 여부는 자유입니다.)\
> 해당 `repo`는 `ci`소스코드 및 설정 파일의 _저장소_ 역할만 수행합니다.
> 실제 `ci`의 수행은 본 코드를 자신의 애플리케이션에 포함해야만 동작합니다.

### `submodule` 사용시
해당 프로젝트를 포함할 애플리케이션의 루트로 이동한 후 터미널에서 다음 명령을 수행합니다.
> [WARN] 아직 커밋할 수 없는 기존 변경사항이 있다면 해결한 후 수행해야 합니다.  

> 본 소스코드가 포함된 첫 커밋은 `ci`에 포함되지 않습니다.
```bash
git switch ${YOUR_MAIN_BRANCH} # 필요하다면
git submodule add ${https://github.com/cho-hm/ci-mvn 또는 자신의 fork repo url}
bash ./ci-mvn/init.sh
git add .github
git commit -m '${COMMIT_MESSAGE}'
git push ${YOUR_REMOTE} ${YOUR_REMOTE_MAIN_BRANCH}
```
#### 리모트 `ci`프로젝트에 변경사항이 생긴 경우
리모트에 `ci`프로젝트에 변경사항이 생긴 경우, 다음 명령을 통해 `submodule`을 `update`이후, `/ci-mvn/init.sh`를 실행시킵니다.
```bash
git submodule update --remote ci-to-mvn && bash ./ci-to-mvn/init.sh
```

### `source code` 다운로드시
해당 프로젝트의 소스코드를 다운받아 내용 전체를 프로젝트 루트의 `ci-mvn`라는 디렉토리를 생성하여 옮깁니다.
이후 프로젝트 루트에서 다음 명령을 실행합니다.
```bash
bash ./ci-mvn/init.sh
```
원하는 시점에 새로 추가된 `ci-mvn/` 와 `.github/`를 포함한 `commit` 및 `push`할 수 있습니다.
> 본 소스코드가 포함된 첫 커밋은 `ci`에 포함되지 않습니다.

#### 리모트 `ci`프로젝트에 변경사항이 생긴 경우
앞선 과정을 새로하는것 처럼 다시 처음부터 반복합니다.

> [info] `submodule`과 소스코드 직접 설치 방식 모두 디렉토리 명을 원하는 대로 설정할 수 있습니다.<br/> 
> 다만, 이 경우 `init.sh`실행 명령의 디렉토리 경로는 자신이 설정한 디렉토리로 작성해야 합니다.

## 구조 및 설정
### 구조
```
./
├── .github/
│   └── workflows/
│       ├── ci-mvn-checker.yml
│       ├── ci-mvn-orchestrator.yml
│       ├── ci-mvn-publisher.yml
│       ├── run-mvn.yml
│       └── scripts/
│           ├── env/
│           │   ├── combine.sh
│           │   └── literal.sh
│           ├── main/
│           │   └── index.sh
│           ├── parser/
│           │   ├── property-parser.sh
│           │   └── set-default.sh
│           ├── runner/
│           │   ├── branch.sh
│           │   ├── signed-tag.sh
│           │   └── tag.sh
│           ├── util/
│           │   └── gpg-key-provider.sh
│           └── valid/
│               ├── valid-first-commit.sh
│               └── validate.sh
├── .gitignore
├── LICENSE
├── README.md
├── ci-mvn.properties
└── init.sh
```

해당 프로젝트의 기본 구조는 위와 같습니다.
#### 파일 설명
##### `run-mvn.yml`
`run-mvn.yml`파일은 전체 프로세스의 `entry point`역할을 하는 `github action workflow`파일입니다.
해당 파일은 `ci-mvn-orchestrator.yml`을 호출합니다.

해당 파일은 유일한 비 재사용 워크플로입니다.

##### `ci-mvn-orchestrator.yml`
`ci-mvn-orchestrator.yml`파일은 `/.github/workflows/scripts/parser/property-parser.sh`를 호출하여 `ci-mvn.properties`에 명시한 속성 및 필요한 기타 환경변수를 설정합니다.\
이후 `ci-mvn-checker`와 `ci-mvn-publisher.yml`를 상태에 따라 필요한 환경변수와 함께 호출합니다.

##### `ci-mvn-checker.yml`
`ci-mvn-checker.yml`파일은 `ci`를 트리거 시킨 `commit`이 사용자가 설정한 상태와 일치하는지 확인합니다. `signed-tag`인 경우 `gpg token`을 통해 서명의 유효성도 검사합니다.\
모든 상태가 일치하여 유효한 `commit`이라고 판단되면 `CONTINUE`를 `true`로 설정하고 종료합니다.

##### `ci-mvn-publisher.yml`
`ci-mvn-publisher.yml`파일은 `ci-mvn-checker`가 설정한 `CONTINUE`상태가 `true`인 경우 `ci-mvn-orchestrator.yml`에 의해 호출됩니다.\
`ci-mvn.properties`에 명시된 설정에 따라 프로젝트를 빌드하고 이미지를 배포합니다.

### 설정
애플리케이션 프로젝트 루트에 `ci-mvn.properties` 파일을 만들어 `ci` 트리거 동작을 선택할 수 있습니다.

#### `ci-mvn-properties`의 모든 기본값
```properties
# commit type
trigger.type=signed-tag
trigger.branch=

# build options
build.command=./gradlew clean test publish --no-daemon

# gpg
gpg.repo.url=
gpg.repo.gpg.path=keys/gpg
gpg.repo.asc.path=keys/asc
gpg.repo.branch=master
```

#### `ci-mvn-properties` 속성 설명
##### `commit type`
- `trigger.type`: `ci`를 트리거 시킬 커밋 유형을 설정합니다.
  - 옵션:
    - `signed-tag` (default)
      - ___서명된 태그___ 인 경우 트리거 됩니다.
    - `tag`
      - ___`lightweight tag`___ 인 경우 트리거 됩니다.
    - `branch`
      - `trigger.branch`에 설정된 브랜치 중 하나인 경우 트리거 됩니다.
- `trigger.branch`: `trigger.type=branch`인 경우 트리거 시킬 브랜치를 설정합니다.
  - 옵션:
    - 원하는 브랜치 명을 `:`구분자로 구분해 작성합니다.
    - 예시:
      - `master`
        - `master`브랜치 인 경우만 트리거 합니다.
      - `deploy:stage:master`
        - `deploy`, `stage`, `master`중 하나의 브랜치라면 트리거 됩니다.
    - 주의
      - 해당 브랜치는 원격지에 `push`될 브랜치 기준입니다. 로컬에서 `push`를 수행한 브랜치는 알 수 없습니다.
      
##### `build options`
- `build.command`: 실제 `publish` 수행을 위한 빌더 커맨드를 설정합니다.
  - 옵션:
    - 필요한 `publish` 커맨드를 작성합니다.

##### `gpg`
> `signed-tag`에 사용할 서명 유효성 검증을 위한 `gpg` 공개키에 대한 설정입니다.
> 서명 유효성 검증이 필요하다면 `gpg`공개키를 포함한 `repository`가 필요합니다.
- `gpg.repo.url`: `gpg` 공개키가 포함된 `repository`의 `url`
  - 옵션
    - `gpg` 공개키가 포함된 `repository`의 `url`을 설정합니다.
  - 주의
    - 해당 `repository`가 `public repository` 라면 별도의 설정이 필요하지 않습니다.
    - 해당 `repository`가 `private repository` 라면 자신의 `repository`에 `GPG_TOKEN`이라는 이름의 읽기 권한이 있는 토큰을 등록해야 합니다. 자세한 설명은 <a href="https://docs.github.com/ko/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets">공식 문서</a>를 참고하세요.
- `gpg.repo.gpg.path`: `gpg` 공개키 `repository`의 `.gpg`파일이 저장된 디렉토리의 경로를 작성합니다.
  - 옵션:
    - `gpg` 공개키 `repository`의 `.gpg`파일이 저장된 `repository root`기준 최종 디렉토리 경로를 작성합니다.
- `gpg.repo.asc.path`: `gpg` 공개키 `repository`의 `.asc`파일이 저장된 디렉토리의 경로를 작성합니다.
  - 옵션:
    - `gpg` 공개키 `repository`의 `.asc`파일이 저장된 `repository root`기준 최종 디렉토리 경로를 작성합니다.
- `gpg.repo.branch`: `gpg` 공개키 `repository`의 기준 브랜치를 작성합니다.
  - 옵션:
    - `gpg` 공개키 `repository`의 기준 브랜치를 작성합니다.


### 그 외
#### `ci-mvn.properties`
`ci-mvn.properties` 파일은 해당 `repository`에 포함되지 않습니다. 기본값 외 직접 설정해야 할 값이 존재한다면, ___프로젝트 루트___ 에 `ci-mvn.properties` 파일을 생성하여 작성합니다.

### 주의사항
#### `.github` 디렉토리
`.github`디렉토리는 각 프로젝트마다 별도로 관리되는 디렉토리입니다. 따라서 얼마든지 변경하더라도, `ci project`의 `repo`로 커밋되지 않습니다.
하지만, `ci-mvn`프로젝트의 `init.sh` 즉, `bash ./ci-mvn/init.sh` 명령을 수행하는 경우 `.github`파일의 내용을 덮어씁니다.
파일 내용이 서로 다른경우 기존 파일을 제거하지는 않지만, ___파일 이름이 동일하면서 `ci-mvn`파일의 내용과 내부가 다른 경우___, 해당 파일은 _`ci-mvn`에 존재하는 파일로 덮어씁니다._
#### `ci-mvn` 디렉토리
`ci-mvn`디렉토리 내부의 내용을 변경할 경우, `ci project`의 `repo`와 연관된 정보를 수정하게 됩니다.
`ci-mvn`프로젝트에 대한 수정사항이 필요하지 않다면 `ci-mvn`디렉토리 내의 파일을 수정하지 않아야 합니다.


또한, `ci-mvn` 디렉토리는 자신의 프로젝트의 `commit`에 포함하지 않아도 됩니다. 하지만 생성 또는 수정된 `.github`디렉토리는 `commit`에 포함되어야 합니다.
> 모든 `ci`의 기준은 `.github` 디렉토리를 기준으로 수행되며, `ci-mvn`디렉토리는 `.github` 디렉토리를 위한 _로컬 원본 저장소_ 역할입니다.

## License
This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.