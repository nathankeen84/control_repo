# frozen_string_literal: true

require 'puppet/property'

class Puppet::Property::SqlserverTsql < Puppet::Property # rubocop:disable Style/Documentation
  desc 'TSQL property that we are going to wrap with a try catch'
  munge do |value|
    quoted_value = value.gsub('\'', '\'\'')
    erb_template = <<~TEMPLATE
      BEGIN TRY
          SET NOCOUNT ON
          DECLARE @sql_text as NVARCHAR(max);
          SET @sql_text = N'#{quoted_value}'
          EXECUTE sp_executesql @sql_text;
      END TRY
      BEGIN CATCH
          DECLARE @msg as VARCHAR(max);
          SELECT @msg = 'THROW CAUGHT: ' + ERROR_MESSAGE();
          THROW 51000, @msg, 10
      END CATCH
    TEMPLATE
    erb_template
  end
end
