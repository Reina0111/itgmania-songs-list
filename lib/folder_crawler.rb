require 'find'

def get_songs(path:)
  paths_ssc = []
  paths_sm = []
  puts "searching ssc and sm files"
  Find.find(path) do |p|
    paths_ssc << p if p =~ /.*\.ssc$/
    paths_sm << p if p =~ /.*\.sm$/
  end
  puts "finishing searching ssc and sm files"

  songs = []

  puts "getting info about scc files"
  paths_ssc.each do |p|
    path_divided = p.split('/')
    song = {
      pack: path_divided[-3],
      title: path_divided[-2],
      metters: [],
      type: "scc",
    }

    file = File.open(p)
    begin
      song[:artist] = file.select { |line| line =~ /.*ARTIST:.*/ }.map { |line| line.split(":", 2)[1].split(";\r\n", 2)[0] }
    rescue ArgumentError
      song[:artist] = "???"
    end
    file.close

    file = File.open(p)
    song[:metters] = file.select { |line| line =~ /.*METER:.*/ }.map { |line| line.scan(/\d*/).reject(&:empty?)[0].to_i }.sort
    file.close

    songs << song
  end

  puts "getting info about sm files"
  paths_sm.each do |p|
    path_divided = p.split('/')
    song = {
      pack: path_divided[-3],
      title: path_divided[-2],
      metters: [],
      type: "sm",
    }

    file = File.open(p)
    begin
      song[:artist] = file.select { |line| line =~ /.*ARTIST:.*/ }.map { |line| line.split(":", 2)[1].split(";\r\n", 2)[0] }
    rescue ArgumentError
      song[:artist] = "???"
    end
    file.close

    file = File.open(p)
    begin
      song[:metters] = file.select { |line| line =~ /     [0-9]*:.*/ }.map { |line| line.scan(/\d*/).reject(&:empty?)[0].to_i }.sort
    rescue ArgumentError
      song[:metters] = [-1]
    end
    file.close

    songs << song
  end

  songs
end