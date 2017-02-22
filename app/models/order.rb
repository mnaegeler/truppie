require 'json'
require 'rest_client'

class Order < ActiveRecord::Base
  belongs_to :tour
  belongs_to :user
  
  def to_param
    "#{id} #{self.payment}".parameterize
  end
  
  def current_status
    payment_id = self.payment
    begin
      order = Stripe::Charge.retrieve(self.payment)
      self.update_attributes({:status => order.status})
      return order.outcome
    rescue => e
      return {
        :type => 'not_available'
      }
    end
  end
  
  def fees
    {
      :fee => self.try(:fee),
      :liquid => self.try(:liquid),
      :total => self.try(:final_price)
    }
  end
  
  def total_fee
    self.fees[:fee]  
  end
  
  def amount_total
    self.fees[:liquid]
  end
  
  def price_with_fee
    self.fees[:liquid]
  end
  
  def full_desc_status(status)
    case status
    when 'CREATED'
      'O seu pagamento foi processado'
    when 'WAITING'
      'Recebemos o seu pagamento e estamos aguardando o contato da operadora do cartão com uma resposta'
    when 'IN_ANALYSIS'
      'O seu pagamento se encontra em análise pela operadora do cartão'
    when 'PRE_AUTHORIZED'
      'O seu pagaemento foi pré-autorizado'
    when 'AUTHORIZED'
      'O seu pagamento foi autorizado'
    when 'CANCELLED'
      'O seu pagamento foi cancelado pela operadora do cartão'
    when 'REVERSED'
      'O seu pagamento foi revertido'
    when 'REFUNDED'
      'Você irá ser reembolsado'
    when 'SETTLED'
      'O seu pagamento foi finalizado'
    else
      'Estamos ainda definindo o status do seu pagamento'
    end
  end
  
  def friendly_status(status)
    case status
    when 'issuer_declined'
      '<span class="label label-danger">NEGADO</span>'
    when 'blocked'
      '<span class="label label-primary">BLOQUEADO</span>'
    when 'authorized'
      '<span class="label label-primary">AUTORIZADO</span>'
    when 'invalid'
      '<span class="label label-info">INVALIDO</span>'
    when 'not_available'
      '<span class="label label-info">NAO DISPONIVEL</span>'
    else
      '<span class="label label-default">AGUARDANDO STATUS</span>'
    end
    
  end
  
end
