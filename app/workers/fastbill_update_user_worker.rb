class FastbillUpdateUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :fastbill,
                  retry: 20,
                  backtrace: true

  def perform user_id
    user = User.find(user_id)
    user.update_fastbill_profile
  end
end
