# frozen_string_literal: true

module Datasources
  class SchemaClassifier
    SIGNAL_KEYWORDS = {
      email:       %w[email email_address],
      phone:       %w[phone phone_number mobile],
      address:     %w[address street city state postal zipcode zip],
      name:        %w[first_name last_name full_name name],
      dob:         %w[birth dob birthdate birthday],
      ssn:         %w[ssn social security],
      credit_card: %w[credit card pan cvv expiry],
      ip:          %w[ip ip_address ipv4 ipv6],
      country:     %w[country nation locale],
      amount:      %w[amount total spend price balance revenue income cost]
    }.freeze

    CATEGORY_MAP = {
      email:       :pii,
      phone:       :pii,
      address:     :pii,
      name:        :pii,
      dob:         :pii,
      ssn:         :pii,
      credit_card: :pii,
      ip:          :pii,

      amount:      :financial,
      country:     :internal,

      generic:     :internal
    }.freeze

    SENSITIVITY_MAP = {
      pii:        :medium,
      financial:  :medium,
      internal:   :low
    }.freeze

    # raw_schema:
    # { "customers" => [{name:, type:}, ...], ... }
    def classify(raw_schema)
      raw_schema.map do |table_name, columns|
        {
          table: table_name,
          columns: Array(columns).map { |col| classify_column(col) }
        }
      end
    end

    private

    def classify_column(column)
      name = column.fetch(:name).to_s.downcase

      signal = SIGNAL_KEYWORDS.find do |_signal, keywords|
        keywords.any? { |kw| name.include?(kw) }
      end&.first || :generic

      category    = CATEGORY_MAP.fetch(signal, :internal)
      sensitivity = SENSITIVITY_MAP.fetch(category, :low)

      {
        name: column[:name],
        type: column[:type],
        classification: signal,
        category: category,
        sensitivity: sensitivity
      }
    end
  end
end
