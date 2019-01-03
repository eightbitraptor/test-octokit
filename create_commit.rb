require 'octokit'
require 'byebug'
require 'base64'
require 'logger'

access_token = ENV.fetch('GITHUB_PERSONAL_ACCESS_TOKEN')
username     = 'eightbitraptor'
repo_name    = 'test-octokit'
repo_path    = [username, repo_name].join('/')
file_path    = 'dummy-file'
log_file     = 'api.log'

logger = Logger.new(log_file)
logger.level = Logger::DEBUG

stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger, logger, {bodies: {request: true}}
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

client = Octokit::Client.new(access_token: access_token)

master_sha = client
  .ref(repo_path, 'heads/master')
  .object
  .sha

dummy_file_blob_sha = Octokit
  .contents(repo_path, path: file_path, ref: 'heads/new-branch')
  .sha

new_file_content = "This\n\tIs\n\t\tthe\n\t\t\tNew File\nあぶない\nwith lots of edits"

# new_branch = client
#   .create_ref(repo_path, 'heads/new-branch', master_sha)

response = client.update_contents(
  repo_path,
  file_path,
  "Octokit: Update file contents",
  dummy_file_blob_sha,
  new_file_content,
  branch: 'new-branch'
)

pull_request = client.create_pull_request(repo_path, 'master',
  'new-branch', 'update dummy file', 'This PR updates the dummy file')

p 'done'
