# OmniAI::Anthropic

An Anthropic implementation of the [OmniAI](https://github.com/ksylvest/omniai) APIs.

## Installation

```sh
gem install omniai-anthropic
```

## Usage

### Client

A client is setup as follows if `ENV['ANTHROPIC_API_KEY']` exists:

```ruby
client = OmniAI::Anthropic::Client.new
```

A client may also be passed the following options:

- `api_key` (required - default is `ENV['ANTHROPIC_API_KEY']`)
- `host` (optional)

### Configuration

Global configuration is supported for the following options:

```ruby
OmniAI::Anthropic.configure do |config|
  config.api_key = '...' # default: ENV['ANTHROPIC_API_KEY']
  config.host = '...' # default: 'https://api.anthropic.com'
end
```

### Chat

A chat completion is generated by passing in prompts using any a variety of formats:

```ruby
completion = client.chat('Tell me a joke!')
completion.choice.message.content # 'Why did the chicken cross the road? To get to the other side.'
```

```ruby
completion = client.chat({
  role: OmniAI::Chat::Role::USER,
  content: 'Is it wise to jump off a bridge?'
})
completion.choice.message.content # 'No.'
```

```ruby
completion = client.chat([
  {
    role: OmniAI::Chat::Role::SYSTEM,
    content: 'You are a helpful assistant.'
  },
  'What is the capital of Canada?',
])
completion.choice.message.content # 'The capital of Canada is Ottawa.'
```

#### Model

`model` takes an optional string (default is `claude-3-haiku-20240307`):

```ruby
completion = client.chat('Provide code for fibonacci', model: OmniAI::Anthropic::Chat::Model::OPUS)
completion.choice.message.content # 'def fibonacci(n)...end'
```

[Anthropic API Reference `model`](https://docs.anthropic.com/en/api/messages)

#### Temperature

`temperature` takes an optional float between `0.0` and `1.0` (defaults is `0.7`):

```ruby
completion = client.chat('Pick a number between 1 and 5', temperature: 1.0)
completion.choice.message.content # '3'
```

[Anthropic API Reference `temperature`](https://docs.anthropic.com/en/api/messages)

#### Stream

`stream` takes an optional a proc to stream responses in real-time chunks instead of waiting for a complete response:

```ruby
stream = proc do |chunk|
  print(chunk.choice.delta.content) # 'Better', 'three', 'hours', ...
end
client.chat('Be poetic.', stream:)
```

[Anthropic API Reference `stream`](https://docs.anthropic.com/en/api/messages)

#### Format

`format` takes an optional symbol (`:json`) and modifies requests to send additional system text requesting JSON:

```ruby
completion = client.chat([
  { role: OmniAI::Chat::Role::USER, content: 'What is the name of the drummer for the Beatles?' }
], format: :json)
JSON.parse(completion.choice.message.content) # { "name": "Ringo" }
```

[Anthropic API Reference `control-output-format`](https://docs.anthropic.com/en/docs/control-output-format)
