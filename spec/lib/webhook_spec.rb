describe Issue::Webhook do

  describe "Initialization" do
    it "should set settings values" do
      config = { secret_token: "123ABC",
                 origin: "testing/tests",
                 discard_sender: "mybot",
                 accept_events: ["issue_comment", "issues"] }

      webhook = Issue::Webhook.new(config)

      expect(webhook.secret_token).to eq("123ABC")
      expect(webhook.accept_origin).to eq("testing/tests")
      expect(webhook.discard_sender).to eq("mybot")
      expect(webhook.accept_events).to eq(["issue_comment", "issues"])
    end

    it "should convert accept_events to an Array of strings" do
      webhook = Issue::Webhook.new({accept_events: :issues})
      expect(webhook.accept_events).to eq(["issues"])
    end
  end

  describe "#parse_request" do
    let(:request_body) { double(read: {title: "New issue"}.to_json, rewind: true) }
    let(:request) { double(get_header: "issues", body: request_body) }

    describe "when unable to verify signature" do
      it "should create an error if there is no secret_token" do
        webhook = Issue::Webhook.new({secret_token: nil})

        payload, error = webhook.parse_request(request)

        expect(payload).to be_nil
        expect(error.message).to eq("Can't compute signature")
      end

      it "should create an error if request is not signed" do
        webhook = Issue::Webhook.new({secret_token: "123ABC"})
        allow(request).to receive(:get_header).with("HTTP_X_HUB_SIGNATURE").and_return(nil)

        payload, error = webhook.parse_request(request)

        expect(payload).to be_nil
        expect(error.message).to eq("Request missing signature")
      end

      it "should create an error if request signature is incorrect" do
        webhook = Issue::Webhook.new({secret_token: "123ABC"})

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("Signatures didn't match!")
      end
    end

    describe "when conditions are not met" do
      before do
        allow_any_instance_of(Issue::Webhook).to receive(:verify_signature).and_return(true)
      end

      it "should create an error if payload is invalid JSON" do
        webhook = Issue::Webhook.new({secret_token: "123ABC"})
        allow(request_body).to receive(:read).and_return("invalid => json format {}")

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("Malformed request")
      end

      it "should create an error if payload is empty" do
        webhook = Issue::Webhook.new({secret_token: "123ABC"})
        allow(request_body).to receive(:read).and_return("{}")

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("No payload")
      end

      it "should create an error if there is no event header" do
        webhook = Issue::Webhook.new({secret_token: "123ABC"})
        allow(request).to receive(:get_header).with("HTTP_X_GITHUB_EVENT").and_return(nil)

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("No event")
      end

      it "should create an error if event is not accepted" do
        webhook = Issue::Webhook.new({secret_token: "123ABC", accept_events: "comments"})

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("Event discarded")
      end

      it "should create an error if origin repository is invalid" do
        webhook = Issue::Webhook.new({secret_token: "123ABC", origin: "testing/tests"})

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("Event origin not allowed")

      end

      it "should create an error if sender is discarded" do
        allow(request_body).to receive(:read).and_return({sender: {login: "bot"}}.to_json)
        webhook = Issue::Webhook.new({secret_token: "123ABC", discard_sender: "bot"})

        payload, error = webhook.parse_request(request)

        expect(error.message).to eq("Event origin discarded")
      end
    end

    it "should parse the payload" do
      payload_body = { action: "created",
                       sender: { login: "user33" },
                       repository: { full_name: "myorg/myreponame" },
                       issue: { number: "42", title: "New package", body: "Body!" }}

      allow(request_body).to receive(:read).and_return(payload_body.to_json)
      webhook = Issue::Webhook.new({secret_token: "123ABC"})
      allow(webhook).to receive(:verify_signature).and_return(true)

      payload, error = webhook.parse_request(request)

      expect(error).to be_nil
      expect(webhook).to_not be_errored
      expect(payload.action).to eq("created")
      expect(payload.event).to eq("issues")
      expect(payload.sender).to eq("user33")
      expect(payload.repo).to eq("myorg/myreponame")
      expect(payload.issue_id).to eq("42")
      expect(payload.issue_title).to eq("New package")
      expect(payload.issue_body).to eq("Body!")
      expect(payload.issue_labels).to be_nil
    end

    it "should get payload if origin is correct" do
      payload_body = { repository: { full_name: "myorg/myreponame" } }
      allow(request_body).to receive(:read).and_return(payload_body.to_json)
      webhook = Issue::Webhook.new({secret_token: "123ABC", origin: "myorg/myreponame"})
      allow(webhook).to receive(:verify_signature).and_return(true)

      payload, error = webhook.parse_request(request)
      expect(error).to be_nil
      expect(payload.repo).to eq("myorg/myreponame")
    end

    it "should get payload if sender is not discarded" do
      payload_body = { sender: { login: "user32" } }
      allow(request_body).to receive(:read).and_return(payload_body.to_json)
      webhook = Issue::Webhook.new({secret_token: "123ABC", discard_sender: "user33"})
      allow(webhook).to receive(:verify_signature).and_return(true)

      payload, error = webhook.parse_request(request)
      expect(error).to be_nil
      expect(payload.sender).to eq("user32")
    end

    it "should get payload if event is in the list of accepted events" do
      payload_body = { repository: { full_name: "myorg/myreponame" } }
      allow(request_body).to receive(:read).and_return(payload_body.to_json)
      webhook = Issue::Webhook.new({secret_token: "123ABC", accept_events: ["issues", "comments"]})
      allow(webhook).to receive(:verify_signature).and_return(true)

      payload, error = webhook.parse_request(request)
      expect(error).to be_nil
      expect(payload.event).to eq("issues")
    end
  end
end