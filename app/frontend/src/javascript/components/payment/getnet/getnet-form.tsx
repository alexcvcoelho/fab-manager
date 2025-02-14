import { FunctionComponent, useState, useEffect } from 'react';
import * as React from 'react';
import { GatewayFormProps } from '../abstract-payment-modal';
import { useForm } from 'react-hook-form';
import { FormInput } from '../../form/form-input';
import Inputmask from 'inputmask';
import ValidationLib from '../../../lib/validation';
import GetnetAPI from '../../../api/getnet';
import { Card, CreatePaymentResponse } from '../../../models/getnet';
import CheckoutAPI from '../../../api/checkout';
import { Invoice } from '../../../models/invoice';
import { Order } from '../../../models/order';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { ShoppingCart } from '../../../models/payment';
import { User } from '../../../models/user';

// we use these two additional parameters to update the card, if provided
interface GetnetFormProps extends GatewayFormProps {
  updateCard?: boolean,
}

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const GetnetForm: React.FC<GetnetFormProps> = ({ onSubmit, onSuccess, onError, children, updateCard = false, className, paymentSchedule, cart, customer, formId, order }) => {
  const [loadingClass, setLoadingClass] = useState<'hidden' | 'loader' | 'loader-overlay'>('hidden');
  const { register, formState, handleSubmit } = useForm<Card>();

  useEffect(() => {
    Inputmask({ mask: '99/99', clearMaskOnLostFocus: true }).mask('[id="expiration"]');
    Inputmask({ mask: '9999 9999 9999 99[9][9]', clearMaskOnLostFocus: true }).mask('[id="number"]');
    Inputmask({ mask: '999[9]', clearMaskOnLostFocus: true }).mask('[id="cvv"]');
  }, []);

  /**
   * Handle the submission of the form.
   */
  const submitForm = async (card: Card): Promise<void> => {
    onSubmit();
    try {
      const token = await crateCardToken(card);
      createPayment(cardData(card, token), cart, customer).then((payment) => {
        if (payment.result.status === 'APPROVED') {
          confirmPayment(payment).then((confirmation) => {
            onSuccess(confirmation);
          }).catch(e => onError(e));
        } else {
          throw Error('Erro ao realizar pagamento.');
        }
      }).catch(e => onError(e));
    } catch (err) {
      // catch api errors
      onError(err);
    } finally {
      setLoadingClass('hidden');
    }
  };

  /**
   * Make a request for tokenize card number
   * @param card
   * @returns
   */
  const crateCardToken = async (card: Card): Promise<string> => {
    const res = await GetnetAPI.tokenCard(card.number, customer);
    if (!res.token) {
      throw new Error(' Número de cartão inválido');
    }
    return res.token;
  };

  /**
   * Create a card object for payment
   * @param card
   * @param token
   * @returns
   */
  const cardData = (card: Card, token: string): Card => {
    return {
      token,
      name: card.name,
      expiration: card.expiration,
      cvv: card.cvv
    } as Card;
  };

  /**
   * Ask the API to create the form token.
   * Depending on the current transaction (schedule or not), a PayZen Token or Payment may be created.
   */
  const createPayment = async (card: Card, cart: ShoppingCart, customer: User): Promise<CreatePaymentResponse> => {
    if (updateCard) {
      throw new Error('Atualização de cartão não implementada');
    } else if (paymentSchedule) {
      throw new Error('Pagamento recorrente não implementado');
    } else if (order) {
      const res = await CheckoutAPI.payment(order);
      return res.payment as CreatePaymentResponse;
    } else {
      return await GetnetAPI.createPayment(card, cart, customer);
    }
  };

  /**
   * Confirm the payment, depending on the current type of payment (single shot or recurring)
   */
  const confirmPayment = async (payment: CreatePaymentResponse): Promise<Invoice | PaymentSchedule | Order> => {
    if (paymentSchedule) {
      throw new Error('Pagamento recorrente não implementado');
    } else if (order) {
      const res = await CheckoutAPI.confirmPayment(order, payment.orderId);
      return res.order;
    } else {
      return await GetnetAPI.confirm(payment.orderId, cart);
    }
  };

  /**
   * Return a loader
   */
  const Loader: FunctionComponent = () => {
    return (
      <div className={`fa-3x ${loadingClass}`}>
        <i className="fas fa-circle-notch fa-spin" />
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit(submitForm)} id={formId} className={`getnet-form ${className || ''}`}>
      <Loader />
      <div className="getnet-container">
        <div className="getnet-card-input">
          <label htmlFor="number">Número do cartão</label>
          <FormInput id="number"
            icon={<i className="fa fa-credit-card" />}
            type="tel"
            register={register}
            rules={{
              pattern: {
                value: ValidationLib.cardNumberRegex,
                message: 'Cartão inválido'
              },
              required: true
            }}
            formState={formState}
          />
        </div>
        <div className="getnet-card-name-input">
          <label htmlFor="name">Nome do cartão</label>
          <FormInput id="name"
            icon={<i className="fa fa-user" />}
            type="text"
            register={register}
            rules={{ required: true }}
            formState={formState}
          />
        </div>
        <div className='getnet-line-cvv-expiration'>
          <div className="getnet-card-expiration-input">
            <label htmlFor="expiration">Data de validade</label>
            <FormInput id="expiration"
              icon={<i className="fa fa-calendar" />}
              type="tel"
              placeholder='DD/MM'
              register={register}
              rules={{
                pattern: {
                  value: ValidationLib.expirationCardRegex,
                  message: 'Data inválida'
                },
                required: true
              }}
              formState={formState}
            />
          </div>
          <div className="getnet-card-cvv-input">
            <label htmlFor="cvv">CVV</label>
            <FormInput id="cvv"
              icon={<i className="fa fa-key" />}
              type="tel"
              register={register}
              rules={{
                pattern: {
                  value: ValidationLib.cvvRegex,
                  message: 'CVV inválido'
                },
                required: true
              }}
              formState={formState}
            />
          </div>
        </div>
      </div>
      {children}
    </form>
  );
};
