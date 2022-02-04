# frozen_string_literal: true

module Service
  class CheckLastSolutions
    def initialize; end

    def perform
      new_searched_solutions = get_new_solutions_from(Setting.last_transaction['hash'])
      return if new_searched_solutions.blank?

      solution = new_searched_solutions.last
      Setting.last_transaction = solution
      new_searched_solutions
    end

    private

    def get_new_solutions_from(hash_of_last_transaction)
      transaction = Transaction.find_by(t_hash: hash_of_last_transaction)
      return [Transaction.first] if transaction.blank?

      Transaction.where('time > ?', transaction.time).reverse
    end
  end
end
