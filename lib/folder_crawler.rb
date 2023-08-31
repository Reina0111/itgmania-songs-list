require 'find'

# extension priorities: ssc, sm, dvi
# TODO fix reading files
# files enters and spaces do not matter!!!
# final version must first remove all of them, and then look only at : and ; to find metters/artists etc.

# TODO add checking for single and double charts

def get_songs(path:)
  paths_ssc, paths_sm = read_songs_paths(path:)

  songs = []

  songs += get_ssc_songs(paths: paths_ssc)

  songs += get_sm_songs(paths: paths_sm)

  songs
end

def read_songs_paths(path:)
  paths_ssc = []
  paths_sm = []
  puts "searching ssc and sm files"
  Find.find(path) do |p|
    paths_ssc << p if p =~ /.*\.ssc$/
    paths_sm << p if p =~ /.*\.sm$/
  end
  puts "finishing searching ssc and sm files"

  [paths_ssc, paths_sm]
end

def get_ssc_songs(paths: [])
  songs = []
  puts "getting info about ssc files"
  paths.each do |p|
    path_divided = p.split('/')
    song = {
      pack: path_divided[-3],
      title: path_divided[-2],
      metters: [],
      type: "ssc",
    }

    file = File.open(p)
    begin
      song[:artist] = file.select { |line| line =~ /.*ARTIST:.*/ }.map { |line| line.split(":", 2)[1].split(";\r\n", 2)[0] }
    rescue ArgumentError
      song[:artist] = "???"
    end
    file.close
    song[:artist] = song[:artist][0] if song[:artist].is_a?(Array)

    file = File.open(p)
    begin
      song[:metters] = file.select { |line| line =~ /.*METER:.*/ }.map { |line| line.scan(/\d*/).reject(&:empty?)[0].to_i }.sort
    rescue ArgumentError
      song[:metters] = [-1]
    end
    file.close

    songs << song
  end

  songs
end

def get_sm_songs(paths: [])
  songs = []
  puts "getting info about sm files"
  paths.each do |p|
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
    song[:artist] = song[:artist][0] if song[:artist].is_a?(Array)

    file = File.open(p)
    begin
      i = -1
      metters = file.select do |line|
        i += 1 if i != -1
        i = 0 if line =~ /#NOTES:.*/
        if i == 4
          i = -1
          true
        else
          false
        end
      end
      song[:metters] = metters.map { |line| line.scan(/\d*/).reject(&:empty?)[0].to_i }.sort
    rescue ArgumentError
      song[:metters] = [-1]
    end
    file.close

    songs << song
  end

  songs
end

def select_single_version_of_song(songs: [])
  grouped_songs = songs.group_by { |s| [s[:pack], s[:title]] }

  selected_songs = grouped_songs.map do |k, v|
    if v.count == 1
      v[0]
    else
      ssc, sm = v[0], v[1]
      ssc, sm = sm, ssc if ssc[:type] == "sm"

      # przypadek jakby źle przeparsowwały się poziomy trudności w pliku ssc - wtedy musimy wziąć sm
      ssc[:meter] != [-1] ? ssc : sm
    end
  end

  selected_songs
end

def save_song_list_to_tsv(file_name: "song_list", songs: [])
  result = "pack\ttitle\tartist\tmeter\r\n"
  songs.each do |song|
    song[:metters].each do |meter|
      result << "#{song[:pack]}\t#{song[:title]}\t#{song[:artist]}\t#{meter}\r\n"
    end
  end

  File.write(file_name, result)

  true
end

def parse_songs_full(path:,file_name: "song_list")
  songs = get_songs(path: path)
  songs = select_single_version_of_song(songs: songs)
  save_song_list_to_tsv(file_name: file_name, songs: songs)
end