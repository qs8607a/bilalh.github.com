#!/usr/bin/env ruby19
# encoding: utf-8
require_relative 'custom_page'

module Jekyll
	class Project < CustomPage
		def initialize(site, base, dir, name, info)
			super site, base, dir, 'project'
			puts "Building project: #{name}"
			
			self.data['title']       = info['title'] || name
			self.data['version']     = info['version_title'] || info['version']
			self.data['repo']        = "https://github.com/#{site.config['github_user']}/#{name}"
			self.data['download']    = "#{self.data['repo']}/zipball/#{info['version'] || 'master'}"
			self.data['docs']        = info['docs'] == 'wiki' ? "#{self.data['repo']}/wiki" : info['docs'] if info['docs']
			self.data['description'] = info['description']
			
			filename="_cache/#{name}.readme"
			if !File.exists?(filename) then
				# this stuff is bit hackish, but it works
				# this will fail if README.md isn't present
				readme = `curl https://raw.github.com/#{site.config['github_user']}/#{name}/master/readme.md` 
				readme.gsub!(/\`{3} ?(\w+)\n(.+?)\n\`{3}/m, "{% highlight \\1 %}\n\\2\n{% endhighlight %}")
				readme = Liquid::Template.parse(readme).render({}, :filters => [Jekyll::Filters], :registers => { :site => site })
				File.open(filename, "w") { |f| f.puts readme } 
			else 
				readme = IO.read filename
			end
			
			self.data['readme']    = RDiscount.new(readme,:generate_toc).to_html
			# self.data['readme']    =  readme
			self.data['changelog'] = 'changelog.html'
		end
	end
	
	class ChangeLog < CustomPage
		def initialize(site, base, dir, name, project)
			super site, base, dir, 'changelog', 'changelog.html'
			['title', 'version','repo','download'].each do |key|
				self.data[key] = project.data[key]
			end
			
			filename="_cache/mplayer-last.fm-scrobbler.changelog"
			
			# filename="_cache/#{name}.readme"
			changelog = IO.read filename
			changelog.gsub!(/\`{3} ?(\w+)\n(.+?)\n\`{3}/m, "{% highlight \\1 %}\n\\2\n{% endhighlight %}")
			changelog = Liquid::Template.parse(changelog).render(
				{}, :filters => [Jekyll::Filters], :registers => { :site => site }
			)
			
			self.data['changelog'] = changelog
		end	
		
	end
	
	class Projects < CustomPage
		def initialize(site, base, dir, projects)
			super site, base, dir, 'projects'
			data = []
			projects.each { |v| data << v.data }
			self.data['projects'] = data
		end
	end
	
	class Site
		def generate_projects
			return unless self.config.key? 'projects'
			throw "No 'project' layout found." unless self.layouts.key? 'project'
			dir = self.config['project_dir'] || 'projects'
			projects = []
			Dir.mkdir '_cache' unless  File.directory?('_cache')
			
			self.config['projects'].each do |k, v|
				slug = v['slug'] || k.slugize
				p = Project.new(self, self.source, File.join(dir, slug), k, v)
				p.data['url'] = "/#{dir}/#{slug}"
				projects << p
				write_page p
				write_page ChangeLog.new(self, self.source, File.join(dir, slug),k, p)
			end
			
			write_page Projects.new(self, self.source, dir, projects) if self.layouts.key? 'projects'
		end
	end
	
end
 