# config valid only for current version of Capistrano
# capistranoのバージョンを記載。固定のバージョンを利用し続け、バージョン変更によるトラブルを防止する
lock '3.11.2'



# ここまでで設定した環境変数をcapistranoでの自動デプロイで利用するため
set :default_env, {
  rbenv_root: "/usr/local/rbenv",
  path: "/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH",
  AWS_ACCESS_KEY_ID: Rails.application.credentials.aws[:access_key_id],
  AWS_SECRET_ACCESS_KEY: Rails.application.credentials.aws[:secret_access_key],
}


# Capistranoのログの表示に利用する
set :application, 'freemarket_sample_67e'

# どのリポジトリからアプリをpullするかを指定する
set :repo_url,  'git@github.com:toshinari-ishii/freemarket_sample_67e.git'

# バージョンが変わっても共通で参照するディレクトリを指定
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :rbenv_type, :user
set :rbenv_ruby, '2.5.1' 

# どの公開鍵を利用してデプロイするか
set :ssh_options, auth_methods: ['publickey'],
                  keys: ['~/.ssh/lastapptest.pem'] 

# プロセス番号を記載したファイルの場所
set :unicorn_pid, -> { "#{shared_path}/tmp/pids/unicorn.pid" }

# Unicornの設定ファイルの場所
set :unicorn_config_path, -> { "#{current_path}/config/unicorn.rb" }
set :keep_releases, 5

# デプロイ処理が終わった後、Unicornを再起動するための記述
after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :restart do
    invoke 'unicorn:restart'
  end
end

# secrets.yml用のシンボリックリンクを追加
set :linked_files, %w{ config/secrets.yml }

# 元々記述されていた after 「'deploy:publishing', 'deploy:restart'」以下を削除して、次のように書き換え

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :restart do
    invoke 'unicorn:restart'
  end

  desc 'upload credentials.yml.enc'
  task :upload do
    on roles(:app) do |host|
      if test "[ ! -d #{shared_path}/config ]"
        execute "mkdir -p #{shared_path}/config"
      end
      upload!('config/credentials.yml.enc', "#{shared_path}/config/credentials.yml.enc")
    end
  end
  before :starting, 'deploy:upload'
  after :finishing, 'deploy:cleanup'
end
