describe Issue::Error do
  it "has a status and a message" do
    error = Issue::Error.new(403, "Forbidden action. Request not accepted.")
    expect(error.status).to eq(403)
    expect(error.message).to eq("Forbidden action. Request not accepted.")
  end
end
