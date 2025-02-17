require 'test_helper'
require 'roar/json/json_api'
require 'json'

class JSONAPITest < MiniTest::Spec
  let(:song) {
    s = OpenStruct.new(
      bla: "halo",
      id: "1",
      title: 'Computadores Fazem Arte',
      album: OpenStruct.new(id: 9, title: "Hackers"),
      :album_id => "9",
      :musician_ids => ["1","2"],
      :composer_id => "10",
      :listener_ids => ["8"],
      musicians: [OpenStruct.new(id: 1, name: "Eddie Van Halen"), OpenStruct.new(id: 2, name: "Greg Howe")]
    )

  }

  # minimal resource, singular
  module MinimalSingular
    include Roar::JSON::JSONAPI
    type :songs

    property :id
  end

  class MinimalSingularDecorator < Roar::Decorator
    include Roar::JSON::JSONAPI
    type :songs

    property :id
  end

  [MinimalSingular, MinimalSingularDecorator].each do |representer|
    describe "minimal singular with #{representer}" do
      subject { representer.prepare(song) }

      it { subject.to_json.must_equal "{\"songs\":{\"id\":\"1\"}}" }
      it { subject.from_json("{\"songs\":{\"id\":\"2\"}}").id.must_equal "2"  }
    end
  end



  module Singular
    include Roar::JSON::JSONAPI
    type :songs

    property :id
    property :title

    # local per-model "id" links
    links do
      property :album_id, :as => :album
      collection :musician_ids, :as => :musicians
    end
    has_one :composer
    has_many :listeners


    # global document links.
    link "songs.album" do
      {
        type: "album",
        href: "http://example.com/albums/{songs.album}"
      }
    end

    compound do
      property :album do
        property :title
      end

      collection :musicians do
        property :name
      end
    end
  end

  class SingularDecorator < Roar::Decorator
    include Roar::JSON::JSONAPI
    type :songs

    property :id
    property :title

    # local per-model "id" links
    links do
      property :album_id, :as => :album
      collection :musician_ids, :as => :musicians
    end
    has_one :composer
    has_many :listeners


    # global document links.
    link "songs.album" do
      {
        type: "album",
        href: "http://example.com/albums/{songs.album}"
      }
    end

    compound do
      property :album do
        property :title
      end

      collection :musicians do
        property :name
      end
    end
  end

  [Singular, SingularDecorator].each do |representer|
    describe "singular with #{representer}" do
      subject { song.extend(Singular) }

      let (:document) do
        {
          "songs" => {
            "id" => "1",
            "title" => "Computadores Fazem Arte",
            "links" => {
              "album" => "9",
              "musicians" => [ "1", "2" ],
              "composer"=>"10",
              "listeners"=>["8"]
            }
          },
          "links" => {
            "songs.album"=> {
              "href"=>"http://example.com/albums/{songs.album}", "type"=>"album"
            }
          },
          "linked" => {
            "album"=> [{"title"=>"Hackers"}],
            "musicians"=> [
              {"name"=>"Eddie Van Halen"},
              {"name"=>"Greg Howe"}
            ]
          }
        }
      end

      # to_hash
      it do
        subject.to_hash.must_equal document
      end

      # #to_json
      it do
        subject.to_json.must_equal JSON.generate(document)
      end

      # #from_json
      it do
        song = OpenStruct.new.extend(Singular)
        song.from_json(
          JSON.generate(
            {
              "songs" => {
                "id" => "1",
                "title" => "Computadores Fazem Arte",
                "links" => {
                  "album" => "9",
                  "musicians" => [ "1", "2" ],
                  "composer"=>"10",
                  "listeners"=>["8"]
                }
              },
              "links" => {
                "songs.album"=> {
                  "href"=>"http://example.com/albums/{songs.album}", "type"=>"album"
                }
              }
            }
          )
        )

        song.id.must_equal "1"
        song.title.must_equal "Computadores Fazem Arte"
        song.album_id.must_equal "9"
        song.musician_ids.must_equal ["1", "2"]
        song.composer_id.must_equal "10"
        song.listener_ids.must_equal ["8"]
      end
    end
  end


  # collection with links
  [Singular, SingularDecorator].each do |representer|
    describe "collection with links and compound" do
      subject { Singular.for_collection.prepare([song, song]) }

      let (:document) do
        {
          "songs" => [
            {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ],
                "composer"=>"10",
              "listeners"=>["8"]
              }
            }, {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ],
                "composer"=>"10",
              "listeners"=>["8"]
              }
            }
          ],
          "links" => {
            "songs.album" => {
              "href" => "http://example.com/albums/{songs.album}",
              "type" => "album" # DISCUSS: does that have to be albums ?
            },
          },
          "linked"=>{
            "album"    =>[{"title"=>"Hackers"}], # only once!
            "musicians"=>[{"name"=>"Eddie Van Halen"}, {"name"=>"Greg Howe"}]
          }
        }
      end

      # to_hash
      it do
        subject.to_hash.must_equal document
      end

      # #to_json
      it { subject.to_json.must_equal JSON.generate(document) }
    end


    # from_json
    it do
      song1, song2 = Singular.for_collection.prepare([OpenStruct.new, OpenStruct.new]).from_json(
        JSON.generate(
          {
            "songs" => [
              {
                "id" => "1",
                "title" => "Computadores Fazem Arte",
                "links" => {
                  "album" => "9",
                  "musicians" => [ "1", "2" ],
                  "composer"=>"10",
                  "listeners"=>["8"]
                },
              },
              {
                "id" => "2",
                "title" => "Talking To Remind Me",
                "links" => {
                  "album" => "1",
                  "musicians" => [ "3", "4" ],
                  "composer"=>"2",
                  "listeners"=>["6"]
                }
              },
            ],
            "links" => {
              "songs.album"=> {
                "href"=>"http://example.com/albums/{songs.album}", "type"=>"album"
              }
            }
          }
        )
      )

      song1.id.must_equal "1"
      song1.title.must_equal "Computadores Fazem Arte"
      song1.album_id.must_equal "9"
      song1.musician_ids.must_equal ["1", "2"]
      song1.composer_id.must_equal "10"
      song1.listener_ids.must_equal ["8"]

      song2.id.must_equal "2"
      song2.title.must_equal "Talking To Remind Me"
      song2.album_id.must_equal "1"
      song2.musician_ids.must_equal ["3", "4"]
      song2.composer_id.must_equal "2"
      song2.listener_ids.must_equal ["6"]
    end
  end


  class CollectionWithoutCompound <  self
    module Representer
      include Roar::JSON::JSONAPI
      type :songs

      property :id
      property :title

      # local per-model "id" links
      links do
        property :album_id, :as => :album
        collection :musician_ids, :as => :musicians
      end
      has_one :composer
      has_many :listeners


      # global document links.
      link "songs.album" do
        {
          type: "album",
          href: "http://example.com/albums/{songs.album}"
        }
      end
    end

    subject { [song, song].extend(Singular.for_collection) }

    # to_json
    it do
      subject.extend(Representer.for_collection).to_hash.must_equal(
        {
          "songs"=>[{"id"=>"1", "title"=>"Computadores Fazem Arte", "links"=>{"album"=>"9", "musicians"=>["1", "2"], "composer"=>"10", "listeners"=>["8"]}}, {"id"=>"1", "title"=>"Computadores Fazem Arte", "links"=>{"album"=>"9", "musicians"=>["1", "2"], "composer"=>"10", "listeners"=>["8"]}}],
          "links"=>{"songs.album"=>{"href"=>"http://example.com/albums/{songs.album}", "type"=>"album"}
          }
        }
      )
    end
  end
end