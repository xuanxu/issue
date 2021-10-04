describe Issue::Payload do
  before do
    @data = JSON.parse({ action: "test-action",
                         sender: { login: "user33" },
                         repository: { full_name: "myorg/myrepo_name" },
                         issue: { number: 42,
                                 title: "New package",
                                 body: "Body!",
                                 user: { login: "author" },
                                 labels: ["astrophysics", "tests"] }}.to_json)
  end

  it "should create context from the passed parsed json data and event" do
    event = "specs"

    payload = Issue::Payload.new(@data, event)
    context = payload.context

    expect(context.action).to eq("test-action")
    expect(context.event).to eq("specs")
    expect(context.issue_id).to eq(42)
    expect(context.issue_title).to eq("New package")
    expect(context.issue_body).to eq("Body!")
    expect(context.issue_author).to eq("author")
    expect(context.issue_labels).to eq(["astrophysics", "tests"])
    expect(context.repo).to eq("myorg/myrepo_name")
    expect(context.sender).to eq("user33")
    expect(context.event_action).to eq("specs.test-action")
  end

  it "context should include comment information on issue_comment event" do
    comment_data = { comment: { id: 33,
                                body: "commenting",
                                created_at: "2/22/2222",
                                html_url: "http://comment.link"} }
    parsed_data = @data.merge(JSON.parse(comment_data.to_json))
    event = "issue_comment"

    payload = Issue::Payload.new(parsed_data, event)
    context = payload.context

    expect(context.action).to eq("test-action")
    expect(context.event).to eq("issue_comment")
    expect(context.comment_id).to eq(33)
    expect(context.comment_body).to eq("commenting")
    expect(context.comment_created_at).to eq("2/22/2222")
    expect(context.comment_url).to eq("http://comment.link")
  end

  it "should create accessor methods for all context information" do
    payload = Issue::Payload.new(@data, "issue_comment")

    expect(payload.action).to eq("test-action")
    expect(payload.event).to eq("issue_comment")
    expect(payload.issue_id).to eq(42)
    expect(payload.issue_title).to eq("New package")
    expect(payload.issue_body).to eq("Body!")
    expect(payload.issue_author).to eq("author")
    expect(payload.issue_labels).to eq(["astrophysics", "tests"])
    expect(payload.repo).to eq("myorg/myrepo_name")
    expect(payload.sender).to eq("user33")
    expect(payload.event_action).to eq("issue_comment.test-action")
    expect(payload.comment_body).to be_nil
    expect(payload.comment_created_at).to be_nil
    expect(payload.comment_url).to be_nil
  end

  it "should get issue data from pull_request" do
    pr_data = JSON.parse({ action: "opened",
                           sender: { login: "user32" },
                           repository: { full_name: "org/newrepo" },
                           pull_request: { number: "11",
                                           title: "New code",
                                           body: "Body of the PR!",
                                           user: { login: "contributor" }}}.to_json)

    payload = Issue::Payload.new(pr_data, "pull_request")

    expect(payload.action).to eq("opened")
    expect(payload.event).to eq("pull_request")
    expect(payload.issue_id).to eq("11")
    expect(payload.issue_title).to eq("New code")
    expect(payload.issue_body).to eq("Body of the PR!")
    expect(payload.issue_author).to eq("contributor")
    expect(payload.issue_labels).to be_nil
    expect(payload.repo).to eq("org/newrepo")
    expect(payload.sender).to eq("user32")
    expect(payload.event_action).to eq("pull_request.opened")
  end

  it "original data should be available" do
    payload = Issue::Payload.new(@data, "whatever")

    expect(payload.raw_payload).to eq(@data)
  end

  it "#opened? should be true only if action = opened or reopened" do
    data = JSON.parse({action: "opened"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_opened

    data = JSON.parse({action: "reopened"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_opened

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_opened
  end

  it "#closed? should be true only if action = closed" do
    data = JSON.parse({action: "closed"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_closed

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_closed
  end

  it "#commented? should be true only if action = created" do
    data = JSON.parse({action: "created"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_commented

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_commented
  end

  it "#edited? should be true only if action = edited" do
    data = JSON.parse({action: "edited"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_edited

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_edited
  end

  it "#locked? should be true only if action = locked" do
    data = JSON.parse({action: "locked"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_locked

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_locked
  end

  it "#unlocked? should be true only if action = unlocked" do
    data = JSON.parse({action: "unlocked"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_unlocked

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_unlocked
  end

  it "#pinned? should be true only if action = pinned or unpinned" do
    data = JSON.parse({action: "pinned"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_pinned

    data = JSON.parse({action: "unpinned"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_pinned

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_pinned
  end

  it "#assigned? should be true only if action = assigned or unassigned" do
    data = JSON.parse({action: "assigned"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_assigned

    data = JSON.parse({action: "unassigned"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_assigned

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_assigned
  end

  it "#labeled? should be true only if action = labeled or unlabeled" do
    data = JSON.parse({action: "labeled"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_labeled

    data = JSON.parse({action: "unlabeled"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to be_labeled

    data = JSON.parse({action: "other"}.to_json)
    payload = Issue::Payload.new(data, "event")
    expect(payload).to_not be_labeled
  end
end
