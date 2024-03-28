# gjz010/notes-public

基于[zk](https://github.com/zk-org/zk)和[Emanote](https://github.com/srid/emanote)的笔记网站。


## 本地使用

```bash
direnv allow
zk serve
```

## GitHub workflow

使用时：

- 需要设置变量 `NOTES_PUBLIC_REPOSITORY` 为公开仓库，例如`gjz010/notes-public`。
- 需要设置Secret `NOTES_GITHUB_TOKEN_PUBLIC_REPO` 为可以上传到公开仓库的Personal Account Token。

## 隐藏笔记功能

支持隐藏笔记，放在`private`目录下的笔记不会被同步到公开仓库。

TODO：在同步时抹除指向`private`目录下笔记的引用。
