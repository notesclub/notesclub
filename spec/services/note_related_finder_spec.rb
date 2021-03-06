# frozen_string_literal: true

require "rails_helper"



RELEVANT_FIELDS = [
  :id, :content, :slug, :user_id, :user,
  :ancestry, :ancestors, :descendants
]
def relevant_data(notes)
  relevant_note_fields notes, RELEVANT_FIELDS
end

RSpec.describe NoteRelatedFinder do
  fixtures(:users)
  let(:user1) { users(:user1) }
  let(:user2) { users(:user2) }
  let(:user3) { users(:user3) }

  let(:note) { make_note(
    content: "Note to be linked",
    ancestry: nil,
    slug: "note",
    user_id: user1.id
  )}

  before(:each) do
    unrelated_note1 = {
      content: "Unrelated note nº1",
      ancestry: nil,
      position: 1,
      slug: "unrelated_note_1",
      user_id: user1.id
    }
    NoteCreator.call unrelated_note1
    unrelated_note2 = {
      content: "Unrelated note nº 2, linking to [[Unrelated note nº1]], really linked to ##Unrelated note nº1",
      ancestry: nil,
      position: 1,
      slug: "unrelated_note_2",
      user_id: user1.id
    }
    NoteCreator.call unrelated_note2
  end

  it "returns error if called with a non-existing note" do
    non_existent_id = 999
    NoteDeleter.call(non_existent_id)

    result = NoteRelatedFinder.call(non_existent_id)

    expect(result.error?).to be true
    expect(result.errors).to match(/Couldn't find Note 999/)
  end

  describe "returns notes with a link to the note" do
    it "with [[...]] format" do
      # rubocop:disable Lint/UselessAssignment
      related_note_1 = make_note(
        slug: "related_note_1",
        content: "Note from the same user linking to the [[#{note["content"]}]]",
        ancestry: nil,
        user_id: user1.id
      )
      related_note_2 = make_note(
        slug: "related_note_2",
        content: "Another note linking to the [[#{note["content"]}]] from another user",
        ancestry: nil,
        user_id: user2.id
      )
      non_root_related_note = make_note(
        slug: "non_root_related_note",
        content: "One non-root note linking to [[#{note["content"]}]]",
        ancestry: related_note_1["id"].to_s,
        user_id: user1.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true
      expect(notes_slugs(result.value)).to match_array([
        "related_note_1",
        "related_note_2",
        "non_root_related_note"
      ])
    end

    it "with ##... format" do
      # rubocop:disable Lint/UselessAssignment
      related_note_1 = make_note(
        slug: "related_note_1",
        content: "Note from the same user linking to the ##" + note["content"],
        ancestry: nil,
        user_id: user1.id
      )
      related_note_2 = make_note(
        slug: "related_note_2",
        content: "Another note linking to the ##" + note["content"] + " from another user",
        ancestry: nil,
        user_id: user2.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true
      expect(notes_slugs(result.value)).to match_array([
        "related_note_1",
        "related_note_2"
      ])
    end

    it "returns empty array if there aren't related notes" do
      standalone_note = make_note(
        content: "This note doesn't have related notes",
        ancestry: nil,
        slug: "related_1",
        user_id: user1.id
      )

      result = NoteRelatedFinder.call(standalone_note["id"])

      expect(result.success?).to be true
      expect(result.value).to eq []
    end

    it "is case insensitive" do
      random_case_content = note["content"].chars.map { |c| rand(2).zero? ? c.upcase : c.downcase }.join

      # rubocop:disable Lint/UselessAssignment
      related_note_1 = make_note(
        slug: "related_note_1",
        content: "Note from the same user linking to the [[#{random_case_content}]]",
        ancestry: nil,
        user_id: user1.id
      )
      related_note_2 = make_note(
        slug: "related_note_2",
        content: "Note from the same user linking to the ##" + random_case_content,
        ancestry: nil,
        user_id: user1.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])
      expect(notes_slugs(result.value)).to match_array([
        "related_note_1",
        "related_note_2"
      ])
    end
  end

  describe "returns root notes with the same content" do
    it "include only root notes" do
      # rubocop:disable Lint/UselessAssignment
      root_note_1 = make_note(
        slug: "root_note_1",
        content: note["content"],
        ancestry: nil,
        user_id: user1.id
      )
      root_note_2 = make_note(
        slug: "root_note_2",
        content: note["content"],
        ancestry: nil,
        user_id: user1.id
      )
      non_root_note = make_note(
        slug: "non_root_note",
        content: note["content"],
        ancestry: root_note_2["id"],
        user_id: user1.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true
      expect(notes_slugs(result.value)).to match_array([
        "root_note_1",
        "root_note_2"
      ])
    end

    it "excludes the note passed as parameter" do
      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true
      expect(result.value).to eq []
    end

    it "is case insensitive" do
      random_case_content = note["content"].chars.map { |c| rand(2).zero? ? c.upcase : c.downcase }.join

      # rubocop:disable Lint/UselessAssignment
      root_note_1 = make_note(
        slug: "root_note_1",
        content: random_case_content,
        ancestry: nil,
        user_id: user1.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true
      expect(notes_slugs(result.value)).to match_array([
        "root_note_1"
      ])
    end
  end

  describe "orders the results" do
    it "returning the notes of the note's user before the other notes" do
      note_user_id = note["user_id"]
      another_user_id = user3.id

      # rubocop:disable Lint/UselessAssignment
      another_user_note = make_note(
        content: "Note linking to the [[#{note["content"]}]]",
        ancestry: nil,
        slug: "related_1",
        user_id: another_user_id
      )
      user_note_1 = make_note(
        content: note["content"],
        ancestry: nil,
        slug: "user_note_1",
        user_id: note_user_id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"])

      expect(result.success?).to be true

      notes = result.value
      expect(notes.count).to eq 2
      expect(notes[0]["user_id"]).to eq note_user_id
      expect(notes[1]["user_id"]).to eq another_user_id
    end

    it "returning first the authenticated user's notes, then note's user's notes" do
      auth_user = user2
      note_user = user1
      another_user = user3

      # rubocop:disable Lint/UselessAssignment
      auth_user_note_1 = make_note(
        content: note["content"],
        ancestry: nil,
        slug: "auth_user_note_1",
        user_id: auth_user.id
      )
      auth_user_note_2 = make_note(
        content: "Note linking to the [[#{note["content"]}]]",
        ancestry: nil,
        slug: "auth_user_note_2",
        user_id: auth_user.id
      )
      user_note_1 = make_note(
        content: note["content"],
        ancestry: nil,
        slug: "user_note_1",
        user_id: note_user.id
      )
      user_note_2 = make_note(
        content: "Note linking to the [[#{note["content"]}]]",
        ancestry: nil,
        slug: "user_note_2",
        user_id: note_user.id
      )
      another_user_note = make_note(
        content: "Note linking to the [[#{note["content"]}]]",
        ancestry: nil,
        slug: "another_user_note",
        user_id: another_user.id
      )
      # rubocop:enable Lint/UselessAssignment

      result = NoteRelatedFinder.call(note["id"], authenticated_user_id: auth_user.id)

      expect(result.success?).to be true

      notes = result.value
      expect(notes.count).to eq 5
      expect(notes[0]["user_id"]).to eq auth_user.id
      expect(notes[1]["user_id"]).to eq auth_user.id
      expect(notes[2]["user_id"]).to eq note_user.id
      expect(notes[3]["user_id"]).to eq note_user.id
      expect(notes[4]["user_id"]).to eq another_user.id
    end
  end

  it "includes descendants, ancestors and user data" do
    note_user = user2
    ancestor_note = make_note(
      slug: "ancestor_note",
      content: "This is an ancestor of the note",
      ancestry: nil,
      user_id: note_user.id
    )
    note_to_return = make_note(
      slug: "note_to_return",
      content: "Note linking to the [[#{note["content"]}]]",
      ancestry: ancestor_note["id"].to_s,
      user_id: note_user.id
    )
    # rubocop:disable Lint/UselessAssignment
    descendant_note = make_note(
      slug: "descendant_note",
      content: "This is a descendant of the note",
      ancestry: "#{note_to_return['ancestry']}/#{note_to_return['id']}",
      user_id: note_user.id
    )
    # rubocop:enable Lint/UselessAssignment

    result = NoteRelatedFinder.call(note["id"],
                include_descendants: true, include_ancestors: true, include_user: true)

    expected_result = [
      note_to_return.merge(
        {
          "ancestors" => [ancestor_note],
          "descendants" => [descendant_note],
          "user" => {
            "id" => note_user.id,
            "name" => note_user.name,
            "username" => note_user.username,
            "avatar_url" => note_user.avatar_url
          }
        }
      )
    ]
    expect(result.success?).to be true
    expect(relevant_data(result.value)).to eq expected_result
  end
end
