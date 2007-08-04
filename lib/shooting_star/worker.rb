module ShootingStar
  class Worker
    @@threads = []
    @@jobs = []
    @@mutex = Mutex.new
    @@running = Mutex.new

    def self.spawn(population)
      @@running.lock
      population.times do
        @@threads << Thread.new{Worker.new.run}
      end
    end

    def self.work(job)
      @@mutex.synchronize{@@jobs << job}
      @@threads.each{|thread| thread.run}
    end

    def self.join
      @@running.unlock
      @@threads.each{|thread| thread.run and thread.join}
    end

    def initialize
    end

    def run
      while @@running.locked?
        @@mutex.lock
        job = @@jobs.pop
        @@mutex.unlock
        job ? work(job) : Thread.stop
      end
    end

    def work(job)
      job[:block].call(*job[:params])
    rescue Exception => e
      job[:rescuer].call(e) if job[:rescuer]
    rescue Exception
    end
  end
end
