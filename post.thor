require "stringex"
class Post < Thor

  desc "new", "create a new post"
  method_option :editor, :default => "vim"
  method_option :date
  method_option :tags

  def new(*title)
    title = title.join(" ")
    date = options[:date] || Time.now.strftime('%Y-%m-%d')
    tags = options[:tags].split(",")
    filename = "_posts/#{date}-#{title.to_url}.md"

    if File.exist?(filename)
      abort("#{filename} already exists!")
    end

    puts "Creating new post: #{filename}"
    open(filename, 'w') do |post|
      post.puts "---"
      post.puts "layout: page"
      post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
      post.puts "date: #{date}"
      post.puts "summary: |"
      post.puts "tags: #{tags.join(' ')}"
      post.puts "---"
    end

    system(options[:editor], filename)
  end

end
