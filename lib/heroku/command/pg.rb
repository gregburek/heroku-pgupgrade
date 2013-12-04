class Heroku::Command::Pg < Heroku::Command::Base

  # pg:upgrade REPLICA
  #
  # unfollow a database and upgrade it to the latest PostgreSQL version
  #
  def upgrade
    unless db = shift_argument
      error("Usage: heroku pg:upgrade REPLICA\nMust specify REPLICA to upgrade.")
    end
    validate_arguments!

    resolver = generate_resolver
    replica = resolver.resolve(db)
    @app = resolver.app_name if @app.nil?

    replica_info = hpg_info(replica)

    upgrade_status = hpg_client(replica).upgrade_status

    if upgrade_status[:error]
      output_with_bang "There were problems upgrading #{replica.resource_name}"
      output_with_bang upgrade_status[:error]
    else
      origin_url = replica_info[:following]
      origin_name = resolver.database_name_from_url(origin_url)

      output_with_bang "#{replica.resource_name} will be upgraded to a newer PostgreSQL version,"
      output_with_bang "stop following #{origin_name}, and become writable."
      output_with_bang "Use `heroku pg:wait` to track status"
      output_with_bang "\nThis cannot be undone."
      return unless confirm_command

      action "Requesting upgrade" do
        hpg_client(replica).upgrade
      end
    end

  end
end
