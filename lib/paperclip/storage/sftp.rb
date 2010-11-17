module Paperclip
  module Storage
 
    module Sftp      
      
       def self.extended(base)         
         require 'net/ssh'
         require 'net/sftp'              
             
         base.instance_eval do
           @host = @options[:sftp_host]
           @user = @options[:sftp_user]
           @password = @options[:sftp_password]
         end
       end
       
       def ssh                           
         @ssh_connection ||= Net::SSH.start(@host, @user, :password => @password)
       end
       
       def to_file(style=default_style)
         @queued_for_write[style] || (ssh.sftp.file.open(path(style), 'rb')
       end
       alias_method :to_io, :to_file
             
       def flush_writes #:nodoc:
         
         @queued_for_write.each do |style, file|
                      
           file.close
           ssh.exec! "mkdir -p #{File.dirname(file_and_path)}"
           ssh.sftp.upload!(file.path, file_and_path)
           ssh.sftp.setstat!(file_and_path, :permissions => 0644)
         end
         @queued_for_write = {}
       end
 
       def flush_deletes #:nodoc:
         @queued_for_delete.each do |path|
           begin
             ssh.sftp.remove(path)
             FileUtils.rm(path) if File.exist?(path)
           rescue Net::SFTP::StatusException
             # ignore file-not-found, let everything else pass
           end
           begin
             while(true)
               path = File.dirname(path)
               sftp.rmdir(path)
             end
           rescue Net::SFTP::StatusException
             # Stop trying to remove parent directories
           end
         end
         @queued_for_delete = []
       end
     end
 
 
  end
end

